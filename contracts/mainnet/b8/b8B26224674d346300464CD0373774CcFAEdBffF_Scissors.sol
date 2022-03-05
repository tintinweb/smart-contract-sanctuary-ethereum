/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// Part: OpenZeppelin/[email protected]/Address

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/Counters

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// Part: OpenZeppelin/[email protected]/IAccessControl

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// Part: OpenZeppelin/[email protected]/IERC165

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Part: OpenZeppelin/[email protected]/IERC721Receiver

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// Part: OpenZeppelin/[email protected]/ReentrancyGuard

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// Part: OpenZeppelin/[email protected]/Strings

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// Part: OpenZeppelin/[email protected]/ERC165

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// Part: OpenZeppelin/[email protected]/IERC721

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// Part: OpenZeppelin/[email protected]/Ownable

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

// Part: OpenZeppelin/[email protected]/Pausable

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// Part: OpenZeppelin/[email protected]/AccessControl

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// Part: OpenZeppelin/[email protected]/Escrow

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// Part: OpenZeppelin/[email protected]/IERC721Enumerable

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// Part: OpenZeppelin/[email protected]/IERC721Metadata

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// Part: OpenZeppelin/[email protected]/ERC721

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// Part: OpenZeppelin/[email protected]/PullPayment

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
}

// Part: OpenZeppelin/[email protected]/ERC721Burnable

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// Part: OpenZeppelin/[email protected]/ERC721Enumerable

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// Part: OpenZeppelin/[email protected]/ERC721URIStorage

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// Part: RPSCollectible

/// @title Scissors Contract.
/// Contract by RpsNft_Art
/// Contract created by: (SHA-256) d735dfa8fa552fcb02c42894edebb4652d44697d1636b6125d2367caf2ade334
abstract contract RPSCollectible is ERC721,
                                    ERC721URIStorage,
                                    ERC721Enumerable,
                                    ERC721Burnable,
                                    Ownable,
                                    Pausable,
                                    AccessControl,
                                    PullPayment,
                                    ReentrancyGuard {

    // Events Declaration    
    event preSales(bool on_off);
    event preSalesCompleted();
    event baseURIChanged(string _baseURI);
    event maxPreSalesReached(uint256 _maxPresales);
    event maxWhiteListReached(uint256 _maxWhiteList);   
    event maxPublicSalesReached(uint256 _maxDrop);


    // Usings
    using Counters for Counters.Counter;
    using Address for address; // isContract()
    using Strings for uint256; // toString()

    // Counters
    Counters.Counter internal _tokenIdCounter;
    Counters.Counter internal _presalesCounter;

    // Keep track of per-wallet minting amounts during pre-sales
    mapping(address => uint256) internal _preSalesMinted;

    // Keep track of per-wallet minting amounts for white lists
    mapping(address => uint256) internal _whiteListMinted;

    // WhiteList controls
    uint256 private wlAllocatedAmount = 0;
    bool private wlAllocated = false;

    string internal _baseTokenURI;
    uint256 internal maxDrop;// = eg. 10000;
    uint256 internal preSalesMintPrice; // = In Weis e.g 55000000000000000;
    uint256 internal mintPrice; // = In Weis e.g. 75000000000000000;
    uint256 internal maxPresales; // = e.g 3000
    uint256 internal maxPresalesNFTAmount; // = e.g 2
    uint256 internal maxWhiteListNFTAmount; // = e.g 5
    uint256 internal maxSalesNFTAmount; // e.g 25
    uint256 internal maxWhiteListAmount; // e.g 150; 

    bool internal _inPresalesMode = false;
    bool internal _preSalesFinished = false;
    bool internal _publicSalesFinished = false;

    // List Roles
    bytes32 public constant PRESALES_ROLE = keccak256("RPS_PRESALES");
    bytes32 public constant WHITELIST_ROLE = keccak256("RPS_WHITELIST");
    
    /**
     *
     * Constructor : Owner created
     *
     */ 
    constructor(string memory _name, string memory _symbol)         
        ERC721(_name,_symbol)
        AccessControl() { // super constructors
         
        require(!(msg.sender.isContract())); // dev: The address is not an account

        // set initial flags as false 

        //  (not in presales, presales not finished and public sales not finished)
        _inPresalesMode = false;
        _preSalesFinished = false;
        _publicSalesFinished = false;

        // do not allow minting to begin with
        preSalesOff();
        pause();
        
        // msg.sender (owner) is the root and admin
        _presalesCounter.reset();
        _tokenIdCounter.reset();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Init white list
        wlAllocatedAmount = 0;
        wlAllocated = false;
    }

    /** ---- ANYONE CAN CALL, SOME EXTERNAL ONLY ---- */
    
    /**
     * Returns number of white list allocated 
     */
    function getWlAllocatedAmount() public view returns(uint256) {
        return(wlAllocatedAmount);
    }

    /**
     *
     * Returns whether or not the contract is in preSales mode 
     *
     */ 
    function inPresales() public view returns(bool) {
        return (_inPresalesMode && !_preSalesFinished);
    }

    /**
     *
     * Returns whether or not the contract is in public Sales mode
     *
     */
    function inPublicSales() public view returns(bool) {
        return _preSalesFinished && !paused() && !_publicSalesFinished;
    }

    /**
     *
     * Returns whether or not preSales has finished
     *
     */
    function preSalesFinished() public view returns(bool) {
        return _preSalesFinished;
    }


    /**
     *
     * Returns whether or not public Sales has finished
     *
     */
    function publicSalesFinished() public view returns(bool) {
        return _publicSalesFinished;
    }

    /**
     *
     * Returns whether or not an address is in the presales list
     *
     */
    function AddrInPresales(address _account) public view returns (bool){
        return _inPresalesMode && 
              !_preSalesFinished && hasRole(PRESALES_ROLE,_account) && 
              (_preSalesMinted[_account]) < maxPresalesNFTAmount;
    }

    /**
     *
     * Returns whether or not an address is in the white list
     *
     */
    function AddrInWhiteList(address _account) public view returns (bool){
        return hasRole(WHITELIST_ROLE,_account) && 
              (_whiteListMinted[_account]) < maxWhiteListNFTAmount;
    }

    /**
     *
     * Returns whether or not caller function is in the presales list
     *
     */
    function AmIinPresales() external view returns (bool) {
        return AddrInPresales(msg.sender);
    }

    /**
     *
     * Returns max drop 
     *
     */
    function getMaxDrop() external view returns(uint256) {
        return maxDrop;
    }

    /**
     *
     * Returns tokenURI for the provider token id
     *
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId)); // dev: ERC721Metadata, URI query for nonexistent token

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }     

   /**
     *
     * Payable mint during pre-sales
     *
     */
    function preSalesMint(uint256 amount) public payable onlyRole(PRESALES_ROLE) {
        require(!(msg.sender.isContract())); // dev: The address is not an account
        require(totalSupply() + amount <= maxPresales); // dev: Pre-sales SOLD-OUT
        require(!_preSalesFinished || msg.sender == owner()); // dev: Pre-sales has already finished
        require(_inPresalesMode || msg.sender == owner()); // dev: Pre-sales has not started yet
        require(!paused() || msg.sender == owner()); // dev: Minting is paused        
        require(msg.value == preSalesMintPrice*amount || msg.sender == owner()); // dev: Wrong price provided
        require(hasRole(PRESALES_ROLE, msg.sender) || msg.sender == owner()); // dev: Wallet not elligible
        require(amount <= maxPresalesNFTAmount); // dev: Cannot mint the specified amount in pre-sales
        require((_preSalesMinted[msg.sender] + amount) <= maxPresalesNFTAmount); // dev: Total pre-sales amount exceeded for wallet

        // Mint the amount of tokens!
        _coreMint(amount);

        // this was the last pre-sales minting based on the max presales allowed
        if(totalSupply() == maxPresales) {
            _preSalesFinished = true;
            _inPresalesMode = false;

            emit maxPreSalesReached(maxPresales);
        }

        // Keep track of wallet's pre-mint amount
        _preSalesMinted[msg.sender] += amount;
    }

    /**
     * To allow owners to reserve some collectibles at the begginning
     */
    function initialMint(uint256 amount) external onlyOwner {                        
        require(msg.sender == owner()); // dev: not owner              
        require(!(msg.sender.isContract())); // dev: The address is not an account                                
        require(!wlAllocated); // dev: initial amount already allocated        
        require((wlAllocatedAmount + amount) <= maxWhiteListAmount); // dev: the initial amount is exceeded
        require((totalSupply() + amount) <= maxDrop); // dev: SOLD OUT!
        
        // Mint the amount!
        _coreMint(amount);

        wlAllocatedAmount += amount;
        
        if(wlAllocatedAmount == maxWhiteListAmount) {
            wlAllocated = true;
            
            emit maxWhiteListReached(maxWhiteListAmount);
        }
    }

    /**
     *
     * Not Payable mint
     *
     */
    function whiteListMint(uint256 amount) public onlyRole(WHITELIST_ROLE) {
        require(!wlAllocated); // dev: initial amount already allocated
        require(!(msg.sender.isContract())); // dev: The address is not an account
        require((wlAllocatedAmount + amount) <= maxWhiteListAmount); // dev: the initial amount is exceeded                        
        require(hasRole(WHITELIST_ROLE, msg.sender) || msg.sender == owner()); // dev: Wallet not elligible        
        require(totalSupply() + amount <= maxDrop); // dev: SOLD OUT!
        require((_whiteListMinted[msg.sender] + amount) <= maxWhiteListNFTAmount); // dev: Total amount exceeded for white-listed wallet

        // Mint the amount of tokens!
        _coreMint(amount);

        wlAllocatedAmount += amount;
        
        if(wlAllocatedAmount >= maxWhiteListAmount) {
            wlAllocated = true;
            
            emit maxWhiteListReached(maxWhiteListAmount);
        }
        
        // Keep track of wallet's white list amount
        _whiteListMinted[msg.sender] += amount;
    }

    /**
     *
     * Payable Public Sales mint version
     *
     */
    function mint(uint256 amount) public payable {
        require(!(msg.sender.isContract())); // dev: The address is not an account
        require(_preSalesFinished || msg.sender == owner()); // dev: Pre-sales has not finished yet
        require(!paused() || msg.sender == owner()); // dev: Minting is paused        
        require(msg.value == mintPrice*amount || msg.sender == owner()); // dev: Wrong price provided
        require(totalSupply() + amount <= maxDrop); // dev: SOLD OUT!
        require(amount <= maxSalesNFTAmount); // dev: Specified amount exceeds per-wallet maximum mint

        // Mint the amount!
        _coreMint(amount);

        // this was the last pre-sales minting based on the max presales allowed
        if(totalSupply() == maxDrop) {
           _publicSalesFinished = true;
           emit maxPublicSalesReached(maxDrop);
        }

        // Reserve in TH as per Roadmap
        _accumulateTH();
    }

    /** ---------- ONLY OWNER CAN CALL EXTERNALLY ------------ */
    
    /**
     *
     *  Change baseURI
     * 
     */ 
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit baseURIChanged(_baseTokenURI);
    }    

    /**
     *
     * External function to allow to provide a list of addresses to be white listed 
     * 
     */
    function addToWhiteList(address[] memory whiteListAddr) external onlyOwner {        
        uint256 numAddrs = whiteListAddr.length;

        for(uint256 i=0;i<numAddrs;i++) {
            addToWhiteList(whiteListAddr[i]);
        }
    }

    /**
     *
     * External function to allow to provide a list of addresses to be white listed 
     * fo presales
     *
     */
    function addToPresalesList(address[] memory presalesAddr) external onlyOwner {
        require(!_preSalesFinished); // dev: Pre-sales period has already finished
        uint256 numAddrs = presalesAddr.length;

        for(uint256 i=0;i<numAddrs;i++) {
            addToPresalesList(presalesAddr[i]);
        }
    }


    /** ---------- ONLY OWNER CAN CALL, EVERYWHERE ------------ */

    /**
     *
     * Allow to pause minting
     *
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     *
     * Allow to unpause minting
     * 
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     *
     * Allow to enable or disable pre-sales
     *
     */
    function preSalesOn() public onlyOwner {
        _inPresalesMode = true;
        _preSalesFinished = false;
        emit preSales(_inPresalesMode);
    }

    /**
     * 
     * Stop presales
     *
     */
    function preSalesOff() public onlyOwner {
        _inPresalesMode = false;
        emit preSales(_inPresalesMode);
    }

    /**
     *
     * Complete preSales
     *
     */
    function preSalesComplete() public onlyOwner {
        _preSalesFinished = true;
        preSalesOff();
        pause();

        emit preSalesCompleted();
    }

    /** ------- INTERNAL CALLS ONLY, SOME ONLY BY OWNER -------- */
    
    /**
     *
     *  Returns baseURI for tokens
     * 
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     *
     * Internal: adds the individual provided wallet to the white list list
     *
     */
    function addToWhiteList(address whiteListAddr) internal onlyOwner {
        require(!whiteListAddr.isContract()); // dev: The address is not an account
        require(!hasRole(WHITELIST_ROLE, whiteListAddr)); // dev: Already in list
                
        grantRole(WHITELIST_ROLE,whiteListAddr);        
    }
 
    /**
     *
     * Internal: adds the individual provided wallet to the presales list
     *
     */
    function addToPresalesList(address presalesAddr) internal onlyOwner {
        require(!presalesAddr.isContract()); // dev: The address is not an account
        require(_presalesCounter.current() < maxPresales); // dev: Maximum number of presales reached
        require(!hasRole(PRESALES_ROLE, presalesAddr)); // dev: Already in list
        require(!_preSalesFinished);    // dev: Pre-sales period has already finished
        
        grantRole(PRESALES_ROLE,presalesAddr);
        _presalesCounter.increment();
    }
 
    /**
     *
     * Internal mint function 
     *
     */
    function _coreMint(uint256 amount) internal {
        uint256 tokenId;

        for(uint256 i = 0; i < amount; i++) {
            // Generate new tokenId
            _tokenIdCounter.increment();
            tokenId = _tokenIdCounter.current();    
            
            // mint the tokenId for caller 
            _safeMint(msg.sender, tokenId);
        }
    }

    /** ------- OVERRIDES NEEDED BY SOLIDITY  -------- */

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        require(maxDrop>0); // dev: cannot burn more
        maxDrop = maxDrop-1;
        super._burn(tokenId);
    }

    /** ------- VIRTUAL FUNCTIONS  -------- */
    function emitMintEvent(uint256 number) internal virtual;
    function _accumulateTH() internal virtual;

    /** ------- HELPER FUNCTIONS DURING UNIT TEST, ONLY BY OWNER -------- */
    function setMaxDrop(uint256 _maxPresales,uint256 _maxDrop,uint256 _maxWhiteListAmount) public onlyOwner {
        require(_maxWhiteListAmount <= _maxDrop); // dev: max presales cannot be greater than maxDrop
        require((_maxWhiteListAmount + _maxPresales) <= _maxDrop); // dev: whitelist and presales sum more than maxdrop
        require(_maxDrop >= totalSupply()); // dev: cannot set maxDrop below already supply
        require(_maxPresales <= _maxDrop); // dev: max presales cannot be greater than maxDrop
                
        maxDrop = _maxDrop;
        maxPresales = _maxPresales;
        maxWhiteListAmount = _maxWhiteListAmount;

        _accumulateTH();
    }

    function setMaxDrop(uint256 _maxDrop) public onlyOwner {
        require(_maxDrop >= totalSupply()); // dev: cannot set maxDrop below already supply

        maxDrop = _maxDrop;
        _accumulateTH();
    }

    function setMaxSalesNFTAmount(uint256 _maxSalesNFTAmount) public onlyOwner {
        maxSalesNFTAmount = _maxSalesNFTAmount;
    }

    function setMaxWhiteListAmount(uint256 _maxWhiteListAmount) public onlyOwner {
        maxWhiteListAmount = _maxWhiteListAmount;
    }

    /**
     * Prizes related
     */

    // To avoid reentrancy
    function withdrawPayments(address payable payee) public override nonReentrant whenNotPaused {
        super.withdrawPayments(payee);
    }

    function sendGiveAway(uint256 _giveAwayId, address[] memory _winners) external onlyOwner virtual whenNotPaused {        
    }
        
    /** Semi-random function to allow selection of winner for giveaways*/
    function rand(uint256 div) public view returns(uint256) {
 
       uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return (seed - ((seed / div) * div));
    }

}

// File: Scissors.sol

//                                                                                
//                                     .,,,,,,,,,,,,,,,,,,,,,                     
//                    ,,,,,,,,,,,,,,,,,,,,.                .,,,,                  
//                  ,,,,                                      ,,,                 
//                ,,,,      (((((       ,    ,     ((    ((    ,,                 
//               ,,,      ((((/((((    ,,,,,,,,   ((((  (((    ,,,
//                ,,.    ((((   (((.     ,,,,     ,((((((     ,,,              
//                ,,.    ((((   (((.    ,,,,,,     ,((((((     ,,,                
//                ,,,     (((((((((   .,,,  ,,,      ((((      ,,,                
//                ,,,                                           ,,,               
//                .,,    @@@@@@@@@    @@@@@@@@@    @@@@@@@@     ,,,               
//                 ,,,   @@      @@   @@      @@  @@            ,,,
//                 ,,,   @@      @    @@      @@    @@@         ,,,   
//                 ,,,   @@@@@@@@@    @@@@@@@@@       @@@@@     ,,,
//                 ,,,   @@      @    @@                @@@     ,,,              
//                 ,,,   @@      @@   @@          @@@@@@@@@    ,,,.               
//                  ,,,                                      ,,,,                 
//                   ,,,,.               ,,,,,,,,,,,,,,,,,,,,,,                   
//                      ,,,,,,,,,,,,,,,,,,,,.                                     
//                                                                                
//                                                                                

/// @title Scissors Contract.
/// Contract by RpsNft_Art
/// Contract created by: (SHA-256) d735dfa8fa552fcb02c42894edebb4652d44697d1636b6125d2367caf2ade334
contract Scissors is RPSCollectible {
   
    // List of public ETH addresses of RPSNft_Art cofounders and other related participants
    address private NGOAddress            = 0x633b7218644b83D57d90e7299039ebAb19698e9C; // UkraineDAO 
    address private ScissorsSisterAddress = 0x92dd828AF04277f1ae6A4b7B25b5fFfc69f3A677;
    address private RockbiosaAddress      = 0x521A4b1A8A968A232ca2BeCfF66713b209Bca2d7;
    address private PaperJamAddress       = 0x57032e15279f520cb98365138533793dfA32d214;
    address private RoseLizardAddress     = 0x502f9198E63D1EEa55C8Bd62e134d8c04CB66B73;
    address private SpockAddress          = 0xBF2117339eD7A9039D9B996a61876150DDcc6b37;
    address private MarketingAddress      = 0x09870346A435E6Eb14887742824BBC7dAd066776;
    address private FirstPrizeAddress     = 0xD0f5C2aD5abA241A18D8E95e761982D911Ed1B20;    
    address private DreamOnAddress        = 0xFfFaBC56a346929f925ddF2dEEc86332CC1Ce437;

    // Token Ids that will determine the VIPs (using ownerof)
    uint256 [] private VIPTokens;
    bool private VIPTokensSet=false;

    // Events for NFT
    event CreateScissors(uint256 indexed id);
    event ReleaseTH(uint256 indexed _pct, uint256 _amount);
    event AmountWithdrawn(address _target, uint256 _amount);
 
    // Events for Prizes
    event FirstGiveAwayCharged();
    event SecondGiveAwayCharged(address[]);
    event ThirdGiveAwayCharged(string _teamName,address[]);    

    // Number of MAX_VIP_TOKENS
    uint256 public constant MAX_VIP_TOKENS = 20;

    // ETHs to acummulate in Treasure Hunt account
    uint256 public constant TH_POOL =            50000000000000000000; // 50 ETH
    uint256 public constant TH_FIRST =            5000000000000000000; // 5 ETH
    uint256 public constant TH_SECOND =          10000000000000000000; // 10 ETH
    uint256 public constant TH_THIRD =           15000000000000000000; // 15 ETH
    uint256 public constant TH_FOURTH =          20000000000000000000; // 20 ETH

    // PCT distributions
    uint256 public constant COFOUNDER_PCT   = 16; // 16 PCT
    uint256 public constant FIVE_PCT        = 5;  // 5 PCT

    // Prizes    
    uint256 public constant TH_PRIZE_PER_WALLET = 5000000000000000000; // 5 ETH

    uint256 public constant FIRST_PRIZE = 1;
    uint256 public constant SECOND_PRIZE = 2;
    uint256 public constant THIRD_PRIZE = 3;

    uint256 public constant FIRST_PRIZE_TOTAL_ETH_AMOUNT =  4000000000000000000;  // 4 ETH
    uint256 public constant FIRST_PRIZE_FIRST_ETH_AMOUNT =  2500000000000000000;  // 2.5 ETH
    uint256 public constant FIRST_PRIZE_SECOND_ETH_AMOUNT = 1000000000000000000;  // 1 ETH
    uint256 public constant FIRST_PRIZE_THIRD_ETH_AMOUNT =   500000000000000000;  // 0.5 ETH

    uint256 public constant SECOND_PRIZE_TOTAL_ETH_AMOUNT =  5000000000000000000;  // 5 ETH
    uint256 public constant SECOND_PRIZE_PER_WALLET_ETH_AMOUNT = 250000000000000000;  // 0.25 ETH
   
    uint256 public constant TH_SECOND_PRIZE_MAX_WINNERS = 20;
    uint256 public constant TH_THIRD_PRIZE_MAX_WINNERS = 10;

    // track if prizes have been released
    bool public first_prize_released = false;
    bool public second_prize_released = false;
    bool public third_prize_released = false;
        
    // Store the TH Secret - Winner will provide the team 50 ETH
    uint256 private accumulatedTHPrize = 0;
    bytes32 private th_secret = 0x0;
    bool private th_secret_set = false;

    // Usings
    using Address for address;
    
    // Keep track of percentages achieved and accumulation for TH accomplished 
    bool _allocatedTH_25 = false;
    bool _allocatedTH_50 = false;
    bool _allocatedTH_75 = false;
    bool _allocatedTH_100 = false;
    
    // table for 2nd prize winners
    address[] public second_prize_winners;

    // mapping to register potential 3rd prize winners. Each array of tokenids must be 
    // max of TH_THIRD_PRIZE_MAX_WINNERS. Address index is who represents a given group and who calls 
    // payable function to register group
    mapping(string => address[]) public third_prize_players;

    // keep track of team where addresses are registered against
    mapping(address => string) public registered_th_addresses;

    string public th_team_winner = '';

    /**
     *  RPS = Rock Paper Scissors
     *  MWSA = Mintable Scissors Art
     */    
    constructor() RPSCollectible("RPS Scissors", "MSA") {
        require(!(msg.sender.isContract())); // dev: The address is not an account

        // So far, to get the metadata from web but soon replace from
        // pre-loaded IPFS
        
        //_baseTokenURI = "ipfs://QmT9Qb3tQfvKC1bnXPqGo5UnBgdU2WK4kq5SzVo4zPcWig/";
        maxDrop = 10000;
        
        VIPTokensSet = false;

        preSalesMintPrice       = 55000000000000000; // 0.055 ETH
        mintPrice               = 70000000000000000; // 0.070 ETH
        maxPresales             = 3500; // 1750 (250+1500) Max accts, each 2 max so max 3500 NFTs
        maxPresalesNFTAmount    = 2; // Max number of NFTs per wallet to mint during pre-sales
        maxWhiteListNFTAmount   = 2; // Max number of NFTs per wallet to mint per whitelisted account
        maxSalesNFTAmount       = 25; // Max number of NFTs per wallet to mint during sales (no other control per account)
        maxWhiteListAmount      = 150; // Max allowance for whitelisted tokens (including contract owners)

        accumulatedTHPrize = 0;  // to keep track of accumulated TH balance as per roadmap
        th_secret_set = false;   // to be set when secret is resolved
    }

    /** ---- ANYONE CAN CALL, SOME EXTERNAL ONLY ---- */
   
    /***
     * 
     *  Maximum balance that can be withdrawn to secure future prices
     *
     */
    function maxBalanceToWithdraw() public view returns(uint256) {
        uint256 balance = address(this).balance;
        int256 max_balance = int256(balance);
        
        // Do not transfer TH pool and prizes part
        if(!_allocatedTH_25) {
            // 25% has not been reached so do not allow to withdraw that part 
            max_balance = max_balance - int256 (TH_FIRST) - int256(FIRST_PRIZE_TOTAL_ETH_AMOUNT);
        } else if(!_allocatedTH_50) {
            // 50% has not been reached so do not allow to withdraw the TH part (5+10) and 1st prize
            max_balance = max_balance - int256 (accumulatedTHPrize + TH_SECOND) - int256(FIRST_PRIZE_TOTAL_ETH_AMOUNT);
        } else if(!_allocatedTH_75) {
            // 75% has not been reached so do not allow to withdraw the TH part (5+10+15) and 2nd prize
            max_balance = max_balance - int256 (accumulatedTHPrize + TH_THIRD) - int256(SECOND_PRIZE_TOTAL_ETH_AMOUNT);
        } else if(!_allocatedTH_100 || !third_prize_released) {
            //    100% has not been reached, do not allow to release the TH_POOL
            // OR 
            //    100% reached BUT TH_POOL has not been released yet, do not allow to withdraw it
            max_balance = max_balance - int256 (TH_POOL); 
        }             

        // if max_balance is positive after ensuring Treasure Hunt 
        // payments, then we can distribute 
        if(max_balance > 0) {
            balance = uint256(max_balance);
        } else {
            balance = 0;
        }

        return balance;
    }

    /**
     *
     * Charging the contract for test purposes: it is just fine by calling this empty payable method 
     *
     */
    function chargeContract() external payable {
    }

    /** ---------- ONLY OWNER CAN CALL ------------ */

    /**
     *
     * Allow to withdraw the accumulated balance among founders, always prioritizing 
     * Treasure Hunt payments
     *
     */
    function withdraw() external onlyOwner {
        require(VIPTokensSet); // dev: VIP tokens unknown

        // Keep amount for prizes
        uint256 balance = maxBalanceToWithdraw();

        require(balance > 0);  // dev: nothing to withdraw after securing prizes

        // Calc stakes from max to withdraw 
        // Solidity missing floats -> first mul then div
        uint256 cofounder_stk = (balance*COFOUNDER_PCT)/100;  // Co-founders
        uint256 VIP_stk = cofounder_stk / VIPTokens.length;   // VIPs participation

        // Early investor pct, NGO steak, For future marketing campaings, Participation of Dream On
        uint256 five_pct = (balance*FIVE_PCT)/100;     
                      
        // Transfer for founders
        transferFounders(cofounder_stk);

        // Transfer to VIPs
        transferVIPs(VIP_stk);

        // Transfer to believer
        payable(SpockAddress).transfer(five_pct);
        emit AmountWithdrawn(SpockAddress, five_pct);

        // Transfer to dream_on
        payable(DreamOnAddress).transfer(five_pct);
        emit AmountWithdrawn(DreamOnAddress, five_pct);

        // Transfer to NGO
        payable(NGOAddress).transfer(five_pct);
        emit AmountWithdrawn(NGOAddress, five_pct);

        // Pool for new marketing investment
        payable(MarketingAddress).transfer(five_pct);
        emit AmountWithdrawn(MarketingAddress, five_pct);
    }

    /**
     *
     * Sets the tokens for cofounding benefits
     * 
     */
    function setVIPTokens(uint256 [] memory _tokens) external onlyOwner {
        uint256 len = _tokens.length;
        require(len > 0); // dev: no tokens of VIPs provided 
        require(len <= MAX_VIP_TOKENS); // dev: max number of VIPs is 20  

        VIPTokens = new uint256[](_tokens.length);
        
        for(uint256 i=0;i < len;i++) {
            VIPTokens[i] = _tokens[i];
        }

        VIPTokensSet = true;
    }

    /**
     * 
     * Allow changing addresses for cofounders
     *
     */ 
    function setFounderAddresses(address _ss, address _rb, address _pj, address _rl,address _sp,
                                 address _ngo, address _ds, address _do) external onlyOwner {
        ScissorsSisterAddress = _ss;
        RockbiosaAddress = _rb;
        PaperJamAddress = _pj;   
        RoseLizardAddress = _rl;
        SpockAddress = _sp;
        NGOAddress = _ngo;
        MarketingAddress = _ds;
        DreamOnAddress = _do;
    }

    /**
     * Set First and Second Prize addresses
     */
    function setPrizesAccounts(address _first) external onlyOwner {
        require(!_first.isContract()); // dev: the address is not an account
        
        FirstPrizeAddress = _first;        
    }

    /** ---------- INTERNAL FUNCTIONS, SOME ONLY OWNER ------------ */

    /**
     *
     * Specific event created when Scissor mints
     *
     */
    function emitMintEvent(uint256 collectibleId) internal override {
        emit CreateScissors(collectibleId);
    }   

    /**
     *
     * Function that is called per every mint and allocates treasure hunt
     * as per roadmap
     *
     * It also accumulates for 1st and 2nd prize
     *
     */
    function _accumulateTH() internal override {
        
        // Everything already allocated in TH
        if(_allocatedTH_100)
            return;

        // Transfer amount of ETHs as per roadmap to TreasureHunt account (25%)
        if(!_allocatedTH_25 && pctReached(25) && address(this).balance>TH_FIRST) {                        
            _allocatedTH_25 = true;
            accumulatedTHPrize += TH_FIRST;
            emit ReleaseTH(25, TH_FIRST);
        }

        // Transfer amount of ETHs as per roadmap to TreasureHunt account (50%)
        if(!_allocatedTH_50 && pctReached(50) && address(this).balance>(TH_SECOND + FIRST_PRIZE_TOTAL_ETH_AMOUNT)) {            
            payable(FirstPrizeAddress).transfer(FIRST_PRIZE_TOTAL_ETH_AMOUNT);  // Transfer 1st prize
            
            _allocatedTH_50 = true;
            accumulatedTHPrize += TH_SECOND;
            emit ReleaseTH(50, TH_SECOND);
        }

        // Transfer amount of ETHs as per roadmap to TreasureHunt account (75%)
        if(!_allocatedTH_75 && pctReached(75) && address(this).balance>(TH_THIRD + SECOND_PRIZE_TOTAL_ETH_AMOUNT)) {            
            // send 2nd GiveAway to random owners
            _secondGiveAway();

            _allocatedTH_75 = true;
            
            // Accumulate for TH
            accumulatedTHPrize += TH_THIRD;
            emit ReleaseTH(75, TH_THIRD);
        }

        // Transfer amount of ETHs as per roadmap to TreasureHunt account (100%)
        if(!_allocatedTH_100 && pctReached(100) && address(this).balance>TH_FOURTH) {    
            _allocatedTH_100 = true;
            accumulatedTHPrize += TH_FOURTH;
            emit ReleaseTH(100,TH_FOURTH);
        }
    }

    /**
     *
     * Transfer for Founders
     *
     */
    function transferFounders(uint256 _amount) internal onlyOwner {

        // divide remainder among founders
        payable(RockbiosaAddress).transfer(_amount);
        emit AmountWithdrawn(RockbiosaAddress, _amount);

        payable(PaperJamAddress).transfer(_amount);
        emit AmountWithdrawn(PaperJamAddress, _amount);

        payable(ScissorsSisterAddress).transfer(_amount);
        emit AmountWithdrawn(ScissorsSisterAddress, _amount);

        payable(RoseLizardAddress).transfer(_amount);
        emit AmountWithdrawn(RoseLizardAddress, _amount);
    }

    /**
     *
     * Transfer for VIPs
     *
     */
    function transferVIPs(uint256 _amount) internal onlyOwner {
        require(VIPTokensSet); // dev: VIP tokens unknown
        
        // Pull payments of a 10th of the total for VIP
        // each VIP gets a pullpayment with proportional amount
        for(uint256 i=0;i < VIPTokens.length;i++) {
            // get the owner of the item to get payment
            address _ccfAddr = ownerOf(VIPTokens[i]);
            
            _asyncTransfer(_ccfAddr, _amount);             
            emit AmountWithdrawn(_ccfAddr, _amount);
        }
    }    

    /**
     * Prizes related functions
     */

    /**
     * Returns whether a given percentage has been reached or not
     */
    function pctReached(uint256 pct) public view returns(bool) {
        bool ret = false;
        
        if(pct == 25) {
            ret = (totalSupply()>=(maxDrop / 4));
        } else if(pct == 50) {            
            ret=(totalSupply()>=(maxDrop / 2));   
        } else if(pct == 75) {            
            ret=(totalSupply()>=((3*maxDrop) / 4));
        } else if(pct == 100) {
            ret=(totalSupply()>=(maxDrop));
        }

        return(ret);
    } 
    

    /**
     * Sets the TH secret up
     */
    function setSecret(bytes32 _secret) external onlyOwner {        
        th_secret = _secret;

        th_secret_set = true;
    }

    function reservedTHPrize() external view returns(uint256) {
        return accumulatedTHPrize;
    }

    function sendGiveAway(uint256 _giveAwayId, address[] memory _winners) public override onlyOwner {
        
        uint256[3] memory _prizes = [FIRST_PRIZE_FIRST_ETH_AMOUNT, // 2.5 ETH
                                     FIRST_PRIZE_SECOND_ETH_AMOUNT, //  1 ETH
                                     FIRST_PRIZE_THIRD_ETH_AMOUNT]; //0.5 ETH
        
        if(_giveAwayId == FIRST_PRIZE) {
            // send first GiveAway            
            _firstGiveAway(_winners,_prizes);
        }        
    }

    // Drop 1, once we have achieved 50% of the sales during first drop, 
    // the 3 community members from community members list, who have brought more new members 
    // to the community, will be rewarded with 2.5 ETH the first 1, 1 ETH the second, and 0.5 ETH the third.
    // Total: 4 ETH
    function _firstGiveAway(address[] memory _winners,uint256[3] memory _prizes) private onlyOwner {
        require(pctReached(50)); // dev: 50% not achieved yet
        require(!first_prize_released);  // dev: 1st prize already released 
        require(_winners.length <= 3);  // dev: winners array greater than 3 
        require(address(this).balance >= FIRST_PRIZE_TOTAL_ETH_AMOUNT); // dev: not enough balance in contract
                
        for(uint256 i=0;i<_winners.length;i++) {
            if(_winners[i] != address(0x0)) {                
                _asyncTransfer(_winners[i],_prizes[i]);  // 2.5 ETH, 1 ETH, 0.5 ETH
                    
                // Flag prize as released
                first_prize_released = true;
                emit FirstGiveAwayCharged();
            }    
        }                
    }

    // Drop 1, after 75% minting 5 ETH are transferred to 20 random scissors owners (pull payment, 0.5 ETH each)
    function _secondGiveAway() internal {
        require(!second_prize_released);  // dev: 2nd prize already released 
        require(pctReached(75)); // dev: 75% not achieved yet
        require(address(this).balance >= SECOND_PRIZE_PER_WALLET_ETH_AMOUNT); // dev: not enough balance in contract
        
        uint256 top_75_pct = (3*maxDrop)/4;  // calc the 75% of the maxDrop

        second_prize_winners = new address[](TH_SECOND_PRIZE_MAX_WINNERS);

        // Get 20 random tokenId numbers from 0...(maxDrop*3)/4
        uint256 div = top_75_pct / TH_SECOND_PRIZE_MAX_WINNERS;
        uint256 seed = rand(div) + 1;

        // Add payment in escrow contract
        for(uint256 i = 0; i < TH_SECOND_PRIZE_MAX_WINNERS; i++) {
            second_prize_winners[i] = ownerOf(seed);
            _asyncTransfer(second_prize_winners[i],SECOND_PRIZE_PER_WALLET_ETH_AMOUNT);
            seed = seed + div;
        }

        second_prize_released = true;
        emit SecondGiveAwayCharged(second_prize_winners);
    }
    
    /**
     * Returns the addresses of token owners (max of TH_THIRD_PRIZE_MAX_WINNERS)
     * internally called by owner of the tokens
     */
    function getAddressesFromTokens(uint256 [] memory _tokens) internal returns (address [] memory) {
            
            address [] memory ret = new address[](_tokens.length);

            for(uint256 i=0;i<_tokens.length;i++) {
                address _tokenOwner = ownerOf(_tokens[i]);
                require(msg.sender == _tokenOwner); // dev: caller is not the owner
                ret[i] = _tokenOwner;
            }

            return ret;
    }
        
    /**
     * Helper function to determine if one of the addresses is already registered in a team
     */
    function addressesNotRegisteredInTeamYet(address[] memory _addrs) internal returns (bool) {
        bool ret = true;

        for(uint256 i=0;i<_addrs.length;i++) {
            if(bytes(registered_th_addresses[_addrs[i]]).length != 0) { // Address already registered in a team
                ret = false;
                break;
            } 
        }

        return ret;
    }

    function addAddrToTeam(address _addr, string memory _teamName, uint256 _amount) internal returns(uint256) {

        registered_th_addresses[_addr] = _teamName;                                            
        
        return _amount + 1;
    }
    /**
     * Registers a new Team for TH prize
     * - caller of this function will provide list of tokens he/she owns to include his address 
     *   in this team and to create the team 
     * - caller of this function is free of charge (only gas) 
     * - Returns: number of shares in the team (max of TH_THIRD_PRIZE_MAX_WINNERS-1)
     */
    function registerTHTeam(string memory _teamName, uint256[] memory _tokensTeam) external returns(uint256) {
        require(_tokensTeam.length < TH_THIRD_PRIZE_MAX_WINNERS); // dev: tokens list size exceed maximum to create list
        require(third_prize_players[_teamName].length == 0); // dev: team name already taken
        uint256 ret = 0;

        // Get addresses for tokens provided to create this team
        address [] memory _addrs = getAddressesFromTokens(_tokensTeam); // Caller must but owner of the tokens or exception

        // if some address already registered in another team, exception
        require(addressesNotRegisteredInTeamYet(_addrs));

        // Flag address as registered under _teamName so it cannot be registered in another team
        for(uint256 i=0;i<_addrs.length;i++) {
            ret = addAddrToTeam(_addrs[i],_teamName,ret);                                                                    
        }

        // Finally, we can register the team
        third_prize_players[_teamName] = _addrs;

        return ret;
    }

    /**
     * Caller calls this function if he/she wants to join a TH team
     */
    function joinTHTeam(string memory _teamName, uint256[] memory _tokensTeam) external returns(uint256) {
        require(third_prize_players[_teamName].length != 0); // dev: team name does not exist
        require(third_prize_players[_teamName].length != TH_THIRD_PRIZE_MAX_WINNERS); // dev: team full

        uint256 ret = 0;

        // Get addresses for tokens provided to create this team
        // Caller must but owner of the tokens or exception
        address [] memory _addrs = getAddressesFromTokens(_tokensTeam); 

        // if some address already registered in another team, exception
        require(addressesNotRegisteredInTeamYet(_addrs)); // dev: caller not in a team yet
        
        for(uint256 i=0;i<_addrs.length;i++) {                   
            // if there still some room left, add new joiner
            if(third_prize_players[_teamName].length < TH_THIRD_PRIZE_MAX_WINNERS) {
                                                            
                // Finally, we can register the team
                third_prize_players[_teamName].push(_addrs[i]);
                
                ret = addAddrToTeam(_addrs[i],_teamName,ret);
            }
        }
        
        return ret;
    }

    /**
     * Function that registered users need to call to provide decrypted message _plaintext 
     * If text matches the encrypted message, TH prize will be distributed to owners of scissors 
     * registered in the team from the caller attending to their participation
     *     
     */
    function decryptForTHPrize(string memory _plaintext) external returns(bool) {                
        require(th_secret_set); // dev: secret not set
        require(pctReached(100)); // dev: 100% not achieved yet
        require(!third_prize_released);  // dev: 3rd prize already released         
        require(accumulatedTHPrize == TH_POOL); // dev: not enough balance in contract
        require(address(this).balance >= TH_POOL); // dev: not enough balance in contract
        require(bytes(registered_th_addresses[msg.sender]).length != 0); // dev: caller not registered in any team

        if(keccak256(abi.encodePacked(_plaintext)) == th_secret) {             
    
            // Secret message found, release prize to winners in team

            // Get the team name
            th_team_winner = registered_th_addresses[msg.sender];

            // Access the addresses list
            address [] memory _winnersAddrs = third_prize_players[th_team_winner];
                      
            // Congrats winners
            _charge3rdGiveAway(th_team_winner,_winnersAddrs);
            
            return true;
        } else {
            revert("RPS - Wrong, keep trying.");            
        }
        
        return false;
    }

    /**
     * Returns addresses of TH winners
     */
    function getTHWinnerAddrs() external view returns(address[] memory) {
        require(third_prize_released); // dev: TH prize not relased yet

        return third_prize_players[th_team_winner];
    }

    /**
     * Returns TH winner team name
     */
    function getTHTeamName() external view returns(string memory) {
        require(third_prize_released); // dev: TH prize not relased yet
        
        return th_team_winner;
    }

    // The 50 ETH accumulated in the treasure account will be equally distributed among the winner group
    // and the corresponding will be made available to them through pullpayment. 
    // Example if the group was formed by 10 people with 10 corresponding accounts, 
    // 5 ETH will be made available to them through pull payment.
    function _charge3rdGiveAway(string memory _teamName, address[] memory _winners) internal {        
                
        // We transfer amount in the contract and from the contract to payees 
        // using pullpayment method
        for(uint256 i=0;i<_winners.length;i++) {
            _asyncTransfer(_winners[i],TH_PRIZE_PER_WALLET); // 5 ETH per wallet
            accumulatedTHPrize -= TH_PRIZE_PER_WALLET;            
        }

        third_prize_released = true;

        emit ThirdGiveAwayCharged(_teamName,_winners);
    }


    /**
     * We will transfer any accumulated prize not provided to NGO account
     */
    function sendRemainderToNGO() external onlyOwner {
        require(third_prize_released && accumulatedTHPrize > 0); // dev: prizes not released yet or no remaining       

        // All prizes have been released, potential remainder to be sent to NGO
        uint256 amount = accumulatedTHPrize;

        payable(NGOAddress).transfer(amount);
        emit AmountWithdrawn(NGOAddress, amount);
    }
}