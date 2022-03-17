// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

/***
 *@title VeBend
 *@notice Votes have a weight depending on time, so that users are
 *        committed to the future of (whatever they are voting for)
 *@dev Vote weight decays linearly over time. Lock time cannot be
 *     more than `MAXTIME` (4 years).
 */

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime
// w ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> time
//       maxtime (4 years?)

// Interface for checking whether address belongs to a whitelisted
// type of a smart wallet.
// When new types are added - the whole contract is changed
// The check() method is modifying to be able to use caching
// for individual wallet addresses

//libraries
import {IVeBend} from "./interfaces/IVeBend.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract VeBend is IVeBend, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // We cannot really do block numbers per se b/c slope is per time, not per block
    // and per block could be fairly bad b/c Ethereum changes blocktimes.
    // What we can do is to extrapolate ***At functions

    uint256 private constant DEPOSIT_FOR_TYPE = 0;
    uint256 private constant CREATE_LOCK_TYPE = 1;
    uint256 private constant INCREASE_LOCK_AMOUNT = 2;
    uint256 private constant INCREASE_UNLOCK_TIME = 3;

    uint256 public constant WEEK = 7 * 86400; // all future times are rounded by week
    uint256 public constant MAXTIME = 4 * 365 * 86400; // 4 years
    uint256 public constant MULTIPLIER = 10**18;

    address public token;
    uint256 public supply;

    mapping(address => LockedBalance) public locked;

    //everytime user deposit/withdraw/change_locktime, these values will be updated;
    uint256 public override epoch;
    mapping(uint256 => Point) public supplyPointHistory; // epoch -> unsigned point.
    mapping(address => mapping(uint256 => Point)) public userPointHistory; // user -> Point[user_epoch]
    mapping(address => uint256) public userPointEpoch;
    mapping(uint256 => int256) public slopeChanges; // time -> signed slope change

    string public name;
    string public symbol;
    uint256 public decimals;

    function initialize(address _tokenAddr) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        token = _tokenAddr;
        supplyPointHistory[0] = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });
        decimals = 18;
        name = "Vote-escrowed BEND";
        symbol = "veBEND";
    }

    function getLocked(address _addr)
        external
        view
        override
        returns (LockedBalance memory)
    {
        return locked[_addr];
    }

    function getUserPointEpoch(address _userAddress)
        external
        view
        override
        returns (uint256)
    {
        return userPointEpoch[_userAddress];
    }

    function getSupplyPointHistory(uint256 _index)
        external
        view
        override
        returns (Point memory)
    {
        return supplyPointHistory[_index];
    }

    function getUserPointHistory(address _userAddress, uint256 _index)
        external
        view
        override
        returns (Point memory)
    {
        return userPointHistory[_userAddress][_index];
    }

    /***
     *@dev Get the most recently recorded rate of voting power decrease for `_addr`
     *@param _addr Address of the user wallet
     *@return Value of the slope
     */
    function getLastUserSlope(address _addr) external view returns (int256) {
        uint256 uepoch = userPointEpoch[_addr];
        return userPointHistory[_addr][uepoch].slope;
    }

    /***
     *@dev Get the timestamp for checkpoint `_idx` for `_addr`
     *@param _addr User wallet address
     *@param _idx User epoch number
     *@return Epoch time of the checkpoint
     */
    function userPointHistoryTs(address _addr, uint256 _idx)
        external
        view
        returns (uint256)
    {
        return userPointHistory[_addr][_idx].ts;
    }

    /***
     *@dev Get timestamp when `_addr`'s lock finishes
     *@param _addr User wallet
     *@return Epoch time of the lock end
     */
    function lockedEnd(address _addr) external view returns (uint256) {
        return locked[_addr].end;
    }

    //Struct to avoid "Stack Too Deep"
    struct CheckpointParameters {
        Point userOldPoint;
        Point userNewPoint;
        int256 oldDslope;
        int256 newDslope;
        uint256 epoch;
    }

    /***
     *@dev Record global and per-user data to checkpoint
     *@param _addr User's wallet address. No user checkpoint if 0x0
     *@param _oldLocked Pevious locked amount / end lock time for the user
     *@param _newLocked New locked amount / end lock time for the user
     */
    function _checkpoint(
        address _addr,
        LockedBalance memory _oldLocked,
        LockedBalance memory _newLocked
    ) internal {
        CheckpointParameters memory _st;
        _st.epoch = epoch;

        if (_addr != address(0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (_oldLocked.end > block.timestamp && _oldLocked.amount > 0) {
                _st.userOldPoint.slope = _oldLocked.amount / int256(MAXTIME);
                _st.userOldPoint.bias =
                    _st.userOldPoint.slope *
                    int256(_oldLocked.end - block.timestamp);
            }
            if (_newLocked.end > block.timestamp && _newLocked.amount > 0) {
                _st.userNewPoint.slope = _newLocked.amount / int256(MAXTIME);
                _st.userNewPoint.bias =
                    _st.userNewPoint.slope *
                    int256(_newLocked.end - block.timestamp);
            }

            // Read values of scheduled changes in the slope
            // _oldLocked.end can be in the past and in the future
            // _newLocked.end can ONLY by in the FUTURE unless everything expired than zeros
            _st.oldDslope = slopeChanges[_oldLocked.end];
            if (_newLocked.end != 0) {
                if (_newLocked.end == _oldLocked.end) {
                    _st.newDslope = _st.oldDslope;
                } else {
                    _st.newDslope = slopeChanges[_newLocked.end];
                }
            }
        }
        Point memory _lastPoint = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });
        if (_st.epoch > 0) {
            _lastPoint = supplyPointHistory[_st.epoch];
        }
        uint256 _lastCheckPoint = _lastPoint.ts;
        // _initialLastPoint is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        // Point memory _initialLastPoint = _lastPoint;
        uint256 _initBlk = _lastPoint.blk;
        uint256 _initTs = _lastPoint.ts;

        uint256 _blockSlope = 0; // dblock/dt
        if (block.timestamp > _lastPoint.ts) {
            _blockSlope =
                (MULTIPLIER * (block.number - _lastPoint.blk)) /
                (block.timestamp - _lastPoint.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        uint256 _ti = (_lastCheckPoint / WEEK) * WEEK;
        for (uint256 i; i < 255; i++) {
            // Hopefully it won't happen that this won't get used in 5 years!
            // If it does, users will be able to withdraw but vote weight will be broken
            _ti += WEEK;
            int256 d_slope = 0;
            if (_ti > block.timestamp) {
                // reach future time, reset to blok time
                _ti = block.timestamp;
            } else {
                d_slope = slopeChanges[_ti];
            }
            _lastPoint.bias =
                _lastPoint.bias -
                _lastPoint.slope *
                int256(_ti - _lastCheckPoint);
            _lastPoint.slope += d_slope;
            if (_lastPoint.bias < 0) {
                // This can happen
                _lastPoint.bias = 0;
            }
            if (_lastPoint.slope < 0) {
                // This cannot happen - just in case
                _lastPoint.slope = 0;
            }
            _lastCheckPoint = _ti;
            _lastPoint.ts = _ti;
            _lastPoint.blk =
                _initBlk +
                ((_blockSlope * (_ti - _initTs)) / MULTIPLIER);
            _st.epoch += 1;
            if (_ti == block.timestamp) {
                // history filled over, break loop
                _lastPoint.blk = block.number;
                break;
            } else {
                supplyPointHistory[_st.epoch] = _lastPoint;
            }
        }
        epoch = _st.epoch;
        // Now supplyPointHistory is filled until t=now

        if (_addr != address(0)) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            _lastPoint.slope += _st.userNewPoint.slope - _st.userOldPoint.slope;
            _lastPoint.bias += _st.userNewPoint.bias - _st.userOldPoint.bias;
            if (_lastPoint.slope < 0) {
                _lastPoint.slope = 0;
            }
            if (_lastPoint.bias < 0) {
                _lastPoint.bias = 0;
            }
        }
        // Record the changed point into history
        supplyPointHistory[_st.epoch] = _lastPoint;
        if (_addr != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [_newLocked.end]
            // and add old_user_slope to [_oldLocked.end]
            if (_oldLocked.end > block.timestamp) {
                // _oldDslope was <something> - _userOldPoint.slope, so we cancel that
                _st.oldDslope += _st.userOldPoint.slope;
                if (_newLocked.end == _oldLocked.end) {
                    _st.oldDslope -= _st.userNewPoint.slope; // It was a new deposit, not extension
                }
                slopeChanges[_oldLocked.end] = _st.oldDslope;
            }
            if (_newLocked.end > block.timestamp) {
                if (_newLocked.end > _oldLocked.end) {
                    _st.newDslope -= _st.userNewPoint.slope; // old slope disappeared at this point
                    slopeChanges[_newLocked.end] = _st.newDslope;
                }
                // else we recorded it already in _oldDslope
            }

            // Now handle user history
            uint256 _userEpoch = userPointEpoch[_addr] + 1;

            userPointEpoch[_addr] = _userEpoch;
            _st.userNewPoint.ts = block.timestamp;
            _st.userNewPoint.blk = block.number;
            userPointHistory[_addr][_userEpoch] = _st.userNewPoint;
        }
    }

    /***
     *@dev Deposit and lock tokens for a user
     *@param _addr User's wallet address
     *@param _value Amount to deposit
     *@param _unlockTime New time when to unlock the tokens, or 0 if unchanged
     *@param _lockedBalance Previous locked amount / timestamp
     */
    function _depositFor(
        address _provider,
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime,
        LockedBalance memory _lockedBalance,
        uint256 _type
    ) internal {
        LockedBalance memory _locked = LockedBalance(
            _lockedBalance.amount,
            _lockedBalance.end
        );
        LockedBalance memory _oldLocked = LockedBalance(
            _lockedBalance.amount,
            _lockedBalance.end
        );

        uint256 _supplyBefore = supply;
        supply = _supplyBefore + _value;
        //Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount = _locked.amount + int256(_value);
        if (_unlockTime != 0) {
            _locked.end = _unlockTime;
        }
        locked[_beneficiary] = _locked;

        // Possibilities
        // Both _oldLocked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)

        _checkpoint(_beneficiary, _oldLocked, _locked);
        if (_value != 0) {
            IERC20Upgradeable(token).safeTransferFrom(
                _provider,
                address(this),
                _value
            );
        }

        emit Deposit(
            _provider,
            _beneficiary,
            _value,
            _locked.end,
            _type,
            block.timestamp
        );
        emit Supply(_supplyBefore, _supplyBefore + _value);
    }

    /***
     *@notice Record total supply to checkpoint
     */
    function checkpointSupply() public override {
        LockedBalance memory _a;
        LockedBalance memory _b;
        _checkpoint(address(0), _a, _b);
    }

    function createLockFor(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime
    ) external override {
        _createLock(_beneficiary, _value, _unlockTime);
    }

    function createLock(uint256 _value, uint256 _unlockTime) external override {
        _createLock(msg.sender, _value, _unlockTime);
    }

    /***
     *@dev Deposit `_value` tokens for `msg.sender` and lock until `_unlockTime`
     *@param _value Amount to deposit
     *@param _unlockTime Epoch time when tokens unlock, rounded down to whole weeks
     */
    function _createLock(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime
    ) internal nonReentrant {
        _unlockTime = (_unlockTime / WEEK) * WEEK; // Locktime is rounded down to weeks
        LockedBalance memory _locked = locked[_beneficiary];

        require(_value > 0, "Can't lock zero value");
        require(_locked.amount == 0, "Withdraw old tokens first");
        require(
            _unlockTime > block.timestamp,
            "Can only lock until time in the future"
        );
        require(
            _unlockTime <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _depositFor(
            msg.sender,
            _beneficiary,
            _value,
            _unlockTime,
            _locked,
            CREATE_LOCK_TYPE
        );
    }

    function increaseAmount(uint256 _value) external override {
        _increaseAmount(msg.sender, _value);
    }

    function increaseAmountFor(address _beneficiary, uint256 _value)
        external
        override
    {
        _increaseAmount(_beneficiary, _value);
    }

    /***
     *@dev Deposit `_value` additional tokens for `msg.sender`
     *        without modifying the unlock time
     *@param _value Amount of tokens to deposit and add to the lock
     */
    function _increaseAmount(address _beneficiary, uint256 _value)
        internal
        nonReentrant
    {
        LockedBalance memory _locked = locked[_beneficiary];

        require(_value > 0, "Can't increase zero value");
        require(_locked.amount > 0, "No existing lock found");
        require(
            _locked.end > block.timestamp,
            "Cannot add to expired lock. Withdraw"
        );

        _depositFor(
            msg.sender,
            _beneficiary,
            _value,
            0,
            _locked,
            INCREASE_LOCK_AMOUNT
        );
    }

    /***
     *@dev Extend the unlock time for `msg.sender` to `_unlockTime`
     *@param _unlockTime New epoch time for unlocking
     */
    function increaseUnlockTime(uint256 _unlockTime)
        external
        override
        nonReentrant
    {
        LockedBalance memory _locked = locked[msg.sender];
        _unlockTime = (_unlockTime / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp, "Lock expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(_unlockTime > _locked.end, "Can only increase lock duration");
        require(
            _unlockTime <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _depositFor(
            msg.sender,
            msg.sender,
            0,
            _unlockTime,
            _locked,
            INCREASE_UNLOCK_TIME
        );
    }

    /***
     *@dev Withdraw all tokens for `msg.sender`
     *@dev Only possible if the lock has expired
     */
    function withdraw() external override nonReentrant {
        LockedBalance memory _locked = LockedBalance(
            locked[msg.sender].amount,
            locked[msg.sender].end
        );

        require(block.timestamp >= _locked.end, "The lock didn't expire");
        uint256 _value = uint256(_locked.amount);

        LockedBalance memory _oldLocked = LockedBalance(
            locked[msg.sender].amount,
            locked[msg.sender].end
        );

        _locked.end = 0;
        _locked.amount = 0;
        locked[msg.sender] = _locked;
        uint256 _supplyBefore = supply;
        supply = _supplyBefore - _value;

        // _oldLocked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, _oldLocked, _locked);

        IERC20Upgradeable(token).safeTransfer(msg.sender, _value);

        emit Withdraw(msg.sender, _value, block.timestamp);
        emit Supply(_supplyBefore, _supplyBefore - _value);
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    /***
     *@dev Binary search to estimate timestamp for block number
     *@param _block Block to find
     *@param _max_epoch Don't go beyond this epoch
     *@return Approximate timestamp for block
     */
    function findBlockEpoch(uint256 _block, uint256 _max_epoch)
        internal
        view
        returns (uint256)
    {
        // Binary search
        uint256 _min = 0;
        uint256 _max = _max_epoch;
        for (uint256 i; i <= 128; i++) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (supplyPointHistory[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /***
     *@notice Get the current voting power for `msg.sender`
     *@dev Adheres to the ERC20 `balanceOf` interface for Metamask & Snapshot compatibility
     *@param _addr User wallet address
     *@return User's present voting power
     */
    function balanceOf(address _addr) external view returns (uint256) {
        uint256 _t = block.timestamp;

        uint256 _epoch = userPointEpoch[_addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory _lastPoint = userPointHistory[_addr][_epoch];
            _lastPoint.bias -= _lastPoint.slope * int256(_t - _lastPoint.ts);
            if (_lastPoint.bias < 0) {
                _lastPoint.bias = 0;
            }
            return uint256(_lastPoint.bias);
        }
    }

    /***
     *@notice Get the current voting power for `msg.sender`
     *@dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     *@param _addr User wallet address
     *@param _t Epoch time to return voting power at
     *@return User voting power
     *@dev return the present voting power if _t is 0
     */
    function balanceOf(address _addr, uint256 _t)
        external
        view
        returns (uint256)
    {
        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = userPointEpoch[_addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory _lastPoint = userPointHistory[_addr][_epoch];
            _lastPoint.bias -= _lastPoint.slope * int256(_t - _lastPoint.ts);
            if (_lastPoint.bias < 0) {
                _lastPoint.bias = 0;
            }
            return uint256(_lastPoint.bias);
        }
    }

    //Struct to avoid "Stack Too Deep"
    struct Parameters {
        uint256 min;
        uint256 max;
        uint256 maxEpoch;
        uint256 dBlock;
        uint256 dt;
    }

    /***
     *@notice Measure voting power of `_addr` at block height `_block`
     *@dev Adheres to MiniMe `balanceOfAt` interface https//github.com/Giveth/minime
     *@param _addr User's wallet address
     *@param _block Block to calculate the voting power at
     *@return Voting power
     */
    function balanceOfAt(address _addr, uint256 _block)
        external
        view
        returns (uint256)
    {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        require(_block <= block.number, "Can't exceed lasted block");

        Parameters memory _st;

        // Binary search
        _st.min = 0;
        _st.max = userPointEpoch[_addr];

        for (uint256 i; i <= 128; i++) {
            // Will be always enough for 128-bit numbers
            if (_st.min >= _st.max) {
                break;
            }
            uint256 _mid = (_st.min + _st.max + 1) / 2;
            if (userPointHistory[_addr][_mid].blk <= _block) {
                _st.min = _mid;
            } else {
                _st.max = _mid - 1;
            }
        }
        Point memory _upoint = userPointHistory[_addr][_st.min];

        _st.maxEpoch = epoch;
        uint256 _epoch = findBlockEpoch(_block, _st.maxEpoch);
        Point memory _point = supplyPointHistory[_epoch];
        _st.dBlock = 0;
        _st.dt = 0;
        if (_epoch < _st.maxEpoch) {
            Point memory _point_1 = supplyPointHistory[_epoch + 1];
            _st.dBlock = _point_1.blk - _point.blk;
            _st.dt = _point_1.ts - _point.ts;
        } else {
            _st.dBlock = block.number - _point.blk;
            _st.dt = block.timestamp - _point.ts;
        }
        uint256 block_time = _point.ts;
        if (_st.dBlock != 0) {
            block_time += (_st.dt * (_block - _point.blk)) / _st.dBlock;
        }

        _upoint.bias -= _upoint.slope * int256(block_time - _upoint.ts);
        if (_upoint.bias >= 0) {
            return uint256(_upoint.bias);
        } else {
            return 0;
        }
    }

    /***
     *@dev Calculate total voting power at some point in the past
     *@param point The point (bias/slope) to start search from
     *@param t Time to calculate the total voting power at
     *@return Total voting power at that time
     */
    function supplyAt(Point memory point, uint256 t)
        internal
        view
        returns (uint256)
    {
        Point memory _lastPoint = point;
        uint256 _ti = (_lastPoint.ts / WEEK) * WEEK;
        for (uint256 i; i < 255; i++) {
            _ti += WEEK;
            int256 d_slope = 0;

            if (_ti > t) {
                _ti = t;
            } else {
                d_slope = slopeChanges[_ti];
            }
            _lastPoint.bias -= _lastPoint.slope * int256(_ti - _lastPoint.ts);

            if (_ti == t) {
                break;
            }
            _lastPoint.slope += d_slope;
            _lastPoint.ts = _ti;
        }

        if (_lastPoint.bias < 0) {
            _lastPoint.bias = 0;
        }
        return uint256(_lastPoint.bias);
    }

    /***
     *@notice Calculate total voting power
     *@dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     *@return Total voting power
     */
    function totalSupply() external view returns (uint256) {
        uint256 _epoch = epoch;
        Point memory _lastPoint = supplyPointHistory[_epoch];

        return supplyAt(_lastPoint, block.timestamp);
    }

    /***
     *@notice Calculate total voting power
     *@dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     *@return Total voting power
     */
    function totalSupply(uint256 _t) external view returns (uint256) {
        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = epoch;
        Point memory _lastPoint = supplyPointHistory[_epoch];

        return supplyAt(_lastPoint, _t);
    }

    /***
     *@notice Calculate total voting power at some point in the past
     *@param _block Block to calculate the total voting power at
     *@return Total voting power at `_block`
     */
    function totalSupplyAt(uint256 _block) external view returns (uint256) {
        require(_block <= block.number, "Can't exceed the latest block");
        uint256 _epoch = epoch;
        uint256 _targetEpoch = findBlockEpoch(_block, _epoch);

        Point memory _point = supplyPointHistory[_targetEpoch];
        uint256 dt = 0;
        if (_targetEpoch < _epoch) {
            Point memory _pointNext = supplyPointHistory[_targetEpoch + 1];
            if (_point.blk != _pointNext.blk) {
                dt =
                    ((_block - _point.blk) * (_pointNext.ts - _point.ts)) /
                    (_pointNext.blk - _point.blk);
            }
        } else {
            if (_point.blk != block.number) {
                dt =
                    ((_block - _point.blk) * (block.timestamp - _point.ts)) /
                    (block.number - _point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point

        return supplyAt(_point, _point.ts + dt);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IVeBend {
    struct Point {
        int256 bias;
        int256 slope;
        uint256 ts;
        uint256 blk;
    }

    struct LockedBalance {
        int256 amount;
        uint256 end;
    }

    event Deposit(
        address indexed provider,
        address indexed beneficiary,
        uint256 value,
        uint256 indexed locktime,
        uint256 _type,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 value, uint256 ts);

    event Supply(uint256 prevSupply, uint256 supply);

    function createLock(uint256 _value, uint256 _unlockTime) external;

    function createLockFor(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime
    ) external;

    function increaseAmount(uint256 _value) external;

    function increaseAmountFor(address _beneficiary, uint256 _value) external;

    function increaseUnlockTime(uint256 _unlockTime) external;

    function checkpointSupply() external;

    function withdraw() external;

    function getLocked(address _addr) external returns (LockedBalance memory);

    function getUserPointEpoch(address _userAddress)
        external
        view
        returns (uint256);

    function epoch() external view returns (uint256);

    function getUserPointHistory(address _userAddress, uint256 _index)
        external
        view
        returns (Point memory);

    function getSupplyPointHistory(uint256 _index)
        external
        view
        returns (Point memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}