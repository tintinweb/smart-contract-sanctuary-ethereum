// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./SafeToken.sol";
import "./base/BaseFeeder.sol";

contract GFFeeder02 is BaseFeeder {
  using SafeToken for address;

  constructor(
    address _rewardManager,
    address _rewardSource,
    uint256 _rewardRatePerBlock,
    uint40 _lastRewardBlock,
    uint40 _rewardEndBlock
  ) BaseFeeder( _rewardManager, _rewardSource, _rewardRatePerBlock, _lastRewardBlock, _rewardEndBlock) {
    token.safeApprove(_rewardManager, type(uint256).max);
  }

  function _feed() override internal  {
    uint40 _rewardEndBlock = rewardEndBlock;
    uint256 _lastRewardBlock = lastRewardBlock;
    uint256 blockDelta = _getMultiplier(_lastRewardBlock, block.number, _rewardEndBlock);
    if (blockDelta == 0) {
      return;
    }

    uint256 _toDistribute = rewardRatePerBlock * blockDelta;
    uint40 blockNumber = uint40(block.number);
    lastRewardBlock = blockNumber > _rewardEndBlock ? _rewardEndBlock : blockNumber;
    if (_toDistribute > 0) {
      token.safeTransferFrom(rewardSource, address(this), _toDistribute);
      rewardManager.feed(_toDistribute);
    }

    emit Feed(_toDistribute);
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