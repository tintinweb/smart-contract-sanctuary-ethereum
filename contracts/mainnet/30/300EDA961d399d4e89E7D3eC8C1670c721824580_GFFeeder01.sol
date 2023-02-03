// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./base/BaseFeeder.sol";
import "./interfaces/IxGF.sol";
import "./interfaces/IStakingPoolManager.sol";
import "./SafeToken.sol";

contract GFFeeder01 is BaseFeeder {
  using SafeToken for address;

  struct Snapshot {
    uint112 stakingPoolTvl;
    uint112 xGFTvl;
    uint32 blockNumber;
  }

  uint256 public constant MAX_BIAS = 10000;

  IStakingPoolManager public stakingPoolManager;
  address public stakingPool;

  uint256 public bias = 3000; // 30%

  /// @dev Mapping ( round off timestamp to week => Snapshot ) to keep track of each week snapshot
  mapping(uint256 => Snapshot) public weeklySnapshotOf;

  event MissingSnapshot(uint40 fromBlock, uint40 toBlock);
  event SetBias(uint256 oldBias, uint256 newBias);


  constructor(
    address _stakingPool,
    address _stakingPoolManager,
    address _rewardManager,
    address _rewardSource,
    uint256 _rewardRatePerBlock,
    uint40 _lastRewardBlock,
    uint40 _rewardEndBlock
  ) BaseFeeder(_rewardManager, _rewardSource, _rewardRatePerBlock, _lastRewardBlock, _rewardEndBlock) {
    stakingPoolManager = IStakingPoolManager(_stakingPoolManager);
    stakingPool = _stakingPool;

    require(stakingPoolManager.reward() == rewardManager.rewardToken(), "invalid legacy reward");

    token.safeApprove(_rewardManager, type(uint256).max);
  }

  function stakingPoolTvl() public view returns (uint256) {
    return IERC20(token).balanceOf(stakingPool);
  }

  function xGFTvl() public view returns (uint256) {
    return IxGF(rewardManager.xGF()).supply() + rewardManager.lastTokenBalance();
  }

  function getRate(uint256 timestamp) external view returns (uint256, uint256) {
    uint256 _weekCursor = _timestampToFloorWeek(timestamp);
    return _getRate(weeklySnapshotOf[_weekCursor], rewardRatePerBlock);
  }

  function _feed() override internal  {
    // 1. Feed reward for this week
    Snapshot memory _thisWeekSnapshot = weeklySnapshotOf[_timestampToFloorWeek(block.timestamp)];

    if (_thisWeekSnapshot.blockNumber == 0) {
      // missing a call to snapshot this week, need to fix with inject reward
      emit MissingSnapshot(lastRewardBlock, uint40(block.number));
    } else {
      _updatePools(_thisWeekSnapshot, lastRewardBlock);
    }
    _updateLastRewardBlock(uint40(block.number));
    // 3. Record Snapshot to be used for next week
    _takeSnapshot(_timestampToFloorWeek(block.timestamp + WEEK - 1));
  }

  function _updateLastRewardBlock(uint40 blockNumber) internal {
    uint40 _rewardEndBlock = rewardEndBlock;
    lastRewardBlock = blockNumber > _rewardEndBlock ? _rewardEndBlock : blockNumber;
  }

  function _updatePools(Snapshot memory _snapshot, uint40 _lastRewardBlock) internal {
    (uint256 rate1, uint256 rate2) = _getRate(_snapshot, rewardRatePerBlock);
    _setStakingPoolManagerRate(rate1);
    uint256 _feedAmount = _feedRewardManager(rate2, _lastRewardBlock, block.number);
    emit Feed(_feedAmount);
  }


  function _takeSnapshot(uint256 _weekCursor) internal {
    weeklySnapshotOf[_weekCursor] = Snapshot({
      stakingPoolTvl: uint112(stakingPoolTvl()),
      xGFTvl: uint112(xGFTvl()),
      blockNumber: uint32(block.number)
    });
  }

  function _setStakingPoolManagerRate(uint256 _rate) internal {
    if (stakingPoolManager.rewardPerBlock() == _rate) {
      stakingPoolManager.distributeRewards();
    } else {
      stakingPoolManager.setRewardPerBlock(_rate);
    }
  }

  function _feedRewardManager(
    uint256 _rate,
    uint256 _fromBlock,
    uint256 _toBlock
  ) internal returns (uint256) {
    uint256 blockDelta = _getMultiplier(_fromBlock, _toBlock, rewardEndBlock);
    if (blockDelta == 0) {
      return 0;
    }
    uint256 _toDistribute = _rate * blockDelta;
    if (_toDistribute > 0) {
      token.safeTransferFrom(rewardSource, address(this), _toDistribute);
      rewardManager.feed(_toDistribute);
    }

    return _toDistribute;
  }

  function _getMultiplier(
    uint256 _from,
    uint256 _to,
    uint256 _endBlock
  ) internal pure returns (uint256) {
    if ((_from >= _endBlock) || (_from > _to)) {
      return 0;
    }

    if (_to <= _endBlock) {
      return _to - _from;
    }
    return _endBlock - _from;
  }

  function _getRate(Snapshot memory _snapshot, uint256 _maxRatePerBlock)
    internal
    view
    returns (uint256 rate1, uint256 rate2)
  {
    if (_snapshot.stakingPoolTvl == 0 || _snapshot.xGFTvl == 0) {
      rate1 = 0;
      rate2 = 0;
      return (rate1, rate2);
    }

    uint256 _bias = bias;
    uint256 _adjustedV1Weight = uint256(_snapshot.stakingPoolTvl) + MAX_BIAS - _bias;
    uint256 _adjustedV2Weight = uint256(_snapshot.xGFTvl) + MAX_BIAS + _bias;

    uint256 _totalWeight = _adjustedV1Weight + _adjustedV2Weight;

    rate1 = (_maxRatePerBlock * _adjustedV1Weight) / _totalWeight;
    rate2 = (_maxRatePerBlock * _adjustedV2Weight) / _totalWeight;
  }

  function _timestampToFloorWeek(uint256 _timestamp) internal pure returns (uint256) {
    return (_timestamp / WEEK) * WEEK;
  }

  function setBias(uint256 _newBias, bool _distribute) external onlyOwner {
    require(_newBias <= MAX_BIAS, "exceed MAX_BIAS");
    if (_distribute) {
      _feed();
    }

    uint256 _oldBias = bias;
    bias = _newBias;
    emit SetBias(_oldBias, _newBias);
  }

  function injectSnapshot(uint256 _timestamp, Snapshot memory _snapshot) external onlyOwner {
    uint256 _weekCursor = _timestampToFloorWeek(_timestamp);
    weeklySnapshotOf[_weekCursor] = _snapshot;
  }

  function setRewardRatePerBlock(uint256 _newRate) override external onlyOwner {
    // 1. feed
    Snapshot memory _thisWeekSnapshot = weeklySnapshotOf[_timestampToFloorWeek(block.timestamp)];
    require(_thisWeekSnapshot.blockNumber != 0, "!thisWeekSnapshot");
    _updatePools(_thisWeekSnapshot, lastRewardBlock);
    _updateLastRewardBlock(uint40(block.number));
    _takeSnapshot(_timestampToFloorWeek(block.timestamp + WEEK - 1));
    
    // 2. update rate
    uint256 _nextWeekCursor = _timestampToFloorWeek(block.timestamp + WEEK - 1);
    _takeSnapshot(_nextWeekCursor);

    uint256 _prevRate = rewardRatePerBlock;
    rewardRatePerBlock = _newRate;

    // 3. apply new rate to staking pool
    (uint newRate1,) = _getRate(_thisWeekSnapshot, _newRate);
    _setStakingPoolManagerRate(newRate1);

    emit SetNewRewardRatePerBlock(msg.sender, _prevRate, _newRate);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IRewardManager.sol";

abstract contract BaseFeeder is Ownable {
  /// @dev Time-related constants
  uint256 public constant WEEK = 7 days;

  address public token;
  address public rewardSource;

  IRewardManager public rewardManager;
  uint40 public lastRewardBlock;
  uint40 public rewardEndBlock;

  uint256 public rewardRatePerBlock;

  mapping(address => bool) public whitelistedFeedCallers;

  event Feed(uint256 feedAmount);
  event SetCanDistributeRewards(bool canDistributeRewards);
  event SetNewRewardEndBlock(address indexed caller, uint256 preRewardEndBlock, uint256 newRewardEndBlock);
  event SetNewRewardRatePerBlock(address indexed caller, uint256 prevRate, uint256 newRate);
  event SetNewRewardSource(address indexed caller, address prevSource, address newSource);
  event SetNewRewardManager(address indexed caller, address prevManager, address newManager);
  event SetWhitelistedFeedCaller(address indexed caller, address indexed addr, bool ok);

  constructor(
    address _rewardManager,
    address _rewardSource,
    uint256 _rewardRatePerBlock,
    uint40 _lastRewardBlock,
    uint40 _rewardEndBlock
  ) {
    rewardManager = IRewardManager(_rewardManager);
    token = rewardManager.rewardToken();
    rewardSource = _rewardSource;
    lastRewardBlock = _lastRewardBlock;
    rewardEndBlock = _rewardEndBlock;
    rewardRatePerBlock = _rewardRatePerBlock;
    
    require(_lastRewardBlock < _rewardEndBlock, "bad _lastRewardBlock");
  }

  function feed() external {
    require(whitelistedFeedCallers[msg.sender],"!whitelisted");
    _feed();
  }

  function _feed() virtual internal;

  function setRewardRatePerBlock(uint256 _newRate) virtual external onlyOwner   {
    _feed();
    uint256 _prevRate = rewardRatePerBlock;
    rewardRatePerBlock = _newRate;
    emit SetNewRewardRatePerBlock(msg.sender, _prevRate, _newRate);
  }

  function setRewardEndBlock(uint40 _newRewardEndBlock) external onlyOwner {
    uint40 _prevRewardEndBlock = rewardEndBlock;
    require(_newRewardEndBlock > rewardEndBlock, "!future");
    rewardEndBlock = _newRewardEndBlock;
    emit SetNewRewardEndBlock(msg.sender, _prevRewardEndBlock, _newRewardEndBlock);
  }


  function setRewardSource(address _rewardSource) external onlyOwner {
    address _prevSource = rewardSource;
    rewardSource = _rewardSource;
    emit SetNewRewardSource(msg.sender, _prevSource , _rewardSource);
  }

  function setRewardManager(address _newManager) external onlyOwner {
    address _prevManager = address(rewardManager);
    rewardManager = IRewardManager(_newManager);
    emit SetNewRewardManager(msg.sender, _prevManager, _newManager);
  }

  function setWhitelistedFeedCallers(address[] calldata callers, bool ok) external onlyOwner {
    for (uint256 idx = 0; idx < callers.length; idx++) {
      whitelistedFeedCallers[callers[idx]] = ok;
      emit SetWhitelistedFeedCaller(msg.sender, callers[idx], ok);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

struct Point {
  int128 bias; // Voting weight
  int128 slope; // Multiplier factor to get voting weight at a given time
  uint256 timestamp;
  uint256 blockNumber;
}

interface IxGF {
  /// @dev Return the max epoch of the given "_user"
  function userPointEpoch(address _user) external view returns (uint256);

  /// @dev Return the max global epoch
  function epoch() external view returns (uint256);

  /// @dev Return the recorded point for _user at specific _epoch
  function userPointHistory(address _user, uint256 _epoch) external view returns (Point memory);

  /// @dev Return the recorded global point at specific _epoch
  function pointHistory(uint256 _epoch) external view returns (Point memory);

  /// @dev Trigger global check point
  function checkpoint() external;

  function supply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IStakingPoolManager {
  function reward() external view returns (address);

  function rewardPerBlock() external view returns (uint256);
  
  function setRewardPerBlock(uint256 _rewardPerBlock) external;

  function distributeRewards() external;
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
pragma solidity 0.8.10;

interface IRewardManager {
  function xGF() external view returns (address);

  function rewardToken() external returns (address);

  function feed(uint256 _amount) external returns (bool);

  function claim(address _for) external returns (uint256);

  function pendingRewardsOf(address _user) external returns (uint256);

  function lastTokenBalance() external view returns (uint256);

  function checkpointToken() external view returns (uint256);
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