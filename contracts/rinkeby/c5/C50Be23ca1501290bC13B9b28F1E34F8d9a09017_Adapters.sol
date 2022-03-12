//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAdapters.sol";


/// @title Contract storing adapters for harvest and management for different token addresses
/// @author George Spasov
/// @notice This contract holds addresses of harvest and management adapters. These can be called or delegatecalled by the Fractional vaults in order to execute certain business logic actions
/// @dev Ownership must be transferred to the DAO
contract Adapters is Ownable, IAdapters {

    struct SupportedAdapters {
        address harvestAdapter;
        address managementAdapter;
    }

    mapping(address => SupportedAdapters) public adapterOf;
    address[] public adapters;

    /// @notice Sets the adapters for the token with the `tokenAddress` address
    /// @param tokenAddress The token address to set as supported
    /// @dev tokenAddress Only doable by the DAO
    function setAdapters(address tokenAddress, address harvestAdapter, address managementAdapter) external onlyOwner {
        require(tokenAddress != address(0x0), "setAdapters :: tokenAddress cannot be 0");
        require(harvestAdapter != address(0x0), "setAdapters :: harvestAdapter cannot be 0");
        require(managementAdapter != address(0x0), "setAdapters :: managementAdapter cannot be 0");

        if (adapterOf[tokenAddress].harvestAdapter == address(0x0)) {// It is a new token
            adapters.push(tokenAddress);
        }

        adapterOf[tokenAddress] = SupportedAdapters(harvestAdapter, managementAdapter);

        emit AdaptersSet(tokenAddress, harvestAdapter, managementAdapter);
    }

    /// @notice Returns the count of all the adapters available
    /// @return The number of adapters available
    function adaptersCount() public view returns (uint256) {
        return adapters.length;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;


interface IAdapters {

    event AdaptersSet(address indexed tokenAddress, address harvestAdapters, address managementAdapter);

    function adapters(uint256) external view returns (address);

    function adapterOf(address) external view returns (address, address);

    function setAdapters(address tokenAddress, address harvestAdapter, address managementAdapter) external;

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