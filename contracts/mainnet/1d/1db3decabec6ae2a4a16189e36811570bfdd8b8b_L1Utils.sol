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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

/// @title L1Utils
/// @notice This is contract that Ribbon Lend references to retrieve the necessary information
contract L1Utils is Ownable {
    /// @notice The L1 bridge address
    address public immutable l1Bridge;

    /// @notice The l2 gas limit amount
    uint32 public l2GasLimit;

    /// @notice The correspondence between l1 and l2 ERC20 addresses
    mapping(address => address) public l1ToL2ERC20Address;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructor
    /// @param _l1Bridge The L1 bridge address
    /// @param _l2GasLimit The l2 gas limit amount
    constructor(address _l1Bridge, uint32 _l2GasLimit) {
        l1Bridge = _l1Bridge;
        l2GasLimit = _l2GasLimit;
    }

    /*//////////////////////////////////////////////////////////////
                                UTILS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Updates l1 and corresponding l2 token addresses
    /// @param _l1ERC20 The l1 token address
    /// @param _l2ERC20 The l2 token address
    function updateL1ToL2ERC20Mapping(address _l1ERC20, address _l2ERC20) external onlyOwner {
        require(_l1ERC20 != address(0), "L1_ADDRESS_ZERO");
        require(_l2ERC20 != address(0), "L2_ADDRESS_ZERO");
        l1ToL2ERC20Address[_l1ERC20] = _l2ERC20;
    }

    /// @notice Updates the gas limit amount
    /// @param _l2GasLimit The new gas limit amount
    function updateL2GasLimit(uint32 _l2GasLimit) external onlyOwner {
        require(_l2GasLimit > 0, "ZERO_AMOUNT");
        l2GasLimit = _l2GasLimit;
    }
}