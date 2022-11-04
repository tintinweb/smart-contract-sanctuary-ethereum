//SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

import "./RewardConfiguration.sol";
import "../interfaces/IRewardConfiguration.sol";

library LRewardConfigurationDeployer {
    function deployRewardConfiguration() external returns(IRewardConfiguration) {
        return new RewardConfiguration();
    }
}

//SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IRewardConfiguration.sol";

contract RewardConfiguration is IRewardConfiguration, Ownable {
  address[] internal rewardReceivers_;
  uint256[] internal percentageRewardDistribution_;

  function _countSum() internal view returns (uint256) {
    uint256 len = rewardReceivers_.length;
    require(len == percentageRewardDistribution_.length, "FeeConfiguration: Incorrect len of arrays");

    uint256 sum = 0;
    for (uint256 i = 0; i < len; ) {
      require(percentageRewardDistribution_[i] <= 100 ether, "FeeConfiguration: Cannot distribute more than 100%");
      unchecked {
        sum += percentageRewardDistribution_[i];
        ++i;
      }
    }

    return sum;
  }

  function _assertConfigCorrect() internal view {
    uint256 sum = _countSum();

    require(sum == 100 ether, "FeeConfiguration: Reward percentage doesnt sum to 100%");
  }

  function rewardReceivers() external virtual override returns (address[] memory) {
    return rewardReceivers_;
  }

  function rewardDistribution() external virtual override returns (uint256[] memory) {
    return percentageRewardDistribution_;
  }

  function addRewardReceiver(
    address receiver_,
    uint256 newRewardDistribution_,
    bool finalize_
  ) external virtual override onlyOwner {
    rewardReceivers_.push(receiver_);
    percentageRewardDistribution_.push(newRewardDistribution_);

    if (finalize_) {
      _assertConfigCorrect();
    }
  }

  function addLastRewardReceiver(address receiver_) external virtual override onlyOwner {
    uint256 sum = _countSum();
    rewardReceivers_.push(receiver_);
    percentageRewardDistribution_.push(100 ether - sum);

    _assertConfigCorrect();
  }
}

//SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

interface IRewardConfiguration {
    function rewardReceivers() external returns(address[] memory);
    function rewardDistribution() external returns(uint256[] memory);
    function addRewardReceiver(address receiver, uint256 newRewardDistribution, bool finalize) external;
    function addLastRewardReceiver(address receiver) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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