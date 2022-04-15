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
pragma solidity 0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";

interface ISmartWalletChecker {
  function check(address addr) external view returns (bool);
}

/**
 * @title Smart Wallet Checker implementation.
 * @notice Checks if an address is approved for staking.
 * @dev This is a basic implementation using a mapping for address => bool.
 * @dev This contract does not check if the address is a contract or not.
 * @dev This contract is a modified version of
 * https://github.com/Idle-Finance/idle-staking/blob/master/contracts/smartWalletChecker/SmartWalletChecker.sol
 */
contract SmartWalletChecker is Ownable, ISmartWalletChecker {
  // @dev mapping of allowed addresses
  mapping(address => bool) private _enabledAddresses;
  // @dev Checks if any contract is allowed.
  bool public isOpen;

  /**
   * @notice Enables an address
   * @dev only callable by owner.
   * @dev This does not check if the address is actually a smart contract or not.
   * @param addr The contract address to enable.
   */
  function toggleAddress(address addr, bool _enabled) external onlyOwner {
    _enabledAddresses[addr] = _enabled;
  }

  /**
   * @notice Allow any non EOA to interact with stkIDLE contract.
   * @dev only callable by owner.
   * @dev Once isOpen is set to true, it cannot be set to false without locking users in so be careful.
   * @param _open Wheter to allow or not anyone
   */
  function toggleIsOpen(bool _open) external onlyOwner {
    isOpen = _open;
  }

  /**
   * @notice Check an address
   * @dev This method will be called by the VotingEscrow contract.
   * @param addr The contract address to check.
   */
  function check(address addr) external view override returns (bool) {
    return isOpen || _enabledAddresses[addr];
  }
}