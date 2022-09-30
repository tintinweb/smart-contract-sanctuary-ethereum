// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";

/// @title meTokens Protocol Vault Registry
/// @author Carter Carlson (@cartercarlson)
/// @notice Approved vaults to be used within meTokens Protocol.
contract VaultRegistry is IVaultRegistry, Ownable {
    // NOTE: approved vault factories could be for:
    // Vanilla erc20 vaults, Uniswap-LP vaults, Balancer LP  vaults, etc.
    mapping(address => bool) private _approved;

    /// @inheritdoc IVaultRegistry
    function approve(address addr) external override onlyOwner {
        require(!_approved[addr], "addr approved");
        _approved[addr] = true;
        emit Approve(addr);
    }

    /// @inheritdoc IVaultRegistry
    function unapprove(address addr) external override onlyOwner {
        require(_approved[addr], "addr !approved");
        _approved[addr] = false;
        emit Unapprove(addr);
    }

    /// @inheritdoc IVaultRegistry
    function isApproved(address addr) external view override returns (bool) {
        return _approved[addr];
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

/// @title meTokens Protocol Vault Registry interface
/// @author Carter Carlson (@cartercarlson)
interface IVaultRegistry {
    /// @notice Event of approving an address
    /// @param addr Address to approve
    event Approve(address addr);

    /// @notice Event of unapproving an address
    /// @param addr Address to unapprove
    event Unapprove(address addr);

    /// @notice Approve an address
    /// @param addr Address to approve
    function approve(address addr) external;

    /// @notice Unapprove an address
    /// @param addr Address to unapprove
    function unapprove(address addr) external;

    /// @notice View to see if an address is approved
    /// @param addr     Address to view
    /// @return         True if address is approved, else false
    function isApproved(address addr) external view returns (bool);
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