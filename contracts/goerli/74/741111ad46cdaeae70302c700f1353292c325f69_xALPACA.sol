// SPDX-License-Identifier: MIT
/**
Ported to Solidity from: https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
**/

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/IGrassHouse.sol";
import "./interfaces/IBEP20.sol";

import "./SafeToken.sol";

/// @title xALPACA - The goverance token of Alpaca Finance
// solhint-disable not-rely-on-time
// solhint-disable-next-line contract-name-camelcase
contract xALPACA is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using SafeToken for address;

  // --- Events ---
  event LogDeposit(
    address indexed locker,
    uint256 value,
    uint256 indexed lockTime,
    uint256 lockType,
    uint256 timestamp
  );
  event LogWithdraw(address indexed locker, uint256 value, uint256 timestamp);
  event LogSetBreaker(uint256 previousBreaker, uint256 breaker);
  event LogSupply(uint256 previousSupply, uint256 supply);
  event LogSetWhitelistedCaller(address indexed caller, address indexed addr, bool ok);

  struct Point {
    int128 bias; // Voting weight
    int128 slope; // Multiplier factor to get voting weight at a given time
    uint256 timestamp;
    uint256 blockNumber;
  }

  struct LockedBalance {
    int128 amount;
    uint256 end;
  }

  // --- Constants ---
  uint256 public constant ACTION_DEPOSIT_FOR = 0;
  uint256 public constant ACTION_CREATE_LOCK = 1;
  uint256 public constant ACTION_INCREASE_LOCK_AMOUNT = 2;
  uint256 public constant ACTION_INCREASE_UNLOCK_TIME = 3;

  uint256 public constant WEEK = 7 days;
  // MAX_LOCK 53 weeks - 1 seconds
  uint256 public constant MAX_LOCK = (53 * WEEK) - 1;
  uint256 public constant MULTIPLIER = 10 ** 18;

  // Token to be locked (ALPACA)
  address public token;
  // Total supply of ALPACA that get locked
  uint256 public supply;

  // Mapping (user => LockedBalance) to keep locking information for each user
  mapping(address => LockedBalance) public locks;

  // A global point of time.
  uint256 public epoch;
  // An array of points (global).
  Point[] public pointHistory;
  // Mapping (user => Point) to keep track of user point of a given epoch (index of Point is epoch)
  mapping(address => Point[]) public userPointHistory;
  // Mapping (user => epoch) to keep track which epoch user at
  mapping(address => uint256) public userPointEpoch;
  // Mapping (round off timestamp to week => slopeDelta) to keep track slope changes over epoch
  mapping(uint256 => int128) public slopeChanges;

  // Circuit breaker
  uint256 public breaker;

  // --- BEP20 compatible variables ---
  string public name;
  string public symbol;
  uint8 public decimals;

  address public grasshouse;

  // --- whitelist address  ---
  mapping(address => bool) public whitelistedCallers;
  mapping(address => bool) public whitelistedRedistributors;

  modifier onlyRedistributors() {
    require(whitelistedRedistributors[msg.sender], "not redistributors");
    _;
  }

  modifier onlyEOAorWhitelisted() {
    if (!whitelistedCallers[msg.sender]) {
      require(msg.sender == tx.origin, "not eoa");
    }
    _;
  }

  /// @notice Initialize xALPACA
  /// @param _token The address of ALPACA token
  function initialize(address _token) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    token = _token;

    pointHistory.push(Point({ bias: 0, slope: 0, timestamp: block.timestamp, blockNumber: block.number }));

    uint8 _decimals = IBEP20(_token).decimals();
    decimals = _decimals;

    name = "xALPACA";
    symbol = "xALPACA";
  }

  /// @notice Return the balance of xALPACA at a given "_blockNumber"
  /// @param _user The address to get a balance of xALPACA
  /// @param _blockNumber The speicific block number that you want to check the balance of xALPACA
  function balanceOfAt(address _user, uint256 _blockNumber) external view returns (uint256) {
    require(_blockNumber <= block.number, "bad _blockNumber");

    // Get most recent user Point to block
    uint256 _userEpoch = _findUserBlockEpoch(_user, _blockNumber);
    if (_userEpoch == 0) {
      return 0;
    }
    Point memory _userPoint = userPointHistory[_user][_userEpoch];

    // Get most recent global point to block
    uint256 _maxEpoch = epoch;
    uint256 _epoch = _findBlockEpoch(_blockNumber, _maxEpoch);
    Point memory _point0 = pointHistory[_epoch];

    uint256 _blockDelta = 0;
    uint256 _timeDelta = 0;
    if (_epoch < _maxEpoch) {
      Point memory _point1 = pointHistory[_epoch + 1];
      _blockDelta = _point1.blockNumber - _point0.blockNumber;
      _timeDelta = _point1.timestamp - _point0.timestamp;
    } else {
      _blockDelta = block.number - _point0.blockNumber;
      _timeDelta = block.timestamp - _point0.timestamp;
    }
    uint256 _blockTime = _point0.timestamp;
    if (_blockDelta != 0) {
      _blockTime += (_timeDelta * (_blockNumber - _point0.blockNumber)) / _blockDelta;
    }

    _userPoint.bias -= (_userPoint.slope * SafeCastUpgradeable.toInt128(int256(_blockTime - _userPoint.timestamp)));

    if (_userPoint.bias < 0) {
      return 0;
    }

    return SafeCastUpgradeable.toUint256(_userPoint.bias);
  }

  /// @notice Return the voting weight of a givne user
  /// @param _user The address of a user
  function balanceOf(address _user) external view returns (uint256) {
    uint256 _epoch = userPointEpoch[_user];
    if (_epoch == 0) {
      return 0;
    }
    Point memory _lastPoint = userPointHistory[_user][_epoch];
    _lastPoint.bias =
      _lastPoint.bias -
      (_lastPoint.slope * SafeCastUpgradeable.toInt128(int256(block.timestamp - _lastPoint.timestamp)));
    if (_lastPoint.bias < 0) {
      _lastPoint.bias = 0;
    }
    return SafeCastUpgradeable.toUint256(_lastPoint.bias);
  }

  /// @notice Record global and per-user slope to checkpoint
  /// @param _address User's wallet address. Only global if 0x0
  /// @param _prevLocked User's previous locked balance and end lock time
  /// @param _newLocked User's new locked balance and end lock time
  function _checkpoint(address _address, LockedBalance memory _prevLocked, LockedBalance memory _newLocked) internal {
    Point memory _userPrevPoint = Point({ slope: 0, bias: 0, timestamp: 0, blockNumber: 0 });
    Point memory _userNewPoint = Point({ slope: 0, bias: 0, timestamp: 0, blockNumber: 0 });

    int128 _prevSlopeDelta = 0;
    int128 _newSlopeDelta = 0;
    uint256 _epoch = epoch;

    // if not 0x0, then update user's point
    if (_address != address(0)) {
      // Calculate slopes and biases according to linear decay graph
      // slope = lockedAmount / MAX_LOCK => Get the slope of a linear decay graph
      // bias = slope * (lockedEnd - currentTimestamp) => Get the voting weight at a given time
      // Kept at zero when they have to
      if (_prevLocked.end > block.timestamp && _prevLocked.amount > 0) {
        // Calculate slope and bias for the prev point
        _userPrevPoint.slope = _prevLocked.amount / SafeCastUpgradeable.toInt128(int256(MAX_LOCK));
        _userPrevPoint.bias =
          _userPrevPoint.slope *
          SafeCastUpgradeable.toInt128(int256(_prevLocked.end - block.timestamp));
      }
      if (_newLocked.end > block.timestamp && _newLocked.amount > 0) {
        // Calculate slope and bias for the new point
        _userNewPoint.slope = _newLocked.amount / SafeCastUpgradeable.toInt128(int256(MAX_LOCK));
        _userNewPoint.bias =
          _userNewPoint.slope *
          SafeCastUpgradeable.toInt128(int256(_newLocked.end - block.timestamp));
      }

      // Handle user history here
      // Do it here to prevent stack overflow
      uint256 _userEpoch = userPointEpoch[_address];
      // If user never ever has any point history, push it here for him.
      if (_userEpoch == 0) {
        userPointHistory[_address].push(_userPrevPoint);
      }

      // Shift user's epoch by 1 as we are writing a new point for a user
      userPointEpoch[_address] = _userEpoch + 1;

      // Update timestamp & block number then push new point to user's history
      _userNewPoint.timestamp = block.timestamp;
      _userNewPoint.blockNumber = block.number;
      userPointHistory[_address].push(_userNewPoint);

      // Read values of scheduled changes in the slope
      // _prevLocked.end can be in the past and in the future
      // _newLocked.end can ONLY be in the FUTURE unless everything expired (anything more than zeros)
      _prevSlopeDelta = slopeChanges[_prevLocked.end];
      if (_newLocked.end != 0) {
        // Handle when _newLocked.end != 0
        if (_newLocked.end == _prevLocked.end) {
          // This will happen when user adjust lock but end remains the same
          // Possibly when user deposited more ALPACA to his locker
          _newSlopeDelta = _prevSlopeDelta;
        } else {
          // This will happen when user increase lock
          _newSlopeDelta = slopeChanges[_newLocked.end];
        }
      }
    }

    // Handle global states here
    Point memory _lastPoint = Point({ bias: 0, slope: 0, timestamp: block.timestamp, blockNumber: block.number });
    if (_epoch > 0) {
      // If _epoch > 0, then there is some history written
      // Hence, _lastPoint should be pointHistory[_epoch]
      // else _lastPoint should an empty point
      _lastPoint = pointHistory[_epoch];
    }
    // _lastCheckpoint => timestamp of the latest point
    // if no history, _lastCheckpoint should be block.timestamp
    // else _lastCheckpoint should be the timestamp of latest pointHistory
    uint256 _lastCheckpoint = _lastPoint.timestamp;

    // initialLastPoint is used for extrapolation to calculate block number
    // (approximately, for xxxAt methods) and save them
    // as we cannot figure that out exactly from inside contract
    Point memory _initialLastPoint = Point({
      bias: 0,
      slope: 0,
      timestamp: _lastPoint.timestamp,
      blockNumber: _lastPoint.blockNumber
    });

    // If last point is already recorded in this block, _blockSlope=0
    // That is ok because we know the block in such case
    uint256 _blockSlope = 0;
    if (block.timestamp > _lastPoint.timestamp) {
      // Recalculate _blockSlope if _lastPoint.timestamp < block.timestamp
      // Possiblity when epoch = 0 or _blockSlope hasn't get updated in this block
      _blockSlope = (MULTIPLIER * (block.number - _lastPoint.blockNumber)) / (block.timestamp - _lastPoint.timestamp);
    }

    // Go over weeks to fill history and calculate what the current point is
    uint256 _weekCursor = _timestampToFloorWeek(_lastCheckpoint);
    for (uint256 i = 0; i < 255; i++) {
      // This logic will works for 5 years, if more than that vote power will be broken 😟
      // Bump _weekCursor a week
      _weekCursor = _weekCursor + WEEK;
      int128 _slopeDelta = 0;
      if (_weekCursor > block.timestamp) {
        // If the given _weekCursor go beyond block.timestamp,
        // We take block.timestamp as the cursor
        _weekCursor = block.timestamp;
      } else {
        // If the given _weekCursor is behind block.timestamp
        // We take _slopeDelta from the recorded slopeChanges
        // We can use _weekCursor directly because key of slopeChanges is timestamp round off to week
        _slopeDelta = slopeChanges[_weekCursor];
      }
      // Calculate _biasDelta = _lastPoint.slope * (_weekCursor - _lastCheckpoint)
      int128 _biasDelta = _lastPoint.slope * SafeCastUpgradeable.toInt128(int256((_weekCursor - _lastCheckpoint)));
      _lastPoint.bias = _lastPoint.bias - _biasDelta;
      _lastPoint.slope = _lastPoint.slope + _slopeDelta;
      if (_lastPoint.bias < 0) {
        // This can happen
        _lastPoint.bias = 0;
      }
      if (_lastPoint.slope < 0) {
        // This cannot happen, just make sure
        _lastPoint.slope = 0;
      }
      // Update _lastPoint to the new one
      _lastCheckpoint = _weekCursor;
      _lastPoint.timestamp = _weekCursor;
      // As we cannot figure that out block timestamp -> block number exactly
      // when query states from xxxAt methods, we need to calculate block number
      // based on _initalLastPoint
      _lastPoint.blockNumber =
        _initialLastPoint.blockNumber +
        ((_blockSlope * ((_weekCursor - _initialLastPoint.timestamp))) / MULTIPLIER);
      _epoch = _epoch + 1;
      if (_weekCursor == block.timestamp) {
        // Hard to be happened, but better handling this case too
        _lastPoint.blockNumber = block.number;
        break;
      } else {
        pointHistory.push(_lastPoint);
      }
    }
    // Now, each week pointHistory has been filled until current timestamp (round off by week)
    // Update epoch to be the latest state
    epoch = _epoch;

    if (_address != address(0)) {
      // If the last point was in the block, the slope change should have been applied already
      // But in such case slope shall be 0
      _lastPoint.slope = _lastPoint.slope + _userNewPoint.slope - _userPrevPoint.slope;
      _lastPoint.bias = _lastPoint.bias + _userNewPoint.bias - _userPrevPoint.bias;
      if (_lastPoint.slope < 0) {
        _lastPoint.slope = 0;
      }
      if (_lastPoint.bias < 0) {
        _lastPoint.bias = 0;
      }
    }

    // Record the new point to pointHistory
    // This would be the latest point for global epoch
    pointHistory.push(_lastPoint);

    if (_address != address(0)) {
      // Schedule the slope changes (slope is going downward)
      // We substract _newSlopeDelta from `_newLocked.end`
      // and add _prevSlopeDelta to `_prevLocked.end`
      if (_prevLocked.end > block.timestamp) {
        // _prevSlopeDelta was <something> - _userPrevPoint.slope, so we offset that first
        _prevSlopeDelta = _prevSlopeDelta + _userPrevPoint.slope;
        if (_newLocked.end == _prevLocked.end) {
          // Handle the new deposit. Not increasing lock.
          _prevSlopeDelta = _prevSlopeDelta - _userNewPoint.slope;
        }
        slopeChanges[_prevLocked.end] = _prevSlopeDelta;
      }
      if (_newLocked.end > block.timestamp) {
        if (_newLocked.end > _prevLocked.end) {
          // At this line, the old slope should gone
          _newSlopeDelta = _newSlopeDelta - _userNewPoint.slope;
          slopeChanges[_newLocked.end] = _newSlopeDelta;
        }
      }
    }
  }

  /// @notice Trigger global checkpoint
  function checkpoint() external {
    LockedBalance memory empty = LockedBalance({ amount: 0, end: 0 });
    _checkpoint(address(0), empty, empty);
  }

  /// @notice Create a new lock.
  /// @dev This will crate a new lock and deposit ALPACA to xALPACA Vault
  /// @param _amount the amount that user wishes to deposit
  /// @param _unlockTime the timestamp when ALPACA get unlocked, it will be
  /// floored down to whole weeks
  function createLock(uint256 _amount, uint256 _unlockTime) external onlyEOAorWhitelisted nonReentrant {
    _unlockTime = _timestampToFloorWeek(_unlockTime);
    LockedBalance memory _locked = locks[msg.sender];

    require(_amount > 0, "bad amount");
    require(_locked.amount == 0, "already lock");
    require(_unlockTime > block.timestamp, "can only lock until future");
    require(_unlockTime <= block.timestamp + MAX_LOCK, "can only lock 1 year max");

    _depositFor(msg.sender, _amount, _unlockTime, _locked, ACTION_CREATE_LOCK);
  }

  /// @notice Deposit `_amount` tokens for `_for` and add to `locks[_for]`
  /// @dev This function is used for deposit to created lock. Not for extend locktime.
  /// @param _for The address to do the deposit
  /// @param _amount The amount that user wishes to deposit
  function depositFor(address _for, uint256 _amount) external nonReentrant {
    LockedBalance memory _lock = LockedBalance({ amount: locks[_for].amount, end: locks[_for].end });

    require(_amount > 0, "bad _amount");
    require(_lock.amount > 0, "!lock existed");
    require(_lock.end > block.timestamp, "lock expired. please withdraw");

    _depositFor(_for, _amount, 0, _lock, ACTION_DEPOSIT_FOR);
  }

  /// @notice Internal function to perform deposit and lock ALPACA for a user
  /// @param _for The address to be locked and received xALPACA
  /// @param _amount The amount to deposit
  /// @param _unlockTime New time to unlock ALPACA. Pass 0 if no change.
  /// @param _prevLocked Existed locks[_for]
  /// @param _actionType The action that user did as this internal function shared among
  /// several external functions
  function _depositFor(
    address _for,
    uint256 _amount,
    uint256 _unlockTime,
    LockedBalance memory _prevLocked,
    uint256 _actionType
  ) internal {
    // Initiate _supplyBefore & update supply
    uint256 _supplyBefore = supply;
    supply = _supplyBefore + _amount;

    // Store _prevLocked
    LockedBalance memory _newLocked = LockedBalance({ amount: _prevLocked.amount, end: _prevLocked.end });

    // Adding new lock to existing lock, or if lock is expired
    // - creating a new one
    _newLocked.amount = _newLocked.amount + SafeCastUpgradeable.toInt128(int256(_amount));
    if (_unlockTime != 0) {
      _newLocked.end = _unlockTime;
    }
    locks[_for] = _newLocked;

    // Handling checkpoint here
    _checkpoint(_for, _prevLocked, _newLocked);

    if (_amount != 0) {
      token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    emit LogDeposit(_for, _amount, _newLocked.end, _actionType, block.timestamp);
    emit LogSupply(_supplyBefore, supply);
  }

  /// @notice Do Binary Search to find out block timestamp for block number
  /// @param _blockNumber The block number to find timestamp
  /// @param _maxEpoch No beyond this timestamp
  function _findBlockEpoch(uint256 _blockNumber, uint256 _maxEpoch) internal view returns (uint256) {
    uint256 _min = 0;
    uint256 _max = _maxEpoch;
    // Loop for 128 times -> enough for 128-bit numbers
    for (uint256 i = 0; i < 128; i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if (pointHistory[_mid].blockNumber <= _blockNumber) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }
    return _min;
  }

  /// @notice Do Binary Search to find the most recent user point history preceeding block
  /// @param _user The address of user to find
  /// @param _blockNumber Find the most recent point history before this block number
  function _findUserBlockEpoch(address _user, uint256 _blockNumber) internal view returns (uint256) {
    uint256 _min = 0;
    uint256 _max = userPointEpoch[_user];
    for (uint256 i = 0; i < 128; i++) {
      if (_min >= _max) {
        break;
      }
      uint256 _mid = (_min + _max + 1) / 2;
      if (userPointHistory[_user][_mid].blockNumber <= _blockNumber) {
        _min = _mid;
      } else {
        _max = _mid - 1;
      }
    }
    return _min;
  }

  /// @notice Increase lock amount without increase "end"
  /// @param _amount The amount of ALPACA to be added to the lock
  function increaseLockAmount(uint256 _amount) external onlyEOAorWhitelisted nonReentrant {
    LockedBalance memory _lock = LockedBalance({ amount: locks[msg.sender].amount, end: locks[msg.sender].end });

    require(_amount > 0, "bad _amount");
    require(_lock.amount > 0, "!lock existed");
    require(_lock.end > block.timestamp, "lock expired. please withdraw");

    _depositFor(msg.sender, _amount, 0, _lock, ACTION_INCREASE_LOCK_AMOUNT);
  }

  /// @notice Increase unlock time without changing locked amount
  /// @param _newUnlockTime The new unlock time to be updated
  function increaseUnlockTime(uint256 _newUnlockTime) external onlyEOAorWhitelisted nonReentrant {
    LockedBalance memory _lock = LockedBalance({ amount: locks[msg.sender].amount, end: locks[msg.sender].end });
    _newUnlockTime = _timestampToFloorWeek(_newUnlockTime);

    require(_lock.amount > 0, "!lock existed");
    require(_lock.end > block.timestamp, "lock expired. please withdraw");
    require(_newUnlockTime > _lock.end, "only extend lock");
    require(_newUnlockTime <= block.timestamp + MAX_LOCK, "1 year max");

    _depositFor(msg.sender, 0, _newUnlockTime, _lock, ACTION_INCREASE_UNLOCK_TIME);
  }

  /// @notice Round off random timestamp to week
  /// @param _timestamp The timestamp to be rounded off
  function _timestampToFloorWeek(uint256 _timestamp) internal pure returns (uint256) {
    return (_timestamp / WEEK) * WEEK;
  }

  /// @notice Calculate total supply of xALPACA (voting power)
  function totalSupply() external view returns (uint256) {
    return _totalSupplyAt(pointHistory[epoch], block.timestamp);
  }

  /// @notice Calculate total supply of xALPACA at specific block
  /// @param _blockNumber The specific block number to calculate totalSupply
  function totalSupplyAt(uint256 _blockNumber) external view returns (uint256) {
    require(_blockNumber <= block.number, "bad _blockNumber");
    uint256 _epoch = epoch;
    uint256 _targetEpoch = _findBlockEpoch(_blockNumber, _epoch);

    Point memory _point = pointHistory[_targetEpoch];
    uint256 _timeDelta = 0;
    if (_targetEpoch < _epoch) {
      Point memory _nextPoint = pointHistory[_targetEpoch + 1];
      if (_point.blockNumber != _nextPoint.blockNumber) {
        _timeDelta =
          ((_blockNumber - _point.blockNumber) * (_nextPoint.timestamp - _point.timestamp)) /
          (_nextPoint.blockNumber - _point.blockNumber);
      }
    } else {
      if (_point.blockNumber != block.number) {
        _timeDelta =
          ((_blockNumber - _point.blockNumber) * (block.timestamp - _point.timestamp)) /
          (block.number - _point.blockNumber);
      }
    }

    return _totalSupplyAt(_point, _point.timestamp + _timeDelta);
  }

  /// @notice Calculate total supply of xALPACA (voting power) at some point in the past
  /// @param _point The point to start to search from
  /// @param _timestamp The timestamp to calculate the total voting power at
  function _totalSupplyAt(Point memory _point, uint256 _timestamp) internal view returns (uint256) {
    Point memory _lastPoint = _point;
    uint256 _weekCursor = _timestampToFloorWeek(_point.timestamp);
    // Iterate through weeks to take slopChanges into the account
    for (uint256 i = 0; i < 255; i++) {
      _weekCursor = _weekCursor + WEEK;
      int128 _slopeDelta = 0;
      if (_weekCursor > _timestamp) {
        // If _weekCursor goes beyond _timestamp -> leave _slopeDelta
        // to be 0 as there is no more slopeChanges
        _weekCursor = _timestamp;
      } else {
        // If _weekCursor still behind _timestamp, then _slopeDelta
        // should be taken into the account.
        _slopeDelta = slopeChanges[_weekCursor];
      }
      // Update bias at _weekCursor
      _lastPoint.bias =
        _lastPoint.bias -
        (_lastPoint.slope * SafeCastUpgradeable.toInt128(int256(_weekCursor - _lastPoint.timestamp)));
      if (_weekCursor == _timestamp) {
        break;
      }
      // Update slope and timestamp
      _lastPoint.slope = _lastPoint.slope + _slopeDelta;
      _lastPoint.timestamp = _weekCursor;
    }

    if (_lastPoint.bias < 0) {
      _lastPoint.bias = 0;
    }

    return SafeCastUpgradeable.toUint256(_lastPoint.bias);
  }

  /// @notice Set breaker
  /// @param _breaker The new value of breaker 0 if off, 1 if on
  function setBreaker(uint256 _breaker) external onlyOwner {
    require(_breaker == 0 || _breaker == 1, "only 0 or 1");
    uint256 _previousBreaker = breaker;
    breaker = _breaker;
    emit LogSetBreaker(_previousBreaker, breaker);
  }

  /// @notice Withdraw all ALPACA when lock has expired.
  function withdraw() external nonReentrant {
    LockedBalance memory _lock = locks[msg.sender];

    if (breaker == 0) require(block.timestamp >= _lock.end, "!lock expired");

    uint256 _amount = SafeCastUpgradeable.toUint256(_lock.amount);
    if (_amount != 0) {
      _unlock(_lock, _amount);

      token.safeTransfer(msg.sender, _amount);
    }

    address _grasshouse = grasshouse;
    if (_grasshouse != address(0)) {
      IGrassHouse(_grasshouse).claim(msg.sender);
    }

    emit LogWithdraw(msg.sender, _amount, block.timestamp);
  }

  function _unlock(LockedBalance memory _lock, uint256 _withdrawAmount) internal {
    // Cast here for readability
    uint256 _lockedAmount = SafeCastUpgradeable.toUint256(_lock.amount);
    require(_withdrawAmount <= _lockedAmount, "!enough");

    LockedBalance memory _prevLock = LockedBalance({ end: _lock.end, amount: _lock.amount });
    //_lock.end should remain the same if we do partially withdraw
    _lock.end = _lockedAmount == _withdrawAmount ? 0 : _lock.end;
    _lock.amount = SafeCastUpgradeable.toInt128(int256(_lockedAmount - _withdrawAmount));
    locks[msg.sender] = _lock;

    uint256 _supplyBefore = supply;
    supply = _supplyBefore - _withdrawAmount;

    // _prevLock can have either block.timstamp >= _lock.end or zero end
    // _lock has only 0 end
    // Both can have >= 0 amount
    _checkpoint(msg.sender, _prevLock, _lock);
    emit LogSupply(_supplyBefore, supply);
  }

  function setWhitelistedCallers(address[] calldata callers, bool ok) external onlyOwner {
    for (uint256 idx = 0; idx < callers.length; idx++) {
      whitelistedCallers[callers[idx]] = ok;
      emit LogSetWhitelistedCaller(_msgSender(), callers[idx], ok);
    }
  }

  function setGrasshouse(address _grasshouse) external onlyOwner {
    grasshouse = _grasshouse;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
pragma solidity 0.8.10;

interface IGrassHouse {
  function rewardToken() external returns (address);

  function feed(uint256 _amount) external returns (bool);

  function claim(address _for) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBEP20 is IERC20 {
  /// @dev Return token's name
  function name() external returns (string memory);

  /// @dev Return token's symbol
  function symbol() external returns (string memory);

  /// @dev Return token's decimals
  function decimals() external returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
  function myBalance(address token) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(address(this));
  }

  function safeTransfer(address token, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    // solhint-disable-next-line avoid-low-level-calls
    require(token.code.length > 0, "!contract");
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
  }

  function safeTransferFrom(address token, address from, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    // solhint-disable-next-line avoid-low-level-calls
    require(token.code.length > 0, "!contract");
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
  }

  function safeApprove(address token, address to, uint256 value) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    require(token.code.length > 0, "!contract");
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
  }

  function safeTransferETH(address to, uint256 value) internal {
    // solhint-disable-next-line no-call-value
    (bool success, ) = to.call{ value: value }(new bytes(0));
    require(success, "!safeTransferETH");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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