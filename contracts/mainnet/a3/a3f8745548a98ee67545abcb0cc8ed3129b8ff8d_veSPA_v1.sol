// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@&....(@@@@@@@@@@@@@..../@@@@@@@@@//
//@@@@@@........../@@@@@@@........../@@@@@@//
//@@@@@............(@@@@@............(@@@@@//
//@@@@@([email protected]@@@@(...........&@@@@@//
//@@@@@@@...........&@@@@@@[email protected]@@@@@@//
//@@@@@@@@@@@@@@%..../@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@......(&@@@@@@@@@@@@//
//@@@@@@#[email protected]@@@@@#[email protected]@@@@@@//
//@@@@@/...........%@@@@@............%@@@@@//
//@@@@@............#@@@@@............%@@@@@//
//@@@@@@..........#@@@@@@@/.........#@@@@@@//
//@@@@@@@@@&/.(@@@@@@@@@@@@@@&/.(&@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//

import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IveSPA.sol";

// @title Voting Escrow
// @notice Cooldown logic is added in the contract
// @notice Make contract upgradeable
// @notice This is a Solidity implementation of the CURVE's voting escrow.
// @notice Votes have a weight depending on time, so that users are
//         committed to the future of (whatever they are voting for)
// @dev Vote weight decays linearly over time. Lock time cannot be
//  more than `MAX_TIME` (4 years).

/**
# Voting escrow to have time-weighted votes
# w ^
# 1 +        /
#   |      /
#   |    /
#   |  /
#   |/
# 0 +--------+------> time
#       maxtime (4 years?)
*/

contract veSPA_v1 is IveSPA, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum ActionType {
        DEPOSIT_FOR,
        CREATE_LOCK,
        INCREASE_AMOUNT,
        INCREASE_LOCK_TIME,
        INITIATE_COOLDOWN
    }

    event UserCheckpoint(
        ActionType indexed actionType,
        bool autoCooldown,
        address indexed provider,
        uint256 value,
        uint256 indexed locktime
    );
    event GlobalCheckpoint(address caller, uint256 epoch);
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);

    struct Point {
        int128 bias; // veSPA value at this point
        int128 slope; // slope at this point
        int128 residue; // residue calculated at this point
        uint256 ts; // timestamp of this point
        uint256 blk; // block number of this point
    }
    /* We cannot really do block numbers per se b/c slope is per time, not per block
     * and per block could be fairly bad b/c Ethereum changes blocktimes.
     * What we can do is to extrapolate ***At functions */

    struct LockedBalance {
        bool autoCooldown; // if true, the user's deposit will have a default cooldown.
        bool cooldownInitiated; // Determines if the cooldown has been initiated.
        uint128 amount; // amount of SPA locked for a user.
        uint256 end; // the expiry time of the deposit.
    }

    string public version;
    string public constant name = "Vote-escrow SPA";
    string public constant symbol = "veSPA";
    uint8 public constant decimals = 18;
    uint256 public totalSPALocked;
    uint256 public constant WEEK = 1 weeks;
    uint256 public constant MAX_TIME = 4 * 365 days;
    uint256 public constant MIN_TIME = 1 * WEEK;
    uint256 public constant MULTIPLIER = 10**18;
    int128 public constant I_YEAR = int128(uint128(365 days));
    int128 public constant I_MIN_TIME = int128(uint128(WEEK));
    address public SPA;

    // @dev Mappings to store global point information
    uint256 public epoch;
    mapping(uint256 => Point) public pointHistory; // epoch -> unsigned point
    mapping(uint256 => int128) public slopeChanges; // time -> signed slope change

    // @dev Mappings to store user deposit information
    mapping(address => LockedBalance) public lockedBalances; // user Deposits
    mapping(address => mapping(uint256 => Point)) public userPointHistory; // user -> point[userEpoch]
    mapping(address => uint256) public override userPointEpoch;

    // @dev Constructor
    function initialize(address _SPA, string memory _version)
        public
        initializer
    {
        require(_SPA != address(0), "_SPA is zero address");
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        SPA = _SPA;
        version = _version;
        pointHistory[0].blk = block.number;
        pointHistory[0].ts = block.timestamp;
    }

    // @notice Get the most recently recorded rate of voting power decrease for `addr`
    // @param addr The address to get the rate for
    // @return value of the slope
    function getLastUserSlope(address addr)
        external
        view
        override
        returns (int128)
    {
        uint256 uEpoch = userPointEpoch[addr];
        if (uEpoch == 0) {
            return 0;
        }
        return userPointHistory[addr][uEpoch].slope;
    }

    // @notice Get the timestamp for checkpoint `idx` for `addr`
    // @param addr User wallet address
    // @param idx User epoch number
    // @return Epoch time of the checkpoint
    function getUserPointHistoryTS(address addr, uint256 idx)
        external
        view
        override
        returns (uint256)
    {
        return userPointHistory[addr][idx].ts;
    }

    // @notice Get timestamp when `addr`'s lock finishes
    // @param addr User wallet address
    // @return Timestamp when lock finishes
    function lockedEnd(address addr) external view override returns (uint256) {
        return lockedBalances[addr].end;
    }

    // @notice add checkpoints to pointHistory for every week from last added checkpoint until now
    // @dev block number for each added checkpoint is estimated by their respective timestamp and the blockslope
    //         where the blockslope is estimated by the last added time/block point and the current time/block point
    // @dev pointHistory include all weekly global checkpoints and some additional in-week global checkpoints
    // @return lastPoint by calling this function
    function _updateGlobalPoint() private returns (Point memory lastPoint) {
        uint256 _epoch = epoch;
        lastPoint = Point({
            bias: 0,
            slope: 0,
            residue: 0,
            ts: block.timestamp,
            blk: block.number //TODO: arbi-main-fork cannot test it
        });
        Point memory initialLastPoint = Point({
            bias: 0,
            slope: 0,
            residue: 0,
            ts: block.timestamp,
            blk: block.number
        });
        if (_epoch > 0) {
            lastPoint = pointHistory[_epoch];
            initialLastPoint = pointHistory[_epoch];
        }
        uint256 lastCheckpoint = lastPoint.ts;
        uint256 blockSlope = 0; // dblock/dt
        if (block.timestamp > lastPoint.ts) {
            blockSlope =
                (MULTIPLIER * (block.number - lastPoint.blk)) /
                (block.timestamp - lastPoint.ts);
        }
        {
            uint256 ti = (lastCheckpoint / WEEK) * WEEK;
            for (uint256 i = 0; i < 255; i++) {
                ti += WEEK;
                int128 dslope = 0;
                if (ti > block.timestamp) {
                    ti = block.timestamp;
                } else {
                    dslope = slopeChanges[ti];
                }
                // calculate the slope and bia of the new last point
                lastPoint.bias -=
                    lastPoint.slope *
                    int128(int256(ti) - int256(lastCheckpoint));
                lastPoint.slope += dslope;
                if (lastPoint.bias < 0) {
                    lastPoint.bias = 0;
                }
                if (lastPoint.slope < 0) {
                    lastPoint.slope = 0;
                }

                lastCheckpoint = ti;
                lastPoint.ts = ti;
                lastPoint.blk =
                    initialLastPoint.blk +
                    (blockSlope * (ti - initialLastPoint.ts)) /
                    MULTIPLIER;
                _epoch += 1;
                if (ti == block.timestamp) {
                    lastPoint.blk = block.number;
                    pointHistory[_epoch] = lastPoint;
                    break;
                }
                pointHistory[_epoch] = lastPoint;
            }
        }

        epoch = _epoch;
        return lastPoint;
    }

    // @notice Record global and per-user data to checkpoint
    // @param addr User wallet address. No user checkpoint if 0x0
    // @param oldDeposit Previous locked balance / end lock time for the user
    // @param newDeposit New locked balance / end lock time for the user
    function _checkpoint(
        address addr,
        LockedBalance memory oldDeposit,
        LockedBalance memory newDeposit
    ) internal {
        Point memory uOld = Point(0, 0, 0, 0, 0);
        Point memory uNew = Point(0, 0, 0, 0, 0);
        int128 dSlopeOld = 0;
        int128 dSlopeNew = 0;

        if (oldDeposit.amount > 0) {
            int128 amt = int128(oldDeposit.amount);
            if (!oldDeposit.cooldownInitiated) {
                uOld.residue = (amt * I_MIN_TIME) / I_YEAR;
                oldDeposit.end -= WEEK;
            }
            if (oldDeposit.end > block.timestamp) {
                uOld.slope = amt / I_YEAR;

                uOld.bias =
                    uOld.slope *
                    int128(int256(oldDeposit.end) - int256(block.timestamp));
            }
        }
        if ((newDeposit.end > block.timestamp) && (newDeposit.amount > 0)) {
            int128 amt = int128(newDeposit.amount);
            if (!newDeposit.cooldownInitiated) {
                uNew.residue = (amt * I_MIN_TIME) / I_YEAR;
                newDeposit.end -= WEEK;
            }
            if (newDeposit.end > block.timestamp) {
                uNew.slope = amt / I_YEAR;
                uNew.bias =
                    uNew.slope *
                    int128(int256(newDeposit.end) - int256(block.timestamp));
            }
        }

        dSlopeOld = slopeChanges[oldDeposit.end];
        if (newDeposit.end != 0) {
            dSlopeNew = slopeChanges[newDeposit.end];
        }
        // add all global checkpoints from last added global check point until now
        Point memory lastPoint = _updateGlobalPoint();
        // update the last global checkpoint (now) with user action's consequences
        lastPoint.slope += (uNew.slope - uOld.slope);
        lastPoint.bias += (uNew.bias - uOld.bias);
        lastPoint.residue += (uNew.residue - uOld.residue);
        if (lastPoint.slope < 0) {
            lastPoint.slope = 0;
        }
        if (lastPoint.bias < 0) {
            lastPoint.bias = 0;
        }
        pointHistory[epoch] = lastPoint;
        if (oldDeposit.end > block.timestamp) {
            // old_dslope was <something> - u_old.slope, so we cancel that
            dSlopeOld += uOld.slope;
            if (newDeposit.end == oldDeposit.end) {
                dSlopeOld -= uNew.slope;
            }
            slopeChanges[oldDeposit.end] = dSlopeOld;
        }

        if (newDeposit.end > block.timestamp) {
            if (newDeposit.end > oldDeposit.end) {
                dSlopeNew -= uNew.slope;
                // old slope disappeared at this point
                slopeChanges[newDeposit.end] = dSlopeNew;
            }
            // else: we recorded it already in old_dslopes̄
        }
        uint256 userEpc = userPointEpoch[addr] + 1;
        userPointEpoch[addr] = userEpc;
        uNew.ts = block.timestamp;
        uNew.blk = block.number;
        userPointHistory[addr][userEpc] = uNew;
    }

    // @notice Deposit and lock tokens for a user
    // @param addr Address of the user
    // @param value Amount of tokens to deposit
    // @param unlockTime Time when the tokens will be unlocked
    // @param oldDeposit Previous locked balance of the user / timestamp

    function _depositFor(
        address addr,
        bool autoCooldown,
        bool enableCooldown,
        uint128 value,
        uint256 unlockTime,
        LockedBalance memory oldDeposit,
        ActionType _type
    ) internal {
        LockedBalance memory newDeposit = lockedBalances[addr];
        uint256 prevSupply = totalSPALocked;

        totalSPALocked += value;
        newDeposit.amount += value;
        newDeposit.autoCooldown = autoCooldown;
        newDeposit.cooldownInitiated = enableCooldown;
        if (unlockTime != 0) {
            newDeposit.end = unlockTime;
        }
        lockedBalances[addr] = newDeposit;
        _checkpoint(addr, oldDeposit, newDeposit);

        if (value != 0) {
            IERC20Upgradeable(SPA).safeTransferFrom(
                _msgSender(),
                address(this),
                value
            );
        }

        emit UserCheckpoint(_type, autoCooldown, addr, value, newDeposit.end);
        emit Supply(prevSupply, totalSPALocked);
    }

    // @notice Record global data to checkpoint
    function checkpoint() external override {
        _updateGlobalPoint();
        emit GlobalCheckpoint(_msgSender(), epoch);
    }

    // @notice Deposit and lock tokens for a user
    // @dev Anyone (even a smart contract) can deposit tokens for someone else, but
    //      cannot extend their locktime and deposit for a user that is not locked
    // @param addr Address of the user
    // @param value Amount of tokens to deposit
    function depositFor(address addr, uint128 value)
        external
        override
        nonReentrant
    {
        LockedBalance memory existingDeposit = lockedBalances[addr];
        require(value > 0, "Cannot deposit 0 tokens");
        require(existingDeposit.amount > 0, "No existing lock");

        if (!existingDeposit.autoCooldown) {
            require(
                !existingDeposit.cooldownInitiated,
                "Cannot deposit during cooldown"
            );
        }
        // else: auto-cooldown is on, so user can deposit anytime prior to expiry
        require(
            existingDeposit.end > block.timestamp,
            "Lock expired. Withdraw"
        );
        _depositFor(
            addr,
            existingDeposit.autoCooldown,
            existingDeposit.cooldownInitiated,
            value,
            0,
            existingDeposit,
            ActionType.DEPOSIT_FOR
        );
    }

    // @notice Deposit `value` for `msg.sender` and lock untill `unlockTime`
    // @param value Amount of tokens to deposit
    // @param unlockTime Time when the tokens will be unlocked
    // @param autoCooldown Choose to opt in to auto-cooldown
    // @dev if autoCooldown is true, the user's veSPA balance will
    //      decay to 0 after `unlockTime` else the user's veSPA balance
    //      will remain = residual balance till user initiates cooldown
    // @dev unlockTime is rownded down to whole weeks
    function createLock(
        uint128 value,
        uint256 unlockTime,
        bool autoCooldown
    ) external override nonReentrant {
        address account = _msgSender();
        uint256 roundedUnlockTime = (unlockTime / WEEK) * WEEK;
        LockedBalance memory existingDeposit = lockedBalances[account];

        require(value > 0, "Cannot lock 0 tokens");
        require(existingDeposit.amount == 0, "Withdraw old tokens first");
        require(roundedUnlockTime > block.timestamp, "Cannot lock in the past");
        require(
            roundedUnlockTime <= block.timestamp + MAX_TIME,
            "Voting lock can be 4 years max"
        );
        _depositFor(
            account,
            autoCooldown,
            autoCooldown,
            value,
            roundedUnlockTime,
            existingDeposit,
            ActionType.CREATE_LOCK
        );
    }

    // @notice Deposit `value` additional tokens for `msg.sender` without
    //         modifying the locktime
    // @param value Amount of tokens to deposit
    function increaseAmount(uint128 value) external override nonReentrant {
        address account = _msgSender();
        LockedBalance memory existingDeposit = lockedBalances[account];

        require(value > 0, "Cannot deposit 0 tokens");
        require(existingDeposit.amount > 0, "No existing lock found");

        if (!existingDeposit.autoCooldown) {
            require(
                !existingDeposit.cooldownInitiated,
                "Cannot deposit during cooldown"
            );
        }
        // else: auto-cooldown is on, so user can deposit anytime prior to expiry

        require(
            existingDeposit.end > block.timestamp,
            "Lock expired. Withdraw"
        );
        _depositFor(
            account,
            existingDeposit.autoCooldown,
            existingDeposit.cooldownInitiated,
            value,
            0,
            existingDeposit,
            ActionType.INCREASE_AMOUNT
        );
    }

    // @notice Extend the locktime of `msg.sender`'s tokens to `unlockTime`
    // @param unlockTime New locktime
    function increaseUnlockTime(uint256 unlockTime) external override {
        address account = _msgSender();
        LockedBalance memory existingDeposit = lockedBalances[account];
        uint256 roundedUnlockTime = (unlockTime / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(existingDeposit.amount > 0, "No existing lock found");
        if (!existingDeposit.autoCooldown) {
            require(
                !existingDeposit.cooldownInitiated,
                "Deposit is in cooldown"
            );
        }
        // else: auto-cooldown is on, so user can increase unlocktime anytime prior to expiry
        require(
            existingDeposit.end > block.timestamp,
            "Lock expired. Withdraw"
        );
        require(
            roundedUnlockTime > existingDeposit.end,
            "Can only increase lock duration"
        );
        require(
            roundedUnlockTime <= block.timestamp + MAX_TIME,
            "Voting lock can be 4 years max"
        );

        _depositFor(
            account,
            existingDeposit.autoCooldown,
            existingDeposit.cooldownInitiated,
            0,
            roundedUnlockTime,
            existingDeposit,
            ActionType.INCREASE_LOCK_TIME
        );
    }

    // @notice Initiate the cooldown period for `msg.sender`'s deposit
    function initiateCooldown() external override {
        address account = _msgSender();
        LockedBalance memory existingDeposit = lockedBalances[account];
        require(existingDeposit.amount > 0, "No existing lock found");
        require(
            !existingDeposit.cooldownInitiated,
            "Cooldown already initiated"
        );
        require(
            block.timestamp >= existingDeposit.end - MIN_TIME,
            "Can not initiate cool down"
        );

        uint256 roundedUnlockTime = ((block.timestamp + MIN_TIME) / WEEK) *
            WEEK;

        _depositFor(
            account,
            existingDeposit.autoCooldown,
            true,
            0,
            roundedUnlockTime,
            existingDeposit,
            ActionType.INITIATE_COOLDOWN
        );
    }

    // @notice Withdraw tokens for `msg.sender`
    // @dev Only possible if the locktime has expired
    function withdraw() external override nonReentrant {
        address account = _msgSender();
        LockedBalance memory existingDeposit = lockedBalances[account];
        require(existingDeposit.amount > 0, "No existing lock found");
        require(existingDeposit.cooldownInitiated, "No cooldown initiated");
        require(block.timestamp >= existingDeposit.end, "Lock not expired.");
        uint128 value = existingDeposit.amount;

        LockedBalance memory oldDeposit = lockedBalances[account];
        lockedBalances[account] = LockedBalance(false, false, 0, 0);
        uint256 prevSupply = totalSPALocked;
        totalSPALocked -= value;

        // oldDeposit can have either expired <= timestamp or 0 end
        // existingDeposit has 0 end
        // Both can have >= 0 amount
        _checkpoint(account, oldDeposit, LockedBalance(false, false, 0, 0));

        IERC20Upgradeable(SPA).safeTransfer(account, value);
        emit Withdraw(account, value, block.timestamp);
        emit Supply(prevSupply, totalSPALocked);
    }

    // ----------------------VIEW functions----------------------
    // NOTE:The following ERC20/minime-compatible methods are not real balanceOf and supply!!
    // They measure the weights for the purpose of voting, so they don't represent real coins.

    // @notice Binary search to estimate timestamp for block number
    // @param blockNumber Block number to estimate timestamp for
    // @param maxEpoch Don't go beyond this epoch
    // @return Estimated timestamp for block number
    function _findBlockEpoch(uint256 blockNumber, uint256 maxEpoch)
        internal
        view
        returns (uint256)
    {
        uint256 min = 0;
        uint256 max = maxEpoch;

        for (uint256 i = 0; i < 128; i++) {
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 1) / 2;
            if (pointHistory[mid].blk <= blockNumber) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return min;
    }

    function _findUserTimestampEpoch(address addr, uint256 ts)
        internal
        view
        returns (uint256)
    {
        uint256 min = 0;
        uint256 max = userPointEpoch[addr];

        for (uint256 i = 0; i < 128; i++) {
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 1) / 2;
            if (userPointHistory[addr][mid].ts <= ts) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return min;
    }

    function _findGlobalTimestampEpoch(uint256 ts)
        internal
        view
        returns (uint256)
    {
        uint256 min = 0;
        uint256 max = epoch;

        for (uint256 i = 0; i < 128; i++) {
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 1) / 2;
            if (pointHistory[mid].ts <= ts) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return min;
    }

    // @notice Function to estimate the user deposit
    // @param autoCooldown Choose to opt in to auto-cooldown
    // @param value Amount of SPA to deposit
    // @param expectedUnlockTime The expected unlock time
    // @dev if autoCooldown is true, the user's veSPA balance will
    //      decay to 0 after `unlockTime` else the user's veSPA balance
    //      will remain = residual balance till user initiates cooldown
    // @return Estimated deposit
    function estimateDeposit(
        bool autoCooldown,
        uint128 value,
        uint256 expectedUnlockTime
    )
        public
        view
        returns (
            bool,
            int128 initialVespaBalance, // initial veSPA balance
            int128 slope, // slope of the user's graph
            int128 bias, // bias of the user's graph
            int128 residue, // residual balance
            uint256 actualUnlockTime, // actual rounded unlock time
            uint256 providedUnlockTime, // expected unlock time
            uint256 residuePeriodStart
        )
    {
        actualUnlockTime = (expectedUnlockTime / WEEK) * WEEK;

        require(actualUnlockTime > block.timestamp, "Cannot lock in the past");
        require(
            actualUnlockTime <= block.timestamp + MAX_TIME,
            "Voting lock can be 4 years max"
        );

        int128 amt = int128(value);
        slope = amt / I_YEAR;

        if (!autoCooldown) {
            residue = (amt * I_MIN_TIME) / I_YEAR;
            residuePeriodStart = actualUnlockTime - WEEK;
            bias =
                slope *
                int128(
                    int256(actualUnlockTime - WEEK) - int256(block.timestamp)
                );
        } else {
            bias =
                slope *
                int128(int256(actualUnlockTime) - int256(block.timestamp));
        }
        if (bias <= 0) {
            bias = 0;
        }
        initialVespaBalance = bias + residue;

        return (
            autoCooldown,
            initialVespaBalance,
            slope,
            bias,
            residue,
            actualUnlockTime,
            expectedUnlockTime,
            residuePeriodStart
        );
    }

    // @notice Get the voting power for a user at the specified timestamp
    // @dev Adheres to ERC20 `balanceOf` interface for Aragon compatibility
    // @param addr User wallet address
    // @param ts Timestamp to get voting power at
    // @return Voting power of user at timestamp
    function balanceOf(address addr, uint256 ts)
        public
        view
        override
        returns (uint256)
    {
        uint256 _epoch = _findUserTimestampEpoch(addr, ts);
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory lastPoint = userPointHistory[addr][_epoch];
            lastPoint.bias -=
                lastPoint.slope *
                int128(int256(ts) - int256(lastPoint.ts));
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            lastPoint.bias += lastPoint.residue;
            return uint256(int256(lastPoint.bias));
        }
    }

    // @notice Get the current voting power for a user
    // @param addr User wallet address
    // @return Voting power of user at current timestamp
    function balanceOf(address addr) public view override returns (uint256) {
        return balanceOf(addr, block.timestamp);
    }

    // @notice Get the voting power of `addr` at block `blockNumber`
    // @param addr User wallet address
    // @param blockNumber Block number to get voting power at
    // @return Voting power of user at block number
    function balanceOfAt(address addr, uint256 blockNumber)
        public
        view
        override
        returns (uint256)
    {
        uint256 min = 0;
        uint256 max = userPointEpoch[addr];

        // Find the approximate timestamp for the block number
        for (uint256 i = 0; i < 128; i++) {
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 1) / 2;
            if (userPointHistory[addr][mid].blk <= blockNumber) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        // min is the userEpoch nearest to the block number
        Point memory uPoint = userPointHistory[addr][min];
        uint256 maxEpoch = epoch;

        // blocktime using the global point history
        uint256 _epoch = _findBlockEpoch(blockNumber, maxEpoch);
        Point memory point0 = pointHistory[_epoch];
        uint256 dBlock = 0;
        uint256 dt = 0;

        if (_epoch < maxEpoch) {
            Point memory point1 = pointHistory[_epoch + 1];
            dBlock = point1.blk - point0.blk;
            dt = point1.ts - point0.ts;
        } else {
            dBlock = blockNumber - point0.blk;
            dt = block.timestamp - point0.ts;
        }

        uint256 blockTime = point0.ts;
        if (dBlock != 0) {
            blockTime += (dt * (blockNumber - point0.blk)) / dBlock;
        }

        uPoint.bias -=
            uPoint.slope *
            int128(int256(blockTime) - int256(uPoint.ts));
        if (uPoint.bias < 0) {
            uPoint.bias = 0;
        }
        uPoint.bias += uPoint.residue;
        return uint256(int256(uPoint.bias));
    }

    // @notice Calculate total voting power at some point in the past
    // @param point The point (bias/slope) to start search from
    // @param ts Timestamp to calculate total voting power at
    // @return Total voting power at timestamp
    function supplyAt(Point memory point, uint256 ts)
        internal
        view
        returns (uint256)
    {
        Point memory lastPoint = point;
        uint256 ti = (lastPoint.ts / WEEK) * WEEK;

        // Calculate the missing checkpoints
        for (uint256 i = 0; i < 255; i++) {
            ti += WEEK;
            int128 dSlope = 0;
            if (ti > ts) {
                ti = ts;
            } else {
                dSlope = slopeChanges[ti];
            }
            lastPoint.bias -=
                lastPoint.slope *
                int128(int256(ti) - int256(lastPoint.ts));
            if (ti == ts) {
                break;
            }
            lastPoint.slope += dSlope;
            lastPoint.ts = ti;
        }

        if (lastPoint.bias < 0) {
            lastPoint.bias = 0;
        }
        lastPoint.bias += lastPoint.residue;
        return uint256(int256(lastPoint.bias));
    }

    // @notice Calculate total voting power at a given timestamp
    // @return Total voting power at timestamp
    function totalSupply(uint256 ts) public view override returns (uint256) {
        uint256 _epoch = _findGlobalTimestampEpoch(ts);
        Point memory lastPoint = pointHistory[_epoch];
        return supplyAt(lastPoint, ts);
    }

    // @notice Calculate total voting power at current timestamp
    // @return Total voting power at current timestamp
    function totalSupply() public view override returns (uint256) {
        return totalSupply(block.timestamp);
    }

    // @notice Calculate total voting power at a given block number in past
    // @param blockNumber Block number to calculate total voting power at
    // @return Total voting power at block number
    function totalSupplyAt(uint256 blockNumber)
        external
        view
        override
        returns (uint256)
    {
        require(blockNumber <= block.number);
        uint256 _epoch = epoch;
        uint256 targetEpoch = _findBlockEpoch(blockNumber, _epoch);

        Point memory point0 = pointHistory[targetEpoch];
        uint256 dt = 0;

        if (targetEpoch < _epoch) {
            Point memory point1 = pointHistory[targetEpoch + 1];
            dt =
                ((blockNumber - point0.blk) * (point1.ts - point0.ts)) /
                (point1.blk - point0.blk);
        } else {
            if (point0.blk != block.number) {
                dt =
                    ((blockNumber - point0.blk) *
                        (block.timestamp - point0.ts)) /
                    (block.number - point0.blk);
            }
        }
        // Now dt contains info on how far we are beyond point0
        return supplyAt(point0, point0.ts + dt);
    }
}