// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "./interfaces/IVeV1.sol";
import "./libraries/PointLib.sol";
import "./libraries/Math.sol";
import "./libraries/Base64.sol";
import "./libraries/String.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/**
@title Voting Escrow
@author Curve Finance
@license MIT
@notice Votes have a weight depending on time, so that users are
committed to the future of (whatever they are voting for)
@dev Vote weight decays linearly over time. Lock time cannot be
more than `MAXTIME` (4 years).

# Voting escrow to have time-weighted votes
# Votes have a weight depending on time, so that users are committed
# to the future of (whatever they are voting for).
# The weight in this implementation is linear, and lock cannot be more than maxtime:
# w ^
# 1 +        /
#   |      /
#   |    /
#   |  /
#   |/
# 0 +--------+------> time
#       maxtime (4 years?)

User voting power w_i is linearly decreasing since the moment of lock. 
So does the total voting power W. 

In order to avoid periodic check-ins, every time the user deposits,
or withdraws, or changes the locktime, we record user’s slope and bias for 
the linear function w_i(t) in the public mapping `userPointHistory`. 

We also change slope and bias for the total voting power W(t) and record it 
in `pointHistory`. 

In addition, when a user’s lock is scheduled to end, we schedule change of 
slopes of W(t) in the future in `slopeChanges`. 
Every change involves increasing the `epoch` by 1.

This way we don’t have to iterate over all users to figure out, 
how much should W(t) change by, neither we require users to check in periodically. 
However, we limit the end of user locks to times rounded off by whole weeks.

Slopes and biases change both when a user deposits and locks governance tokens, 
and when the locktime expires. All the possible expiration times are rounded 
to whole weeks to make number of reads from blockchain proportional to number 
of missed weeks at most, not number of users (which is potentially large).
*/

struct LockedBalance {
    int128 amount;
    uint256 end;
}

enum DepositType {
    DEPOSIT_FOR,
    CREATE_LOCK,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME,
    MERGE
}

// TODO: upgradeable?
// TODO: check code with Curve VE

// solhint-disable not-rely-on-time, quotes /*
contract VeV1 is ERC721, ReentrancyGuard, Ownable {
    event SetVoter(address voter);
    event Deposit(
        address indexed provider,
        uint256 tokenId,
        uint256 value,
        uint256 indexed lockTime,
        DepositType depositType,
        uint256 timestamp
    );
    event Withdraw(
        address indexed provider,
        uint256 tokenId,
        uint256 value,
        uint256 timestamp
    );
    event Supply(uint256 prevSupply, uint256 supply);

    uint256 private constant WEEK = 7 days;
    uint256 private constant MAXTIME = 4 * 365 days;
    int128 private constant IMAXTIME = 4 * 365 days;
    // Multiplier for block slope = block delta / time delta
    uint256 private constant BLOCK_SLOPE_MULTIPLIER = 10**18;

    address public immutable halo;
    // Total amount of HALO locked
    uint256 public supply;
    // VE token id => locked balance
    mapping(uint256 => LockedBalance) public locked;
    // VE token id => block number
    mapping(uint256 => uint256) public ownershipChange;

    uint256 public epoch;
    // Epoch => unsigned point
    mapping(uint256 => Point) public pointHistory;
    // VE token id => epoch
    mapping(uint256 => uint256) public userPointEpoch;
    // VE token id => user epoch => Point
    mapping(uint256 => mapping(uint256 => Point)) public userPointHistory;
    // Future slope changes to be applied to points in pointHistory
    // Timestamp => signed slope change
    mapping(uint256 => int128) public slopeChanges;

    // VE token id => count of gauges this token is registered to
    mapping(uint256 => uint256) public numAttachments;
    // VE token id => voted
    mapping(uint256 => bool) public voted;
    address public voter;

    // Current count of VE token
    uint256 private tokenId;

    constructor(address _halo) ERC721("veHALO", "veHALO") {
        halo = _halo;
        pointHistory[0] = Point({
            bias: 0,
            slope: 0,
            timestamp: block.timestamp,
            blk: block.number
        });
    }

    modifier onlyVoter() {
        require(msg.sender == voter, "not voter");
        _;
    }

    /**
     * @notice Check token is not attached to any Gauge and it's not used in Voter
     */
    modifier notAttached(uint256 _tokenId) {
        require(numAttachments[_tokenId] == 0 && !voted[_tokenId], "attached");
        _;
    }

    function setVoter(address _voter) external onlyOwner {
        voter = _voter;
        emit SetVoter(_voter);
    }

    function setVoted(uint256 _tokenId, bool _voted) external onlyVoter {
        voted[_tokenId] = _voted;
    }

    /**
     * @notice Increment number of gauges this token id is registered in
     * @param _tokenId Token id that was registered to a gauge
     */
    function attach(uint256 _tokenId) external onlyVoter {
        require(_tokenId > 0, "invalid token");
        ++numAttachments[_tokenId];
    }

    /**
     * @notice Decrement number of gauges this token id is registered in
     * @param _tokenId Token id that was unregistered from a gauge
     */
    function detach(uint256 _tokenId) external onlyVoter {
        require(_tokenId > 0, "invalid token");
        --numAttachments[_tokenId];
    }

    /**
     * @notice Record global and per-user data to checkpoint
     * @param _tokenId NFT token ID. No user checkpoint if 0
     * @param oldLocked Previous locked amount / end lock time for the user
     * @param newLocked New locked amount / end lock time for the user
     */
    function _checkpoint(
        uint256 _tokenId,
        LockedBalance memory oldLocked,
        LockedBalance memory newLocked
    ) private {
        // old user point
        Point memory uOld;
        // new user point
        Point memory uNew;
        int128 oldDslope;
        int128 newDslope;
        uint256 _epoch = epoch;

        if (_tokenId != 0) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            /*
            s = slope
            b = bias
            l = locked amount
            t0 = lock start
            e = lock end
            M = max time

            l |\
              | \
              |  \ s
            b |\s \
              | \  \
              |__\__\__
              t0  e   M

              s = a / M
              b = s * (e - t0)

              t = current time
              t_l = time left to unlock = (e - t)
              vote weight = a * t_l / M
            */
            if (oldLocked.end > block.timestamp && oldLocked.amount > 0) {
                uOld.slope = oldLocked.amount / IMAXTIME;
                uOld.bias =
                    uOld.slope *
                    int128(int256(oldLocked.end - block.timestamp));
            }
            if (newLocked.end > block.timestamp && newLocked.amount > 0) {
                uNew.slope = newLocked.amount / IMAXTIME;
                uNew.bias =
                    uNew.slope *
                    int128(int256(newLocked.end - block.timestamp));
            }

            // Read values of scheduled changes in the slope
            // oldLocked.end can be in the past and in the future
            // newLocked.end can ONLY by in the FUTURE unless everything expired
            oldDslope = slopeChanges[oldLocked.end];
            if (newLocked.end > 0) {
                if (newLocked.end == oldLocked.end) {
                    newDslope = oldDslope;
                } else {
                    newDslope = slopeChanges[newLocked.end];
                }
            }
        }

        Point memory lastPoint = Point({
            bias: 0,
            slope: 0,
            timestamp: block.timestamp,
            blk: block.number
        });
        if (_epoch > 0) {
            lastPoint = pointHistory[_epoch];
        }

        uint256 lastCheckpoint = lastPoint.timestamp;

        // initialLastPoint is used to approximate block number
        Point memory initialLastPoint = Point({
            bias: lastPoint.bias,
            slope: lastPoint.slope,
            timestamp: lastPoint.timestamp,
            blk: lastPoint.blk
        });
        // block delta / time delta
        uint256 blockSlope;
        if (block.timestamp > lastPoint.timestamp) {
            blockSlope =
                (BLOCK_SLOPE_MULTIPLIER * (block.number - lastPoint.blk)) /
                (block.timestamp - lastPoint.timestamp);
        }
        // If last point is already recorded in this block, slope = 0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        {
            uint256 tI = (lastCheckpoint / WEEK) * WEEK;
            // Hopefully it won't happen that this won't get used in 5 years!
            // If it does, users will be able to withdraw but vote weight will be broken
            for (uint256 i = 0; i < 255; ++i) {
                tI += WEEK;

                int128 dSlope;
                if (tI > block.timestamp) {
                    tI = block.timestamp;
                } else {
                    dSlope = slopeChanges[tI];
                }

                lastPoint.bias -=
                    lastPoint.slope *
                    int128(int256(tI - lastCheckpoint));
                lastPoint.slope += dSlope;

                if (lastPoint.bias < 0) {
                    // This can happen
                    lastPoint.bias = 0;
                }
                if (lastPoint.slope < 0) {
                    // This cannot happen - just in case
                    lastPoint.slope = 0;
                }

                lastCheckpoint = tI;
                lastPoint.timestamp = tI;
                // Approximate block
                lastPoint.blk =
                    initialLastPoint.blk +
                    (blockSlope * (tI - initialLastPoint.timestamp)) /
                    BLOCK_SLOPE_MULTIPLIER;

                ++_epoch;

                if (tI == block.timestamp) {
                    lastPoint.blk = block.number;
                    break;
                } else {
                    pointHistory[_epoch] = lastPoint;
                }
            }
        }
        // Now pointHistory is filled until t = now

        epoch = _epoch;

        if (_tokenId != 0) {
            // If last point was in this block, the slope change has been applied
            // already. But in such case we have 0 slope(s)
            lastPoint.slope += (uNew.slope - uOld.slope);
            lastPoint.bias += (uNew.bias - uOld.bias);

            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
        }

        // Record the changed point into history
        pointHistory[_epoch] = lastPoint;

        if (_tokenId != 0) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from slopeChanges[newLocked.end]
            // and add old_user_slope to slopeChanges[oldLocked.end]
            if (oldLocked.end > block.timestamp) {
                // oldDslope was <something> - uOld.slope, so we cancel that
                oldDslope += uOld.slope;
                if (newLocked.end == oldLocked.end) {
                    oldDslope -= uNew.slope; // It was a new deposit, not extension
                }
                slopeChanges[oldLocked.end] = oldDslope;
            }

            if (newLocked.end > block.timestamp) {
                if (newLocked.end > oldLocked.end) {
                    newDslope -= uNew.slope; // old slope disappeared at this point
                    slopeChanges[newLocked.end] = newDslope;
                }
                // else: we recorded it already in oldDslope
            }

            // Now handle user history
            uint256 userEpoch = userPointEpoch[_tokenId] + 1;
            userPointEpoch[_tokenId] = userEpoch;
            uNew.timestamp = block.timestamp;
            uNew.blk = block.number;
            userPointHistory[_tokenId][userEpoch] = uNew;
        }
    }

    /**
     * @notice Record global data to checkpoint
     */
    function checkpoint() external {
        _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
    }

    /**
     * @notice Deposit and lock tokens for a user
     * @param _tokenId NFT that holds lock
     * @param _value Amount to deposit
     * @param unlockTime New time when to unlock the tokens, or 0 if unchanged
     * @param _locked Previous locked amount / timestamp
     * @param depositType The type of deposit
     */
    function _depositFor(
        uint256 _tokenId,
        uint256 _value,
        uint256 unlockTime,
        LockedBalance memory _locked,
        DepositType depositType
    ) private {
        uint256 supplyBefore = supply;
        supply = supplyBefore + _value;

        // copy _locked
        LockedBalance memory oldLocked = LockedBalance({
            amount: _locked.amount,
            end: _locked.end
        });

        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount += int128(int256(_value));
        // unlock time = 0 for depositFor, increaseAmount and increaseUnlockTime
        if (unlockTime > 0) {
            _locked.end = unlockTime;
        }
        locked[_tokenId] = _locked;

        // Possibilities:
        // Both oldLocked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock)
        // value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_tokenId, oldLocked, _locked);

        if (_value > 0 && depositType != DepositType.MERGE) {
            IERC20(halo).transferFrom(msg.sender, address(this), _value);
        }

        emit Deposit(
            msg.sender,
            _tokenId,
            _value,
            _locked.end,
            depositType,
            block.timestamp
        );
        emit Supply(supplyBefore, supplyBefore + _value);
    }

    /**
     * @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
     * @param _value Amount to deposit
     * @param _lockDuration Number of seconds to lock tokens for
     *        (rounded down to nearest week)
     * @param _to Address to deposit
     * @return Token id
     */
    function _createLock(
        uint256 _value,
        uint256 _lockDuration,
        address _to
    ) private returns (uint256) {
        require(_value > 0, "value = 0");
        // unlock time is rounded down to weeks
        uint256 unlockTime = ((block.timestamp + _lockDuration) / WEEK) * WEEK;

        require(unlockTime > block.timestamp, "unlock time <= now");
        require(unlockTime <= block.timestamp + MAXTIME, "unlock time > max");

        ++tokenId;
        uint256 _tokenId = tokenId;
        _mint(_to, _tokenId);

        _depositFor(
            _tokenId,
            _value,
            unlockTime,
            LockedBalance(0, 0),
            DepositType.CREATE_LOCK
        );

        return _tokenId;
    }

    /**
     * @notice Deposit `_value` tokens for `msg.sender` and lock for `_lockDuration`
     * @param _value Amount to deposit
     * @param _lockDuration Number of seconds to lock tokens for
     *        (rounded down to nearest week)
     * @return Token id
     */
    function createLock(uint256 _value, uint256 _lockDuration)
        external
        lock
        returns (uint256)
    {
        return _createLock(_value, _lockDuration, msg.sender);
    }

    /**
     * @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
     * @param _value Amount to deposit
     * @param _lockDuration Number of seconds to lock tokens for
     *        (rounded down to nearest week)
     * @param _to Address to deposit
     * @return Token id
     */
    function createLockFor(
        uint256 _value,
        uint256 _lockDuration,
        address _to
    ) external lock returns (uint256) {
        return _createLock(_value, _lockDuration, _to);
    }

    /**
     * @notice Deposit `_value` tokens for `_tokenId` and add to the lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but
     *      cannot extend their lock time and deposit for a brand new user
     * @param _tokenId lock NFT
     * @param _value Amount to add to user's lock
     */
    function depositFor(uint256 _tokenId, uint256 _value) external lock {
        require(_value > 0, "value = 0");
        LockedBalance memory _locked = locked[_tokenId];

        require(_locked.amount > 0, "lock not found");
        require(_locked.end > block.timestamp, "lock expired");
        _depositFor(_tokenId, _value, 0, _locked, DepositType.DEPOSIT_FOR);
    }

    /**
     * @notice Merge locks
     * @param _from Token id to merge from
     * @param _to Token id to merge to
     */
    function merge(uint256 _from, uint256 _to) external notAttached(_from) {
        require(_from != _to, "from = to");
        require(_isApprovedOrOwner(msg.sender, _from), "not authorized");
        require(_isApprovedOrOwner(msg.sender, _to), "not authorized");

        LockedBalance memory locked0 = locked[_from];
        LockedBalance memory locked1 = locked[_to];
        uint256 amount0 = uint256(int256(locked0.amount));
        uint256 end = Math.max(locked0.end, locked1.end);

        delete locked[_from];

        _checkpoint(_from, locked0, LockedBalance(0, 0));
        _burn(_from);
        _depositFor(_to, amount0, end, locked1, DepositType.MERGE);
    }

    /**
     * @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increaseAmount(uint256 _tokenId, uint256 _value) external lock {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "not authorized");
        require(_value > 0, "value = 0");
        LockedBalance memory _locked = locked[_tokenId];

        require(_locked.amount > 0, "lock not found");
        require(_locked.end > block.timestamp, "lock expired");

        _depositFor(
            _tokenId,
            _value,
            0,
            _locked,
            DepositType.INCREASE_LOCK_AMOUNT
        );
    }

    /**
     * @notice Extend the unlock time for `_tokenId`
     * @param _lockDuration New number of seconds until tokens unlock
     */
    function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration)
        external
        lock
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "not authorized");

        LockedBalance memory _locked = locked[_tokenId];
        uint256 unlockTime = ((block.timestamp + _lockDuration) / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp, "lock expired");
        require(_locked.amount > 0, "lock amount = 0");
        require(unlockTime > _locked.end, "unlock time <= lock end");
        require(unlockTime <= block.timestamp + MAXTIME, "unlock time > max");

        _depositFor(
            _tokenId,
            0,
            unlockTime,
            _locked,
            DepositType.INCREASE_UNLOCK_TIME
        );
    }

    /// @notice Withdraw all tokens for `_tokenId`
    /// @dev Only possible if the lock has expired
    function withdraw(uint256 _tokenId) external lock notAttached(_tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "not authorized");

        LockedBalance memory _locked = locked[_tokenId];
        require(block.timestamp >= _locked.end, "lock not expired");
        uint256 value = uint256(int256(_locked.amount));

        delete locked[_tokenId];
        uint256 supplyBefore = supply;
        supply = supplyBefore - value;

        // oldLocked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(_tokenId, _locked, LockedBalance(0, 0));

        IERC20(halo).transfer(msg.sender, value);

        // Burn the NFT
        _burn(_tokenId);

        emit Withdraw(msg.sender, _tokenId, value, block.timestamp);
        emit Supply(supplyBefore, supplyBefore - value);
    }

    function findTimestampEpoch(uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return PointLib.findTimestampEpoch(pointHistory, _timestamp, epoch);
    }

    function findUserEpochFromTimestamp(
        uint256 _tokenId,
        uint256 _timestamp,
        uint256 _maxUserEpoch
    ) external view returns (uint256) {
        return
            PointLib.findTimestampEpoch(
                userPointHistory[_tokenId],
                _timestamp,
                _maxUserEpoch
            );
    }

    /**
     * @notice Get the current voting power for `_tokenId`
     * @dev Curve VotingEscrow.balanceOf
     * @param _tokenId NFT for lock
     * @param _t Epoch time to return voting power at
     * @return User voting power
     */
    function _balanceOfNFT(uint256 _tokenId, uint256 _t)
        private
        view
        returns (uint256)
    {
        uint256 _epoch = userPointEpoch[_tokenId];
        if (_epoch == 0) {
            return 0;
        }

        // latest point of user
        Point memory point = userPointHistory[_tokenId][_epoch];
        point.bias -= point.slope * int128(int256(_t - point.timestamp));

        if (point.bias <= 0) {
            return 0;
        }
        return uint256(int256(point.bias));
    }

    function balanceOfNFT(uint256 _tokenId) external view returns (uint256) {
        if (ownershipChange[_tokenId] == block.number) {
            return 0;
        }
        return _balanceOfNFT(_tokenId, block.timestamp);
    }

    /**
     * @notice Measure voting power of `_tokenId` at block height `_block`
     * @dev Curve VotingEscrow.balanceOfAt
     * @param _tokenId User's wallet NFT
     * @param _block Block to calculate the voting power at
     * @return Voting power
     */
    function balanceOfAtNFT(uint256 _tokenId, uint256 _block)
        external
        view
        returns (uint256)
    {
        require(_block <= block.number, "block > current");

        // get user point
        uint256 userEpoch = PointLib.findBlockEpoch(
            userPointHistory[_tokenId],
            _block,
            userPointEpoch[_tokenId]
        );
        Point memory userPoint = userPointHistory[_tokenId][userEpoch];

        // get point
        uint256 maxEpoch = epoch;
        uint256 _epoch = PointLib.findBlockEpoch(
            pointHistory,
            _block,
            maxEpoch
        );
        Point memory p0 = pointHistory[_epoch];

        if (_block < p0.blk) {
            return 0;
        }

        // get block and time delta
        uint256 dblock;
        uint256 dt;
        if (_epoch < maxEpoch) {
            Point memory p1 = pointHistory[_epoch + 1];
            dblock = p1.blk - p0.blk;
            dt = p1.timestamp - p0.timestamp;
        } else {
            dblock = block.number - p0.blk;
            dt = block.timestamp - p0.timestamp;
        }

        uint256 blockTime = p0.timestamp;
        if (dblock > 0) {
            // approximate block timestamp
            // dt / dblock = seconds per block
            blockTime += (dt * (_block - p0.blk)) / dblock;
        }

        userPoint.bias -=
            userPoint.slope *
            int128(int256(blockTime - userPoint.timestamp));

        if (userPoint.bias <= 0) {
            return 0;
        }
        return uint256(uint128(userPoint.bias));
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param _point The point (bias/slope) to start calculation from
     * @param _timestamp time to calculate the total voting power at
     * @return Total voting power at that time
     */
    function _supplyAt(Point memory _point, uint256 _timestamp)
        private
        view
        returns (uint256)
    {
        Point memory p = _point;
        // start of week of p.timestamp
        uint256 t = (p.timestamp / WEEK) * WEEK;

        // Iterates max 255 weeks from week of p
        for (uint256 i = 0; i < 255; ++i) {
            t += WEEK;

            int128 dslope;
            if (t > _timestamp) {
                t = _timestamp;
            } else {
                dslope = slopeChanges[t];
            }

            // t = next week of p.timestamp, t >= p.timestamp
            p.bias -= p.slope * int128(int256(t - p.timestamp));

            if (t == _timestamp) {
                break;
            }

            p.slope += dslope;
            p.timestamp = t;
        }

        if (p.bias <= 0) {
            return 0;
        }
        return uint256(uint128(p.bias));
    }

    /**
     * @notice Calculate total voting power
     * @param _timestamp time to calculate the total voting power at
     * @return Total voting power
     */
    function totalSupplyAt(uint256 _timestamp) public view returns (uint256) {
        return _supplyAt(pointHistory[epoch], _timestamp);
    }

    /**
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     */
    function totalSupply() external view returns (uint256) {
        return totalSupplyAt(block.timestamp);
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param _block Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAtBlock(uint256 _block)
        external
        view
        returns (uint256)
    {
        require(_block <= block.number, "block > current");

        uint256 maxEpoch = epoch;
        uint256 _epoch = PointLib.findBlockEpoch(
            pointHistory,
            _block,
            maxEpoch
        );
        Point memory p0 = pointHistory[_epoch];

        if (_block < p0.blk) {
            return 0;
        }

        // approximate block timestamp delta
        uint256 dt = 0;
        if (_epoch < maxEpoch) {
            Point memory p1 = pointHistory[_epoch + 1];
            if (p0.blk != p1.blk) {
                dt =
                    ((_block - p0.blk) * (p1.timestamp - p0.timestamp)) /
                    (p1.blk - p0.blk);
            }
        } else {
            if (p0.blk != block.number) {
                dt =
                    ((_block - p0.blk) * (block.timestamp - p0.timestamp)) /
                    (block.number - p0.blk);
            }
        }

        // Now dt contains info on how far are we beyond point
        return _supplyAt(p0, p0.timestamp + dt);
    }

    // ERC 721 //

    /**
     * @notice Returns whether the given spender can transfer a given token ID
     * @param _spender address of the spender to query
     * @param _tokenId uint ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID, is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address _spender, uint256 _tokenId)
        private
        view
        returns (bool)
    {
        address _owner = _ownerOf[_tokenId];
        return ((_owner == _spender) ||
            (_spender == getApproved[_tokenId]) ||
            isApprovedForAll[_owner][_spender]);
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    // VE.transferFrom -> ERC721.transferFrom
    // VE.safeTransferFrom -> ERC721.safeTransferFrom -> VE.transferFrom -> ERC721.transferFrom
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override notAttached(_tokenId) {
        super.transferFrom(_from, _to, _tokenId);
        // Set the block of ownership transfer (for Flash NFT protection)
        ownershipChange[_tokenId] = block.number;
    }

    // TODO: change SVG to HALO
    function _tokenURI(
        uint256 _tokenId,
        uint256 _balanceOf,
        uint256 _lockedEnd,
        uint256 _value
    ) private pure returns (string memory output) {
        output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        output = string(
            abi.encodePacked(
                output,
                "token ",
                String.toString(_tokenId),
                '</text><text x="10" y="40" class="base">'
            )
        );
        output = string(
            abi.encodePacked(
                output,
                "balanceOf ",
                String.toString(_balanceOf),
                '</text><text x="10" y="60" class="base">'
            )
        );
        output = string(
            abi.encodePacked(
                output,
                "locked_end ",
                String.toString(_lockedEnd),
                '</text><text x="10" y="80" class="base">'
            )
        );
        output = string(
            abi.encodePacked(
                output,
                "value ",
                String.toString(_value),
                "</text></svg>"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "lock #',
                        String.toString(_tokenId),
                        '", "description": "halo-amm locks, can be used to boost gauge yields, vote on token emission, and receive bribes", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
    }

    /**
     * @notice Returns current token URI metadata
     * @param _tokenId Token ID to fetch URI for.
     * @dev To preview NFT,
     * 1. Paste output to browser URL
     * 2. Copy "image" field into browser URL again
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_ownerOf[_tokenId] != address(0), "Token doesn't exist");
        LockedBalance memory _locked = locked[_tokenId];
        return
            _tokenURI(
                _tokenId,
                _balanceOfNFT(_tokenId, block.timestamp),
                _locked.end,
                uint256(int256(_locked.amount))
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Point} from "../libraries/PointLib.sol";

interface IVeV1 is IERC721Metadata {
    function halo() external view returns (address);

    function balanceOfNFT(uint256) external view returns (uint256);

    function isApprovedOrOwner(address, uint256) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function setVoted(uint256 tokenId, bool _voted) external;

    function attach(uint256 tokenId) external;

    function detach(uint256 tokenId) external;

    function epoch() external view returns (uint256);

    function userPointEpoch(uint256 tokenId) external view returns (uint256);

    function pointHistory(uint256 i) external view returns (Point memory);

    function userPointHistory(uint256 tokenId, uint256 i)
        external
        view
        returns (Point memory);

    function checkpoint() external;

    function depositFor(uint256 tokenId, uint256 value) external;

    function createLockFor(
        uint256,
        uint256,
        address
    ) external returns (uint256);

    function findTimestampEpoch(uint256 _timestamp)
        external
        view
        returns (uint256);

    function findUserEpochFromTimestamp(
        uint256 _tokenId,
        uint256 _timestamp,
        uint256 _maxUserEpoch
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

struct Point {
    int128 bias;
    int128 slope; // amount locked / max time
    uint256 timestamp;
    uint256 blk; // block number
}

library PointLib {
    /**
     * @notice Binary search to find epoch equal to or immediately before `_block`.
     *         WARNING: If `_block` < `pointHistory[0].blk`
     *         this function returns the index of first point history `0`.
     * @dev Algorithm copied from Curve's VotingEscrow
     * @param pointHistory Mapping from uint => Point
     * @param _block Block to find
     * @param max Max epoch. Don't search beyond this epoch
     * @return min Epoch that is equal to or immediately before `_block`
     */
    function findBlockEpoch(
        mapping(uint256 => Point) storage pointHistory,
        uint256 _block,
        uint256 max
    ) internal view returns (uint256 min) {
        while (min < max) {
            // Max 128 iterations will be enough for 128-bit numbers
            // mid = ceil((min + max) / 2)
            //     = mid index if min + max is odd
            //       mid-right index if min + max is even
            uint256 mid = max - (max - min) / 2; // avoiding overflow
            if (pointHistory[mid].blk <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
    }

    /**
     * @notice Binary search to find epoch equal to or immediately before `timestamp`.
     *         WARNING: If `timestamp` < `pointHistory[0].timestamp`
     *         this function returns the index of first point history `0`.
     * @dev Algorithm almost the same as `findBlockEpoch`
     * @param pointHistory Mapping from uint => Point
     * @param timestamp Timestamp to find
     * @param max Max epoch. Don't search beyond this epoch
     * @return min Epoch that is equal to or immediately before `timestamp`
     */
    function findTimestampEpoch(
        mapping(uint256 => Point) storage pointHistory,
        uint256 timestamp,
        uint256 max
    ) internal view returns (uint256 min) {
        while (min < max) {
            // Max 128 iterations will be enough for 128-bit numbers
            // mid = ceil((min + max) / 2)
            //     = mid index if min + max is odd
            //       mid-right index if min + max is even
            uint256 mid = max - (max - min) / 2; // avoiding overflow
            if (pointHistory[mid].timestamp <= timestamp) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
    }

    /**
     * @notice Calculates bias (used for VE total supply and user balance),
     * returns 0 if bias < 0
     * @param point Point
     * @param dt time delta in seconds
     */
    function calculateBias(Point memory point, uint256 dt)
        internal
        pure
        returns (uint256)
    {
        int128 bias = point.bias - point.slope * int128(int256(dt));
        if (bias > 0) {
            return uint256(int256(bias));
        }

        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library String {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            ++digits;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            --digits;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

abstract contract ReentrancyGuard {
    // simple re-entrancy check
    uint256 internal _unlocked = 1;

    modifier lock() {
        // solhint-disable-next-line
        require(_unlocked == 1, "reentrant");
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/IOwnable.sol";

contract Ownable is IOwnable {
    event NewOwner(address owner);

    address public owner;
    address public pendingOwner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != msg.sender, "new owner = current owner");
        pendingOwner = _newOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "not pending owner");
        owner = msg.sender;
        pendingOwner = address(0);
        emit NewOwner(msg.sender);
    }

    function deleteOwner() external onlyOwner {
        require(pendingOwner == address(0), "pending owner != 0 address");
        owner = address(0);
        emit NewOwner(address(0));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IOwnable {
    function owner() external view returns (address);

    function setOwner(address _newOwner) external;

    function acceptOwner() external;

    function deleteOwner() external;
}