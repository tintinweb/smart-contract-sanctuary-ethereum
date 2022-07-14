// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMigrationRegistry} from "../interfaces/IMigrationRegistry.sol";

/// @title Migration Registry
/// @author Carter Carlson (@cartercarlson)
/// @notice Contract which manages all migration routes for when a meToken
///         changes its' base asset
contract MigrationRegistry is Ownable, IMigrationRegistry {
    // Initial vault, target vault, migration vault, approved status
    mapping(address => mapping(address => mapping(address => bool)))
        private _migrations;

    function approve(
        address initialVault,
        address targetVault,
        address migration
    ) external override onlyOwner {
        require(
            !_migrations[initialVault][targetVault][migration],
            "migration already approved"
        );
        _migrations[initialVault][targetVault][migration] = true;
        emit Approve(initialVault, targetVault, migration);
    }

    function unapprove(
        address initialVault,
        address targetVault,
        address migration
    ) external override onlyOwner {
        require(
            _migrations[initialVault][targetVault][migration],
            "migration not approved"
        );
        _migrations[initialVault][targetVault][migration] = false;
        emit Unapprove(initialVault, targetVault, migration);
    }

    function isApproved(
        address initialVault,
        address targetVault,
        address migration
    ) external view override returns (bool) {
        return _migrations[initialVault][targetVault][migration];
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title MeToken migration registry interface
/// @author Carter Carlson (@cartercarlson)
interface IMigrationRegistry {
    /// @notice Event of approving a meToken migration route
    /// @param initialVault    Vault for meToken to start migration from
    /// @param targetVault     Vault for meToken to migrate to
    /// @param migration       Address of migration vault
    event Approve(address initialVault, address targetVault, address migration);

    /// @notice Event of unapproving a meToken migration route
    /// @param initialVault    Vault for meToken to start migration from
    /// @param targetVault     Vault for meToken to migrate to
    /// @param migration       Address of migration vault
    event Unapprove(
        address initialVault,
        address targetVault,
        address migration
    );

    /// @notice Approve a vault migration route
    /// @param initialVault    Vault for meToken to start migration from
    /// @param targetVault     Vault for meToken to migrate to
    /// @param migration       Address of migration vault
    function approve(
        address initialVault,
        address targetVault,
        address migration
    ) external;

    /// @notice Unapprove a vault migration route
    /// @param initialVault    Vault for meToken to start migration from
    /// @param targetVault     Vault for meToken to migrate to
    /// @param migration       Address of migration vault
    function unapprove(
        address initialVault,
        address targetVault,
        address migration
    ) external;

    /// @notice View to see if a specific migration route is approved
    /// @param initialVault Vault for meToken to start migration from
    /// @param targetVault  Vault for meToken to migrate to
    /// @param migration    Address of migration vault
    /// @return             True if migration route is approved, else false
    function isApproved(
        address initialVault,
        address targetVault,
        address migration
    ) external view returns (bool);
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