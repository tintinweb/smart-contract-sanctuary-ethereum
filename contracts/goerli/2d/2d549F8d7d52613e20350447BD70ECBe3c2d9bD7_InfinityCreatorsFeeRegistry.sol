// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IFeeRegistry} from '../interfaces/IFeeRegistry.sol';

/**
 * @title InfinityCreatorsFeeRegistry
 */
contract InfinityCreatorsFeeRegistry is IFeeRegistry, Ownable {
  address CREATORS_FEE_MANAGER;
  struct FeeInfo {
    address setter;
    address[] destinations;
    uint16[] bpsSplits;
  }

  mapping(address => FeeInfo) private _creatorsFeeInfo;

  event CreatorsFeeUpdate(
    address indexed collection,
    address indexed setter,
    address[] destinations,
    uint16[] bpsSplits
  );

  event CreatorsFeeManagerUpdated(address indexed manager);

  /**
   * @notice Update creators fee for collection
   * @param collection address of the NFT contract
   * @param setter address that sets destinations
   * @param destinations receivers for the fee
   * @param bpsSplits fee (500 = 5%, 1,000 = 10%)
   */
  function registerFeeDestinations(
    address collection,
    address setter,
    address[] calldata destinations,
    uint16[] calldata bpsSplits
  ) external override {
    require(msg.sender == CREATORS_FEE_MANAGER, 'Creators Fee Registry: Only creators fee manager');
    _creatorsFeeInfo[collection] = FeeInfo({setter: setter, destinations: destinations, bpsSplits: bpsSplits});
    emit CreatorsFeeUpdate(collection, setter, destinations, bpsSplits);
  }

  /**
   * @notice View creator fee info for a collection address
   * @param collection collection address
   */
  function getFeeInfo(address collection)
    external
    view
    override
    returns (
      address,
      address[] memory,
      uint16[] memory
    )
  {
    return (
      _creatorsFeeInfo[collection].setter,
      _creatorsFeeInfo[collection].destinations,
      _creatorsFeeInfo[collection].bpsSplits
    );
  }

  // ===================================================== ADMIN FUNCTIONS =====================================================

  function updateCreatorsFeeManager(address manager) external onlyOwner {
    CREATORS_FEE_MANAGER = manager;
    emit CreatorsFeeManagerUpdated(manager);
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
pragma solidity ^0.8.0;

interface IFeeRegistry {
  function registerFeeDestinations(
    address collection,
    address setter,
    address[] calldata destinations,
    uint16[] calldata bpsSplits
  ) external;

  function getFeeInfo(address collection)
    external
    view
    returns (
      address,
      address[] calldata,
      uint16[] calldata
    );
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