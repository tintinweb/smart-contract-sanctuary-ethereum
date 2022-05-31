// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICallWhitelist.sol";

/**
 * @title CallWhitelist
 * @author Non-Fungible Technologies, Inc.
 *
 * Maintains a whitelist for calls that can be made from an AssetVault.
 * Intended to be used to allow for "claim" and other-utility based
 * functions while an asset is being held in escrow. Some functions
 * are blacklisted, e.g. transfer functions, to prevent callers from
 * being able to circumvent withdrawal rules for escrowed assets.
 * Whitelists are specified in terms of "target contract" (callee)
 * and function selector.
 *
 * The contract owner can add or remove items from the whitelist.
 */
contract CallWhitelist is Ownable, ICallWhitelist {
    // ============================================ STATE ==============================================

    // ============= Global Immutable State ==============

    /**
     * @dev Global blacklist for transfer functions.
     */
    bytes4 private constant ERC20_TRANSFER = 0xa9059cbb;
    bytes4 private constant ERC20_ERC721_APPROVE = 0x095ea7b3;
    bytes4 private constant ERC20_ERC721_TRANSFER_FROM = 0x23b872dd;

    bytes4 private constant ERC721_SAFE_TRANSFER_FROM = 0x42842e0e;
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM_DATA = 0xb88d4fde;
    bytes4 private constant ERC721_ERC1155_SET_APPROVAL = 0xa22cb465;

    bytes4 private constant ERC1155_SAFE_TRANSFER_FROM = 0xf242432a;
    bytes4 private constant ERC1155_SAFE_BATCH_TRANSFER_FROM = 0x2eb2c2d6;

    // ================= Whitelist State ==================

    /**
     * @notice Whitelist of callable functions on contracts. Maps addresses that
     *         can be called to function selectors which can be called on it.
     *         For example, if we want to allow function call 0x0000 on a contract
     *         at 0x1111, the mapping will contain whitelist[0x1111][0x0000] = true.
     */
    mapping(address => mapping(bytes4 => bool)) private whitelist;

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @notice Returns true if the given function on the given callee is whitelisted.
     *
     * @param callee                The contract that is intended to be called.
     * @param selector              The function selector that is intended to be called.
     *
     * @return isWhitelisted        True if whitelisted, else false.
     */
    function isWhitelisted(address callee, bytes4 selector) external view override returns (bool) {
        return !isBlacklisted(selector) && whitelist[callee][selector];
    }

    /**
     * @notice Returns true if the given function selector is on the global blacklist.
     *         Blacklisted function selectors cannot be called on any contract.
     *
     * @param selector              The function selector to check.
     *
     * @return isBlacklisted        True if blacklisted, else false.
     */
    function isBlacklisted(bytes4 selector) public pure override returns (bool) {
        return
            selector == ERC20_TRANSFER ||
            selector == ERC20_ERC721_APPROVE ||
            selector == ERC20_ERC721_TRANSFER_FROM ||
            selector == ERC721_SAFE_TRANSFER_FROM ||
            selector == ERC721_SAFE_TRANSFER_FROM_DATA ||
            selector == ERC721_ERC1155_SET_APPROVAL ||
            selector == ERC1155_SAFE_TRANSFER_FROM ||
            selector == ERC1155_SAFE_BATCH_TRANSFER_FROM;
    }

    // ======================================== UPDATE OPERATIONS =======================================

    /**
     * @notice Add the given callee and selector to the whitelist. Can only be called by owner.
     * @dev    A blacklist supersedes a whitelist, so should not add blacklisted selectors.
     *
     * @param callee                The contract to whitelist.
     * @param selector              The function selector to whitelist.
     */
    function add(address callee, bytes4 selector) external override onlyOwner {
        whitelist[callee][selector] = true;
        emit CallAdded(msg.sender, callee, selector);
    }

    /**
     * @notice Remove the given calle and selector from the whitelist. Can only be called by owner.
     *
     * @param callee                The contract to whitelist.
     * @param selector              The function selector to whitelist.
     */
    function remove(address callee, bytes4 selector) external override onlyOwner {
        whitelist[callee][selector] = false;
        emit CallRemoved(msg.sender, callee, selector);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ICallWhitelist {
    // ============= Events ==============

    event CallAdded(address operator, address callee, bytes4 selector);
    event CallRemoved(address operator, address callee, bytes4 selector);

    // ================ View Functions ================

    function isWhitelisted(address callee, bytes4 selector) external view returns (bool);

    function isBlacklisted(bytes4 selector) external view returns (bool);

    // ================ Update Operations ================

    function add(address callee, bytes4 selector) external;

    function remove(address callee, bytes4 selector) external;
}

// SPDX-License-Identifier: MIT

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