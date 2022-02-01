// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Celestial Vault
contract CelestialVault is Ownable {
  /// @notice Basic deposit structure.
  struct Deposit {
    address recipient;
    uint64 timestamp;
  }

  /// @notice Rewards end time.
  uint256 public endTime;

  /// @notice Distributed rewards per day staked.
  uint256 public rate;

  /// @notice Fast Food Frens contract address.
  ICKEY public stakingToken;

  /// @notice Fries contract address.
  IFBX public rewardToken;

  /// @notice Deposit by token Id mapping.
  mapping(uint256 => Deposit) public deposits;

  constructor(
    address newStakingToken,
    address newRewardToken,
    uint256 newRate,
    uint256 newEndTime
  ) {
    stakingToken = ICKEY(newStakingToken);
    rewardToken = IFBX(newRewardToken);
    rate = newRate;
    endTime = newEndTime;
  }

  /// @notice Deposit tokens with `ids`. Tokens MUST have been approved to this contract first.
  function stake(uint256[] memory ids) external {
    for (uint256 i = 0; i < ids.length; i++) {
      require(deposits[ids[i]].recipient == address(0), "Token already staked");
      // Add the new deposit to the mapping
      deposits[ids[i]] = Deposit(msg.sender, uint64(block.timestamp));
      // Transfer the deposited token to this contract
      stakingToken.transferFrom(msg.sender, address(this), ids[i]);
    }
  }

  /// @notice Withdraw tokens with `ids` and claim their pending rewards.
  function withdraw(uint256[] memory ids) external {
    for (uint256 i = 0; i < ids.length; i++) {
      require(deposits[ids[i]].recipient == msg.sender, "Token not staked or sender is no the owner");
      // Get pending rewards and delete old deposit
      uint256 totalRewards = _earned(ids[i]);
      delete deposits[ids[i]];
      // Mint the new rewards and transfer back the nft
      rewardToken.mint(msg.sender, totalRewards);
      stakingToken.safeTransferFrom(address(this), msg.sender, ids[i]);
    }
  }

  /// @notice Claim pending rewards for `ids`.
  function claim(uint256[] memory ids) external {
    for (uint256 i = 0; i < ids.length; i++) {
      require(deposits[ids[i]].recipient == msg.sender, "Token not staked or sender is no the owner");

      // Calculate rewards and update last timestamp
      uint256 totalRewards = _earned(ids[i]);
      deposits[ids[i]].timestamp = uint64(block.timestamp);

      // Mint the new tokens
      rewardToken.mint(msg.sender, totalRewards);
    }
  }

  /// @notice Calculate total rewards for given `ids`.
  function earned(uint256[] memory ids) public view returns (uint256 totalRewards) {
    for (uint256 i = 0; i < ids.length; i++) totalRewards += _earned(ids[i]);
  }

  /// @notice Set the new token rewards rate.
  function setRate(uint256 rate_) external onlyOwner {
    rate = rate_;
  }

  /// @notice Set the new rewards period end time.
  function setEndTime(uint256 endTime_) external onlyOwner {
    require(endTime_ > block.timestamp, "End time must be greater than now");
    endTime = endTime_;
  }

  /// @notice Internally calculates rewards for token `_id`.
  function _earned(uint256 id_) internal view returns (uint256) {
    if (deposits[id_].timestamp == 0) return 0;
    return ((Math.min(block.timestamp, endTime) - deposits[id_].timestamp) * rate) / 1 days;
  }
}

interface IFBX {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

interface ICKEY {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

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