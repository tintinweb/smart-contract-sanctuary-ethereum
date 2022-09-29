// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Registry is Ownable {
    // ============================================= ADDRESS CONFIG =============================================

    /**
     * @notice Emitted when the address of a contract is changed.
     * @param id value representing the unique ID tied to the changed contract
     * @param oldAddress address of the contract before the change
     * @param newAddress address of the contract after the contract
     */
    event AddressChanged(uint256 indexed id, address oldAddress, address newAddress);

    /**
     * @notice Attempted to set the address of a contract that is not registered.
     * @param id id of the contract that is not registered
     */
    error Registry__ContractNotRegistered(uint256 id);

    /**
     * @notice Emitted when depositor privilege changes.
     * @param depositor depositor address
     * @param state the new state of the depositor privilege
     */
    event DepositorOnBehalfChanged(address depositor, bool state);

    /**
     * @notice The unique ID that the next registered contract will have.
     */
    uint256 public nextId;

    /**
     * @notice Get the address associated with an id.
     */
    mapping(uint256 => address) public getAddress;

    /**
     * @notice In order for an address to make deposits on behalf of users they must be approved.
     */
    mapping(address => bool) public approvedForDepositOnBehalf;

    /**
     * @notice toggles a depositors  ability to deposit into cellars on behalf of users.
     */
    function setApprovedForDepositOnBehalf(address depositor, bool state) external onlyOwner {
        approvedForDepositOnBehalf[depositor] = state;
        emit DepositorOnBehalfChanged(depositor, state);
    }

    /**
     * @notice Set the address of the contract at a given id.
     */
    function setAddress(uint256 id, address newAddress) external onlyOwner {
        if (id >= nextId) revert Registry__ContractNotRegistered(id);

        emit AddressChanged(id, getAddress[id], newAddress);

        getAddress[id] = newAddress;
    }

    // ============================================= INITIALIZATION =============================================

    /**
     * @param gravityBridge address of GravityBridge contract
     * @param swapRouter address of SwapRouter contract
     * @param priceRouter address of PriceRouter contract
     */
    constructor(
        address gravityBridge,
        address swapRouter,
        address priceRouter
    ) Ownable() {
        _register(gravityBridge);
        _register(swapRouter);
        _register(priceRouter);
    }

    // ============================================ REGISTER CONFIG ============================================

    /**
     * @notice Emitted when a new contract is registered.
     * @param id value representing the unique ID tied to the new contract
     * @param newContract address of the new contract
     */
    event Registered(uint256 indexed id, address indexed newContract);

    /**
     * @notice Register the address of a new contract.
     * @param newContract address of the new contract to register
     */
    function register(address newContract) external onlyOwner {
        _register(newContract);
    }

    function _register(address newContract) internal {
        getAddress[nextId] = newContract;

        emit Registered(nextId, newContract);

        nextId++;
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