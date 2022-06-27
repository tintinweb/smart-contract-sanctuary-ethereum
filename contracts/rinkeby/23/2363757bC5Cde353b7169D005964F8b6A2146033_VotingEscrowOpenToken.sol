// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.8;

// Modified from WarTech9/VEToken. Original idea and based on Curve Finance's veCRV
// https://github.com/WarTech9/VEToken/blob/master/contracts/core/veToken.sol
// https://resources.curve.fi/faq/vote-locking-boost
// https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
//
//@notice Votes have a weight depending on time, so that users are
//        committed to the future of (whatever they are voting for)
//@dev Vote weight decays linearly over time. Lock time cannot be
//     more than `MAXTIME` (4 years).

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime:
// w ^
// 1 +    /
//   |   /
//   |  /
//   | /
//   |/
// 0 +---+---> time
//       maxtime (4 years?)


import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Inheritance
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";



// # Interface for checking whether address belongs to a whitelisted
// # type of a smart wallet.
// # When new types are added - the whole contract is changed
// # The check() method is modifying to be able to use caching
// # for individual wallet addresses
interface SmartWalletChecker {
    function check(address addr) external returns (bool);
}

/// @title veOpenToken
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract VotingEscrowOpenToken is ReentrancyGuard, Pausable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;


    /* ========== STATE VARIABLES ========== */

    address public token; // MON
    uint256 public supply;//total num of locked open tokens
    mapping (uint256 => uint256) public weekSupply;//weekend total num of locked open tokens
    uint256 public maxWeekSupplyTime;

    uint256 public epoch;
    mapping (address => LockedBalance) public locked;
    Point[100000000000000000000000000000] public pointHistory; // epoch -> unsigned point
    mapping (address => Point[1000000000]) public userPointHistory;
    mapping (address => uint256) public userPointEpoch;
    mapping (uint256 => int256) public slopeChanges; // time -> signed slope change

    // Aragon's view methods for
    address public controller;

    bool public transfersEnabled;

    // veOPEN token related
    string public name;
    string public symbol;
    string public version;
    uint256 public decimals;

    // Checker for whitelisted (smart contract) wallets which are allowed to deposit
    // The goal is to prevent tokenizing the escrow
    address public futureSmartWalletChecker;
    address public smartWalletChecker;

    address public currentOwner;
    address public futureOwner;
    address public admin;  // Can and will be a smart contract

    uint256 public startTime = 0;

    int128 public constant DEPOSIT_FOR_TYPE = 0;
    int128 public constant CREATE_LOCK_TYPE = 1;
    int128 public constant INCREASE_LOCK_AMOUNT = 2;
    int128 public constant INCREASE_UNLOCK_TIME = 3;

    address public constant ZERO_ADDRESS = address(0);

    uint256 public constant WEEK = 600;//7 * 86400; // all future times are rounded by week
    uint256 public constant MAXTIME = 4 * 365 * 86400; // 4 years
    uint256 public constant MULTIPLIER = 10 ** 18;

    // We cannot really do block numbers per se b/c slope is per time, not per block
    // and per block could be fairly bad b/c Ethereum changes blocktimes.
    // What we can do is to extrapolate ***At functions
    struct Point {
        int256 bias;
        int256 slope; // dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int256 amount;
        uint256 end;
    }


    /* ========== MODIFIERS ========== */
    modifier  onlyByOwner {
        require(msg.sender == currentOwner, "You are not the owner");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == currentOwner || msg.sender == admin, "You are not the admin");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    // tokenAddr_: address, name_: String[64], symbol_: String[32], version_: String[32]
    /**
        * @notice Contract constructor
        * @param tokenAddr_ `ERC20OPEN` token address
        * @param name_ Token name
        * @param symbol_ Token symbol
        * @param version_ Contract version - required for Aragon compatibility
    */
    constructor (
        address tokenAddr_,
        string memory name_,
        string memory symbol_,
        string memory version_
    ) {
        currentOwner = msg.sender;
        admin = msg.sender;
        token = tokenAddr_;
        pointHistory[0].blk = _blockNumber();
        pointHistory[0].ts = _blockTimestamp();
        controller = msg.sender;
        transfersEnabled = true;

        uint256 _decimals = ERC20(tokenAddr_).decimals();
        assert(_decimals <= 255);
        decimals = _decimals;

        name = name_;
        symbol = symbol_;
        version = version_;

        startTime = block.timestamp/WEEK*WEEK;
    }

    /*=========== Pausable =========*/
    function pause() public onlyByOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyByOwner whenPaused {
        _unpause();
    }

    /* ========== VIEWS ========== */

    // Constant structs not allowed yet, so this will have to do
    function EMPTY_POINT_FACTORY() internal pure returns (Point memory){
        return Point({
        bias: 0,
        slope: 0,
        ts: 0,
        blk: 0
        });
    }

    // Constant structs not allowed yet, so this will have to do
    function EMPTY_LOCKED_BALANCE_FACTORY() internal pure returns (LockedBalance memory){
        return LockedBalance({
        amount: 0,
        end: 0
        });
    }

    /**
        * @notice Get the most recently recorded rate of voting power decrease for `addr`
        * @param addr_ Address of the user wallet
        * @return Value of the slope
    */
    function getLastUserSlope(address addr_) external view returns (int256) {
        uint256 uepoch = userPointEpoch[addr_];
        return userPointHistory[addr_][uepoch].slope;
    }

    /**
        * @notice Get the timestamp for checkpoint `epoch_` for `addr_`
        * @param addr_ User wallet address
        * @param epoch_ User epoch number
        * @return Epoch time of the checkpoint
    */
    function userPointHistoryTS(address addr_, uint256 epoch_) external view returns (uint256) {
        return userPointHistory[addr_][epoch_].ts;
    }

    /**
        * @notice Get timestamp when `addr_`'s lock finishes
        * @param addr_ User wallet
        * @return Epoch time of the lock end
    */
    function lockedEnd(address addr_) external view returns (uint256) {
        return locked[addr_].end;
    }

    /**
        * @notice Measure voting power of `addr_` at the specified timestamp
        * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
        * @param addr_ User wallet address
        * @param t_ Epoch time to return voting power at
        * @return User voting power
    */
    function balanceOf(address addr_, uint256 t_) public view returns (uint256) {
        // Binary search
        uint256 _min = 0;
        uint256 _max = userPointEpoch[addr_];

        // Will be always enough for 128-bit numbers
        for(uint i = 0; i < 128; i++){
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (userPointHistory[addr_][_mid].ts <= t_) {
                _min = _mid;
            }
            else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = userPointHistory[addr_][_min];

        upoint.bias -= upoint.slope * int256(t_ - (upoint.ts));
        if (upoint.bias >= 0) {
            return uint256(upoint.bias);
        }
        else {
            return 0;
        }

    }

    /**
        * @notice Get the current voting power for `msg.sender` at the current timestamp
        * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
        * @param addr_ User wallet address
        * @return User voting power
    */
    function balanceOf(address addr_) public view returns (uint256) {
        return balanceOf(addr_, _blockTimestamp());
    }

    /**
        * @notice Measure voting power of `addr_` at block height `block_`
        * @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
        * @param addr_ User's wallet address
        * @param block_ Block to calculate the voting power at
        * @return Voting power
    */
    function balanceOfAt(address addr_, uint256 block_) external view returns (uint256) {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        require(block_ <= _blockNumber(), "VE: Invalid block");

        // Binary search
        uint256 _min = 0;
        uint256 _max = userPointEpoch[addr_];

        // Will be always enough for 128-bit numbers
        for(uint i = 0; i < 128; i++){
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (userPointHistory[addr_][_mid].blk <= block_) {
                _min = _mid;
            }
            else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = userPointHistory[addr_][_min];

        uint256 maxEpoch = epoch;
        uint256 _epoch = findBlockEpoch(block_, maxEpoch);
        Point memory point0 = pointHistory[_epoch];
        uint256 dBlock = 0;
        uint256 dT = 0;

        if (_epoch < maxEpoch) {
            Point memory point1 = pointHistory[_epoch + 1];
            dBlock = point1.blk - point0.blk;
            dT = point1.ts - point0.ts;
        }
        else {
            dBlock = _blockNumber() - point0.blk;
            dT = _blockTimestamp() - point0.ts;
        }

        uint256 blockTime = point0.ts;
        if (dBlock != 0) {
            blockTime += dT * (block_ - point0.blk) / dBlock;
        }

        upoint.bias -= upoint.slope * int256((blockTime) - (upoint.ts));
        if (upoint.bias >= 0) {
            return uint256(upoint.bias);
        }
        else {
            return 0;
        }
    }

    /**
        * @notice Calculate total voting power at the specified timestamp
        * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
        * @return Total voting power
    */
    function totalSupply(uint256 t_) public view returns (uint256) {

        // Binary search
        uint256 _min = 0;
        uint256 _max = epoch;

        // Will be always enough for 128-bit numbers
        for(uint i = 0; i < 128; i++){
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (pointHistory[_mid].ts <= t_) {
                _min = _mid;
            }
            else {
                _max = _mid - 1;
            }
        }

        Point memory lastPoint = pointHistory[_min];
        return supplyAt(lastPoint, t_);
    }

    /**
        * @notice Calculate total voting power at the current timestamp
        * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
        * @return Total voting power
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply(_blockTimestamp());
    }

    /**
        * @notice Calculate total voting power at some point in the past
        * @param block_ Block to calculate the total voting power at
        * @return Total voting power at `block_`
    */
    function totalSupplyAt(uint256 block_) external view returns (uint256) {
        require(block_ <= _blockNumber(), "VE: Invalid block");
        uint256 _epoch = epoch;
        uint256 targetEpoch = findBlockEpoch(block_, _epoch);

        Point memory point = pointHistory[targetEpoch];
        uint256 dt = 0;

        if (targetEpoch < _epoch) {
            Point memory pointNext = pointHistory[targetEpoch + 1];
            if (point.blk != pointNext.blk) {
                dt = ((block_ - point.blk) * (pointNext.ts - point.ts)) / (pointNext.blk - point.blk);
            }
        }
        else {
            if (point.blk != _blockNumber()) {
                dt = ((block_ - point.blk) * (_blockTimestamp() - point.ts)) / (_blockNumber() - point.blk);
            }
        }

        // Now dt contains info on how far are we beyond point
        return supplyAt(point, point.ts + dt);
    }


    /**
       * @notice Fill week supply for the lock token week-over-week for
            missed checkins and return the weeksupply at target timestamp
    */
    function changeWeekSupply() public {
        uint256 t = _blockTimestamp() / WEEK * WEEK;
        if(t >= maxWeekSupplyTime){
            uint256 tt = maxWeekSupplyTime;
            for(uint i = 0; i < 500; i++){
                if(tt > block.timestamp){
                    break;
                }
                tt += WEEK;
                if(tt > block.timestamp){
                    weekSupply[tt] = supply;
                }
                else{
                    weekSupply[tt] = weekSupply[maxWeekSupplyTime];
                }
                maxWeekSupplyTime = tt;
            }
        }
    }

    /**
       * @notice Get the weeksupply at target timestamp
        * @param t_ target timestamp
        * @return the weeksupply at target timestamp
    */
    function getWeekSupply(uint256 t_) external view returns(uint256){
        uint256 t = t_ / WEEK * WEEK;

        if(t >= maxWeekSupplyTime){
            return weekSupply[maxWeekSupplyTime];
        }
        else {
            return weekSupply[t];
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
        * @notice Check if the call is from a whitelisted smart contract, revert if not
        * @param addr_ Address to be checked
    */
    function _assertNotContract(address addr_) internal {
        if (addr_ != tx.origin) {
            address checker = smartWalletChecker;
            if (checker != ZERO_ADDRESS){
                if (SmartWalletChecker(checker).check(addr_)){
                    return;
                }
            }
            revert("Depositor not allowed");
        }
    }

    /**
        * @notice Record global and per-user data to checkpoint
        * @param addr_ User's wallet address. No user checkpoint if 0x0
        * @param oldLocked_ Previous locked amount / end lock time for the user
        * @param newLocked_ New locked amount / end lock time for the user
    */
    function _checkpoint(address addr_, LockedBalance memory oldLocked_, LockedBalance memory newLocked_) internal {
        Point memory uOld = EMPTY_POINT_FACTORY();
        Point memory uNew = EMPTY_POINT_FACTORY();
        int256 oldSlope = 0;
        int256 newSlope = 0;
        uint256 _epoch = epoch;

        if (addr_ != ZERO_ADDRESS){
            // Calculate slopes and biases
            // Kept at zero when they have to
            if ((oldLocked_.end > _blockTimestamp()) && (oldLocked_.amount > 0)){
                uOld.slope = (oldLocked_.amount / int256(MAXTIME));
                uOld.bias = uOld.slope * int256((oldLocked_.end) - (_blockTimestamp()));
            }

            if ((newLocked_.end > _blockTimestamp()) && (newLocked_.amount > 0)){
                uNew.slope = (newLocked_.amount / int256(MAXTIME));
                uNew.bias = uNew.slope * int256((newLocked_.end) - (_blockTimestamp()));
            }

            // Read values of scheduled changes in the slope
            // oldLocked_.end can be in the past and in the future
            // newLocked_.end can ONLY by in the FUTURE unless everything expired: than zeros
            oldSlope = slopeChanges[oldLocked_.end];
            if (newLocked_.end != 0) {
                if (newLocked_.end == oldLocked_.end) {
                    newSlope = oldSlope;
                }
                else {
                    newSlope = slopeChanges[newLocked_.end];
                }
            }

        }

        Point memory lastPoint = Point({
        bias: 0,
        slope: 0,
        ts: _blockTimestamp(),
        blk: _blockNumber()
        });
        if (_epoch > 0) {
            lastPoint = pointHistory[_epoch];
        }
        uint256 lastCheckpoint = lastPoint.ts;

        // initialLastPoint is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initialLastPoint = lastPoint;
        int256 blockSlope = 0; // dblock/dt
        if (_blockTimestamp() > lastPoint.ts) {
            blockSlope = int256(MULTIPLIER) * int256((_blockNumber() - lastPoint.blk) / (_blockTimestamp() - lastPoint.ts));
        }

        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        uint256 tI = (lastCheckpoint / WEEK) * WEEK;
        for(uint i = 0; i < 255; i++){
            // Hopefully it won't happen that this won't get used in 4 years!
            // If it does, users will be able to withdraw but vote weight will be broken
            tI += WEEK;
            int256 dSlope = 0;
            if (tI > _blockTimestamp()) {
                tI = _blockTimestamp();
            }
            else {
                dSlope = slopeChanges[tI];
            }
            lastPoint.bias -= lastPoint.slope * int256((tI) - (lastCheckpoint));
            lastPoint.slope += dSlope;
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0; // This can happen
            }
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0; // This cannot happen - just in case
            }
            lastCheckpoint = tI;
            lastPoint.ts = tI;
            lastPoint.blk = uint256(int256(initialLastPoint.blk) + blockSlope * int256((tI - initialLastPoint.ts) / MULTIPLIER));
            _epoch += 1;
            if (tI == _blockTimestamp()){
                lastPoint.blk = _blockNumber();
                break;
            }
            else {
                pointHistory[_epoch] = lastPoint;
            }
        }

        epoch = _epoch;
        // Now pointHistory is filled until t=now

        if (addr_ != ZERO_ADDRESS) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
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

        if (addr_ != ZERO_ADDRESS) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [newLocked_.end]
            // and add old_user_slope to [oldLocked_.end]
            if (oldLocked_.end > _blockTimestamp()) {
                // oldSlope was <something> - uOld.slope, so we cancel that
                oldSlope += uOld.slope;
                if (newLocked_.end == oldLocked_.end) {
                    oldSlope -= uNew.slope;  // It was a new deposit, not extension
                }
                slopeChanges[oldLocked_.end] = oldSlope;
            }

            if (newLocked_.end > _blockTimestamp()) {
                if (newLocked_.end > oldLocked_.end) {
                    newSlope -= uNew.slope;  // old slope disappeared at this point
                    slopeChanges[newLocked_.end] = newSlope;
                }
                // else: we recorded it already in oldSlope
            }

            // Now handle user history
            // Second function needed for 'stack too deep' issues
            _checkpointPartTwo(addr_, uNew.bias, uNew.slope);
        }

    }
    /**
        * @notice Needed for 'stack too deep' issues in _checkpoint()
        * @param addr_ User's wallet address. No user checkpoint if 0x0
        * @param bias_ from unew
        * @param slope_ from unew
    */
    function _checkpointPartTwo(address addr_, int256 bias_, int256 slope_) internal {
        uint256 userEpoch = userPointEpoch[addr_] + 1;

        userPointEpoch[addr_] = userEpoch;
        userPointHistory[addr_][userEpoch] = Point({
        bias: bias_,
        slope: slope_,
        ts: _blockTimestamp(),
        blk: _blockNumber()
        });
    }

    /**
        * @notice Deposit and lock tokens for a user
        * @param addr_ User's wallet address
        * @param value_ Amount to deposit
        * @param unlockTime_ New time when to unlock the tokens, or 0 if unchanged
        * @param lockedBalance_ Previous locked amount / timestamp
    */
    function _depositFor(address addr_, uint256 value_, uint256 unlockTime_, LockedBalance memory lockedBalance_, int128 type_) internal  {
        
        uint256 supplyBefore = supply;

        supply = supplyBefore + value_;

        changeWeekSupply();

        LockedBalance memory oldLocked = lockedBalance_;

        LockedBalance memory newLocked = LockedBalance({
            amount: oldLocked.amount + int256(value_),
            end: oldLocked.end
        });
        // Adding to existing lock, or if a lock is expired - creating a new one
        //newLocked.amount += (value_);
        if (unlockTime_ != 0) {
            newLocked.end = unlockTime_;
        }
        locked[addr_] = newLocked;

        // Possibilities:
        // Both oldLocked.end could be current or expired (>/< _blockTimestamp())
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // newLocked.end > _blockTimestamp() (always)
        _checkpoint(addr_, oldLocked, newLocked);

        if (value_ != 0) {
            assert(ERC20(token).transferFrom(addr_, address(this), value_));
        }

        emit Deposit(addr_, value_, newLocked.end, type_, _blockTimestamp());
        emit Supply(supplyBefore, supplyBefore + value_);
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.
    /**
        * @notice Binary search to estimate timestamp for block number
        * @param block_ Block to find
        * @param maxEpoch_ Don't go beyond this epoch
        * @return Approximate timestamp for block
    */
    function findBlockEpoch(uint256 block_, uint256 maxEpoch_) internal view returns (uint256) {
        // Binary search
        uint256 _min = 0;
        uint256 _max = maxEpoch_;

        // Will be always enough for 128-bit numbers
        for (uint i = 0; i < 128; i++){
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (pointHistory[_mid].blk <= block_) {
                _min = _mid;
            }
            else {
                _max = _mid - 1;
            }
        }

        return _min;
    }

    /**
        * @notice Calculate total voting power at some point in the past
        * @param point_ The point (bias/slope) to start search from
        * @param t_ Time to calculate the total voting power at
        * @return Total voting power at that time
    */
    function supplyAt(Point memory point_, uint256 t_) internal view returns (uint256) {
        Point memory lastPoint = point_;
        uint256 tI = (lastPoint.ts / WEEK) * WEEK;

        for(uint i = 0; i < 255; i++){
            tI += WEEK;
            int256 dSlope = 0;
            if (tI > t_) {
                tI = t_;
            }
            else {
                dSlope = slopeChanges[tI];
            }
            lastPoint.bias -= lastPoint.slope * int256((tI) - (lastPoint.ts));
            if (tI == t_) {
                break;
            }
            lastPoint.slope += dSlope;
            lastPoint.ts = tI;
        }

        if (lastPoint.bias < 0) {
            lastPoint.bias = 0;
        }
        return uint256(lastPoint.bias);
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
        * @notice Record global data to checkpoint
    */
    function checkpoint(address) external {
        _checkpoint(ZERO_ADDRESS, EMPTY_LOCKED_BALANCE_FACTORY(), EMPTY_LOCKED_BALANCE_FACTORY());
    }

    /**
        * @notice Deposit and lock tokens for a user
        * @dev Anyone (even a smart contract) can deposit for someone else, but
        cannot extend their locktime and deposit for a brand new user
        * @param addr_ User's wallet address
        * @param value_ Amount to add to user's lock
    */
    function depositFor(address addr_, uint256 value_) external nonReentrant {
        LockedBalance memory _locked = locked[addr_];
        require (value_ > 0, "need non-zero value");
        require (_locked.amount > 0, "No existing lock found");
        require (_locked.end > _blockTimestamp(), "Cannot add to expired lock");
        _depositFor(addr_, value_, 0, locked[addr_], DEPOSIT_FOR_TYPE);
    }

    /**
        * @notice Deposit `value_` tokens for `msg.sender` and lock until `unlockTime_`
        * @param value_ Amount to deposit
        * @param unlockTime_ Epoch time when tokens unlock, rounded down to whole weeks
    */
    function createLock(uint256 value_, uint256 unlockTime_) external nonReentrant {
        _assertNotContract(msg.sender);
        uint256 blockTimestamp = _blockTimestamp();
        uint256 unlockTime = (unlockTime_ / WEEK) * WEEK ; // Locktime is rounded down to weeks
        LockedBalance memory _locked = locked[msg.sender];

        require (value_ > 0, "need non-zero value");
        require (_locked.amount == 0, "Withdraw old tokens first");
        require (unlockTime > blockTimestamp, "Unlock time must be future");
        require (unlockTime <= blockTimestamp + MAXTIME, "Voting lock can be 4 years max");
        _depositFor(msg.sender, value_, unlockTime, _locked, CREATE_LOCK_TYPE);
    }

    /**
        * @notice Deposit `value_` additional tokens for `msg.sender`
        without modifying the unlock time
        * @param value_ Amount of tokens to deposit and add to the lock
    */
    function increaseAmount(uint256 value_) external nonReentrant {
        _assertNotContract(msg.sender);
        LockedBalance memory userLocked = locked[msg.sender];

        require(value_ > 0, "need non-zero value");
        require(userLocked.amount > 0, "No existing lock found");
        require(userLocked.end > _blockTimestamp(), "Cannot add to expired lock.");

        _depositFor(msg.sender, value_, 0, userLocked, INCREASE_LOCK_AMOUNT);
    }

    /**
        * @notice Extend the unlock time for `msg.sender` to `unlockTime_`
        * @param unlockTime_ New epoch time for unlocking
    */
    function increaseUnlockTime(uint256 unlockTime_) external nonReentrant {
        _assertNotContract(msg.sender);
        LockedBalance memory userLocked = locked[msg.sender];
        uint256 unlockTime = (unlockTime_ / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(userLocked.end > _blockTimestamp(), "Lock expired");
        require(userLocked.amount > 0, "Nothing is locked");
        require(unlockTime > userLocked.end, "Can only increase lock duration");
        require(unlockTime <= _blockTimestamp() + MAXTIME, "Voting lock can be 4 years max");

        _depositFor(msg.sender, 0, unlockTime, userLocked, INCREASE_UNLOCK_TIME);
    }

    /**
        * @notice Withdraw all tokens for `msg.sender`ime`
        * @dev Only possible if the lock has expired
    */
    function withdraw() external nonReentrant {
        LockedBalance memory oldLocked = locked[msg.sender];
        uint256 blockTimestamp = _blockTimestamp();
        require(blockTimestamp >= oldLocked.end, "The lock didn't expire");
        uint256 value = uint256(oldLocked.amount);

        LockedBalance memory newLocked = LockedBalance({
            amount: 0,
            end: 0
        });
        locked[msg.sender] = newLocked;
        uint256 supplyBefore = supply;
        supply = supplyBefore - value;

        changeWeekSupply();

        // oldLocked can have either expired <= timestamp or zero end
        // newLocked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, oldLocked, newLocked);

        require(ERC20(token).transfer(msg.sender, value), "VEToken: Transfer failed");

        emit Withdraw(msg.sender, value, blockTimestamp);
        emit Supply(supplyBefore, supplyBefore - value);
    }



    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
        * @notice Transfer ownership of VotingEscrow contract to `addr`
        * @param addr_ Address to have ownership transferred to
    */
    function commitTransferOwnership(address addr_) external onlyByOwner {
        futureOwner = addr_;
        emit CommitOwnership(addr_);
    }

    /**
        * @notice Apply ownership transfer
    */
    function applyTransferOwnership() external onlyByOwner {
        address _owner = futureOwner;
        assert (_owner != ZERO_ADDRESS);  // dev: admin not set
        currentOwner = _owner;
        emit ApplyOwnership(_owner);
    }

    /**
        * @notice Set an external contract to check for approved smart contract wallets
        * @param addr_ Address of Smart contract checker
    */
    function commitSmartWalletChecker(address addr_) external onlyByOwner {
        futureSmartWalletChecker = addr_;
    }

    /**
        * @notice Apply setting external contract to check approved smart contract wallets
    */
    function applySmartWalletChecker() external onlyByOwner {
        smartWalletChecker = futureSmartWalletChecker;
    }

    /**
        * @notice Admin transfer
    */
    function transferAdmin(address addr_) external onlyByOwner {
        admin = addr_;
    }


    /**
        * @notice Dummy method for compatibility with Aragon
        * @dev Dummy method required for Aragon compatibility
    */
    function changeController(address newController_) external {
        require(msg.sender == controller, "VEToken: not controller");
        controller = newController_;
    }

    function _blockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function _blockNumber() public view returns (uint256) {
        return block.number;
    }

    /* ========== EVENTS ========== */

    event CommitOwnership(address admin);
    event ApplyOwnership(address admin);
    event Deposit(address indexed provider, uint256 value, uint256 indexed locktime, int128 type_, uint256 ts);
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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