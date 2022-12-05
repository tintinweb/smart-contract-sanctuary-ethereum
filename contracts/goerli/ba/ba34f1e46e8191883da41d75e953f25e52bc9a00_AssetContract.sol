/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;


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
        _requireMinted(tokenId);

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
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



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

// File: TNFT-3.sol


pragma solidity ^0.8.4;








// @title - IAssetContract - interface for TNFT asset tying
interface IAssetContract /*,EIP165*/{

    // @dev enum values if the TNFT is place on either Martketplace or Rentplace
    enum tokenMarketPlaceStatus{
        notAnywhere,
        isOnMarketplace,
        isOnRentPlace
    }

    // Asset demption info
    struct redemptionInfo{
        uint256 tokenId;
        uint256 startDate;
        uint256 endDate;
    }

    // Asset user engagement states
    enum _assetUserState{
        waitingForUser,
        UserEngaged,
        userAuthenticated,
        UserRedeemAsset
    }

    // @dev This emits when the NFT is assigned as utility of a new user.
    //  This event emits when the user of the token changes.
    //  (`_addressUser` == 0) when no user is assigned.
    event UserAssigned(uint256 indexed tokenId, address indexed _addressUser,address _assignedBy);

    // @dev This emits when the NFT is assigned as utility of a new asset.
    //  This event emits when the asset of the token changes.
    //  (`_addressAsset` == 0) when no user is assigned.
    event AssetAssigned(uint256 indexed tokenId, address indexed _addressAsset);
    
    
    // @dev This event  emits when physical user authenticate that he belongs to that user address
    event UserAuthenticated(uint256 indexed tokenId);

   
    // @dev This emits when user redeemed the asset.
    // This event  emits when asset is physically redeemed.
    event UserRedeemedAsset(uint256 indexed tokenId,address userAddress);


    // @dev This emits when asset status is marked as burned and transfered to the burn wallet.
    event AssetBurned(uint256 indexed tokenId);

    // @dev This event emit when the asset user approved to other user
    event UserApproval(address indexed user, address indexed approved, uint256 indexed tokenId);

    // @dev This event emits when redemption date inforamtion updated
    event RedemptionInfoUpdated(uint256 indexed tokenId,uint256 indexed startDate, uint256 indexed endDate);

    
    
    // @notice this function is used by owner of this interface 
    // @dev this function will be initialized by NFT contract address.
    // @param _nftContract is the ERC721 contract address.
    function initNFTContract(address _nftContract)external; 

    // @notice this function is used by owner of this interface 
    // @dev this function will be initialized by Rent TNFT contract address.
    // @param rentTNFTContractAddress is the TNFT rent contract contract address.
    // @note rentTNFTContractAddress address should be intialzed to if asset needs to be gone on rent.
    function initRentTNFTContract(address rentTNFTContractAddress) external;

    // @notice this function is used by owner of this interface 
    // @dev this function will be set by Marketplace contract address.
    // @param marketContract is the Marketplace contract address.
    function initMarketContract(address marketContract) external;

    // @notice this function is used by owner of this interface 
    // @dev this function will be set by Rentplace contract address.
    // @param rentContract is the Rentplace contract address.
    function initRentplaceContract(address rentContract) external;


    function getRentTNFTContractAddress() external view returns(address);
    
    // @notice This function will be called only by the NFT contract
    // this function is used to add the assset address, user address at the NFT minting time.
    // If owner wants to add the asset address, user address at minting time
    // @param tokenId is the TNFT token id 
    // @param assetAddress is of the assigned utillity with NFT .
    // @param userAddress is of the assigned user with NFT .
    function afterMint(uint256 tokenId,address assetAddress,address userAddress) external;

    // @notice This function will be called by only the NFT contract
    // @dev this function is used to delete the NFT data from asset contract like asset address , token id  if NFT owner burn the TNFT
    // @param tokenId is the NFT token id .
    function afterBurn(uint256 tokenId)external;

    // @notice anyone can call this function
    // @dev this function is used to check whether an asset have an address or not
    // @param assetAddress is of the assigned utillity with NFT .
    // @return true is asset address exist
    function assetAddressExists(address assetAddress) external view returns (bool);

    // @notice anyone can call this function
    // @dev This function is used to check total tokens that are exist.
    // @return count of the total tokens
    function getTotaltokens() external view returns(uint256);


    // @notice This function defines how the NFT is assigned as utility of a new user (if "addressUser" is defined).
    // @dev Only the owner of the  NFT can assign a user or if the NFT is on sale , marketplace contract can also set the user .
    // If "addressAsset" is defined, then the state of the token must be
    // "waitingForUser" ,"engagedWithOwner","userAuthenticated" or "UserRedeemAsset" and this function changes the state of the token defined by "_tokenId" to
    // @param _tokenId is the tokenId of the ERC721 NFT tied to the asset.
    // @param _addressUser is the address of the new user.
    function setUser(uint256 _tokenId, address _addressUser) external ; 

    // @notice This function defines is used to define the asset(utility) address which is tied with NFT.
    // @dev only NFT Owner can call this function.
    // @param _tokenId is the tokenId of the ERC721 NFT tied to the asset.
    // @param _addressAsset is the address of the new asset.
    function setAssetAddress(uint256 _tokenId, address _addressAsset) external ; 
    
    
    
    // @notice This function lets obtain the tokenId from an address. 
    // @dev Everybody can call this function. The code executed only reads from Ethereum.
    // @param _addressAsset is the address to obtain the tokenId from it.
    // @return tokenId of the token tied to the asset that generates _addressAsset.
    function tokenFromBCA(address _addressAsset) external view returns (uint256);

    
    
    // @notice This function lets know the owner of the token from the address of the asset tied to the token.
    // @dev Everybody can call this function. The code executed only reads from Ethereum.
    // @param _addressAsset is the address to obtain the owner from it.
    // @return owner of the token bound to the asset that generates _addressAsset.
    function ownerOfFromBCA(address _addressAsset) external view returns (address);
    
    // @notice This function is used to get the token user by its tokenId.
    // @dev Everybody can call this function. The code executed only reads from Ethereum.
    // @param _tokenId is the tokenId of the EIP-4519 NFT tied to the asset.
    // @return user of the token from its _tokenId.
    function userOf(uint256 _tokenId) external view returns (address);
    
    // /// @notice This function is used to get the token user by the asset address 
    // /// @dev Everybody can call this function. The code executed only reads from Ethereum.
    // /// @param _addressAsset is the address to obtain the user from it.
    // /// @return user of the token tied to the asset that generates _addressAsset.
    function userOfFromBCA(address _addressAsset) external view returns (address);
    
    // /// @notice This function lets know how many tokens are assigned to a user.
    // /// @dev Everybody can call this function. The code executed only reads from Ethereum.
    // /// @param _addressUser is the address of the user.
    // /// @return number of tokens assigned to a user.
    function userBalanceOf(address _addressUser) external view returns (uint256);

    // @notice This function lets know tokens ids are assigned to a owner.
    // @dev Everybody can call this function. The code executed only reads from Ethereum.
    // @param owner is the address of the NFT owner.
    // @return array of tokens ids assigned to a owner.
    function getOwnerTokens(address owner) external view returns(uint256[] memory);


    // @notice This function lets know tokens ids are assigned to a user.
    // @dev Everybody can call this function. The code executed only reads from Ethereum.
    // @param user is the address of the user.
    // @return array of tokens ids assigned to a user.
    function getUserTokens(address _user) external view returns(uint256[] memory);
       
    
    // @notice This function lets know how many tokens of a particular owner are assigned to a user.
    // @dev Everybody can call this function. The code executed only reads from Ethereum.
    // @param _addressUser is the address of the user.
    // @param _addressOwner is the address of the owner.
    // @return number of tokens assigned to a user from an owner.
    function userBalanceOfAnOwner(address _addressUser, address _addressOwner) external view returns (uint256);

    // @notice This function is used when user verify own address identity by signing the message.
    // This function check whether the message is signed with  asset user. if message is verified a event .
    // if the message is successfully verified then asset state is changed to UserEngaged.
    // @event UserAuthenticated event emits
    // @param assetAdress is the address of the user.
    // @param _hashedMessage is the hash of the message.
    // @params _v,_r, _s are the splited part of the signature message
    function verifyAssetUser(address assetAdress,bytes32 _hashedMessage,bytes memory sig) external;

    // @notice this function lets know whether asset is redeeded or not
    // @param  tokenId  it is the NFT Id
    // return true if NFT/Asset is redeemed
    function isAssetRedeemed(uint256 tokenId) external view returns (bool);
    
    // @notice This function is called after when user received the Asset by POS system. 
    // @dev this function is called by NFT owner/creator.
    // NFT Owner before burning ensure asset status is userAuthenticated.
    function userBurnAsset(address assetAdress) external;


    // Marketplace/Rent place functions start here
    
    
    // @notice this function lets whether TNFT is listed on any Martketplace or Rentplace
    // @dev anybody can call this function
    // @param tokenId - it is TNFT token id
    // @return it return the enum values of tokenMarketPlaceStatus
    function getTokenMarketPlaceStatus(uint256 tokenId) external view returns (uint);

    // @notice this function is used to update the TokenMarketPlaceStatus
    // the aim of keeping this variable is to maintain the market place / rent place
    // @dev only the marke place contract or rent place contract can call this
    // @param tokenId - it is TNFT token id
    // @param status - it is enum value of tokenMarketPlaceStatus
    function updateTokenMarketPlaceStatus(uint256 tokenId,uint status) external;

    // Marketplace/Rent place functions end here
    
    //----------user approval functions start here-------------

    // @notice This function lets know any user is  approved by Asset user
    // @dev This function can be called by anyone
    // @param tokenId - it is TNFT token id
    // @param returns - it returns the approved user address
    function getUserApproved(uint256 tokenId) external view  returns (address);


    // @notice This function lets know any user is  approved by Asset user
    // @dev This function can be called by anyone
    // @param to - it is address of to user
    // @param tokenId - it is TNFT token id
    // @param returns - it returns the approved user address
    function approveUser(address to, uint256 tokenId) external;

    //----------user approval functions end here-------------


    //----------RENT  TNFT functions start here-------------

    // @notice this function lets know the rent user for a TNFT
    // @dev anybody can call this function
    // @param tokenId - it is TNFT token id
    // @return the rent user address if it  exist and it is not expired. if it is not exist 
    // if it is not exist it will return empty address
    function getRentUser(uint256 tokenId) external view returns(address);

    //----------RENT  TNFT functions end here-------------


    //----------redeption date functions start here-------------

    // @notice This function is to update the the TNFT redemption start date and end date
    // @dev This function should be called by TNFT Contract
    // @parm tokenId- It is the id of TNFT
    // @param _startDate - It the TNFT redemption start date . 
    // @param _endDate - It the TNFT redemption end date .
    function addRedeptionDate(uint256 tokenId ,uint256 _startDate, uint256 _endDate) external;

    // @notice This function lets know asset can be redeemed or not
    // @dev Any one can call this function
    // @param tokenId- It is the id of TNFT
    // @return true - if TNFT can be redeemed .
    function canAssetBeRedeeded(uint256 tokenId) external view returns(bool CanRedeem);

    // @notice This function lets know the full information about TNFT redemption date
    // @dev Any one can call this function
    // @param tokenId- It is the id of TNFT
    // @return redemptionInfo - it returns the struct of  TNFT redemption date.    
    function getTokenRedemptionInfo(uint256 tokenId) external view returns (redemptionInfo memory);

    //----------redeption date functions end here-------------

    // @notice this function to lets current contract address
    function contractAddress() external view returns (address);
}

// Interface for  giving the TNFT at rent
// @title - RentInterface - interface for TNFT to give on  renting
interface RentInterface {
    // @dev struct for renting the TNFT
    struct RentInfo 
    {
        uint256 tokenId;
        address user;   // address of user role
        uint256 expires; // unix timestamp, user expires
        uint256 startAt; //  rent perio startted at
        uint256 price; // total paid amount
        address rentowner; // payment reciever address
        bool isRedeemed;
    }

    // Asset user engagement states
    enum _assetRentUserState{
        RentUserEngaged,  // State change when rent user assigned with TNFT
        RentUserAuthenticated, // State change when rent user authenticated his/her identity
        RentUserRedeemAsset // State change when rent user redeemed the TNFT temperorly
    }

    // @dev This event emits when asset is rented
    event AssetRented(uint256 tokenId, address rentUser, uint256 expires,uint256 startedAt,uint256 price,address rentOwner);

    // @dev This even emits when subcription is updated
    event SubscriptionUpdate(uint256 indexed tokenId, uint256 expiration);

    event RentUserAuthenticated(uint256 tokenId);

    // @dev This emits when user redeemed the asset.
    // This event  emits when asset is physically redeemed.
    event UserRedeemedRentAsset(uint256 indexed tokenId,address userAddress);

     // @dev This event emit when the asset user approved to other user
    event RentUserApproval(address indexed user, address indexed approved, uint256 indexed tokenId);



    // @notice this function is used by owner of this interface 
    // @dev this function will be initialized by NFT contract address.It also intialized the Asset contract
    // @param _nftContract is the ERC721 contract address.
    function initNFTContract(address _nftContract)external; 

    
    // @notice this function is used by owner of this interface 
    // @dev this function will be set by Rentplace contract address.
    // @param rentContract is the Rentplace contract address.
    function initRentplaceContract(address rentContract) external;

    // @notice -This function is used to get rentplace contract address
    // @dev anyone can call this function
    // @return the rentplace contract address
    function getRentplaceContractAddress() external view returns(address);


    // @notice This function is used to add the rent owner for a TNFT. 
    // @dev Only Rent marketplace contract , ower or user can call this function
    // @param tokenId - it is TNFT token id
    // @param rentUser - Ethereum address of the user who takes it on rent
    // @param expires - it is rent expiry time
    // @param startedAt - it is rent starting at time
    // @param rentOwner - it is ehereum address of the rent owner (TNFT owner/ TNFT user who purchased it)
    function addRentUser(uint256 tokenId, address rentUser, uint256 expires,uint256 startedAt,uint256 price,address rentOwner)external;


    // @notice Renews the subscription to an NFT
    // Throws if `tokenId` is not a valid NFT
    // @param tokenId The NFT to renew the subscription for
    // @param duration The number of seconds to extend a subscription for
    function renewSubscription(uint256 tokenId, uint256 duration) external payable;

    /// @notice Cancels the subscription of an NFT
    /// @dev Throws if `tokenId` is not a valid NFT
    /// @param tokenId The NFT to cancel the subscription for
    function cancelSubscription(uint256 tokenId) external payable;

    // @notice this function lets know the rent user for a TNFT
    // @dev anybody can call this function
    // @param tokenId - it is TNFT token id
    // @return the rent user address if it  exist and it is not expired. if it is not exist 
    // if it is not exist it will return empty address
    function getRentUser(uint256 tokenId) external view returns(address);

    // @notice this lets know the user expiry time
    // @dev anybody can call this function
    // @param tokenId - it is TNFT token id
    // @return it return the rent user expiry time if rent user exist. 
    function userExpires(uint256 tokenId) external view  returns(uint256);

    // @notice this lets know the all attributes values regarding rent
    // @dev anybody can call this function
    // @param tokenId - it is TNFT token id
    // @return it return the RentInfo struct data. 
    function getRentInfo(uint256 tokenId)external view returns(RentInfo memory);

    // @notice this lets know the rent inforamations for all TNFTs
    // @dev anybody can call this function
    // @param active - if can be true or false
    // @return  if active==true , it will renturn only non expired  rent informations 
    // otherwise it will return   rent inforamations for all TNFTs
    function getAllRentInfo(bool active)external view returns(RentInfo [] memory);

    // @notice this function is used to split the signature into v,r,s
    // @param - Signature
    // @returns Signature in splited part v,r,s
    function splitSignature(bytes memory sig)
       external
       pure
       returns (uint8, bytes32, bytes32);
    
     // @notice This function is used when user verify own address identity by signing the message.
    // This function check whether the message is signed with  asset user. if message is verified ,A event RentUserAuthenticated emits.
    // if the message is successfully verified then asset state is changed to UserEngaged.
    // @event UserAuthenticated event emits
    // @param assetAdress is the address of the user.
    // @param _hashedMessage is the hash of the message.
    // @params sig is the signatured message
    function verifyAssetRentUser(uint256 tokenId,bytes32 _hashedMessage,bytes memory sig) external;

    // @notice this function lets know whether asset is redeeded or not
    // @param  tokenId  it is the NFT Id
    // return true if NFT/Asset is redeemed
    function isAssetRedeemed(uint256 tokenId) external view returns (bool);
    
    // @notice this function is used to mark as TNFT is temperorly redeedem.
    // rent user first approve the sytem to do this action. when user approve the system pay TNFT and update it in smart contract as redeemed
    // @dev - only the approved account or rent user self can use this function
    // @param tokenId -TNFT token id
    function rentUserRedeemAsset(uint256 tokenId) external;

    //----------user approval functions start here-------------

    // @notice This function lets know any user is  approved by Asset user
    // @dev This function can be called by anyone
    // @param tokenId - it is TNFT token id
    // @return - it returns the approved user address
    function getRentUserApproved(uint256 tokenId) external view  returns (address);


    // @notice This function is used to approve a user
    // @dev This function can be called by anyone
    // @param to - it is address of to user
    // @param tokenId - it is TNFT token id
    function approveRentUser(address to, uint256 tokenId) external;

    //----------user approval functions end here-------------
    
}


// Interface attribute customization
interface AssetCustomizationInterface {

    event  AttributesAdded(uint256 indexed tokenId);
    event  AttributeValueUpdated(uint256 indexed tokenId);
    event  AttributeValueDeleted(uint256 indexed tokenId);

    // @notice - This function is used to add the TNFT attributes
    // @dev - Only the TNFT owner can call this function
    // @param tokenId- It is the id of TNFT
    // @param traitType - It is the array of TNFT attributes names like Color, Height, Weight etc may be attributes.
    // @param traitValue -It is the array of TNFT attributes values.   
    function _addTokenAttributes(uint256 _tokenId, string [] memory  _traitType , string [] memory  _traitValue) external ;

    // @notice - This function is used to lets know TNFT attributes is exist or not
    // @dev any one can call this function
    // @param tokenId- It is the id of TNFT
    // @param traitType - It is the array of TNFT attributes names.
    // @returns true if attribute is exist
    function _attributeTraitTypeExists(uint256 _tokenId, string memory _traitType ) external view   returns (bool);

    // @notice - This function is used to let knows the count of TNFT attributes
    // @dev - Any one can call this function
    // @param tokenId- It is the id of TNFT 
    // @retun the count of attributes
    function _getTokenAttributeCount(uint256 _tokenId) external view returns(uint256);

    // @notice - This function is used to update the TNFT attribute value
    // @dev - This  function will be override in TNFT contract
    // @param tokenId- It is the id of TNFT
    // @param traitType- It is the TNFT attribute name
    // @param traitValue- It is the TNFT attribute value
    // @event AttributeValueUpdated emitted
    function _updateTokenAttributeValue(uint256 _tokenId, string memory _traitType,string memory _traitValue)external;

    // @notice - This function is used to delete the attribute the TNFT
    // @dev - This  function will be override in TNFT contract
    // @param tokenId- It is the id of TNFT
    // @param traitType- It is the TNFT attribute name 
    // @event AttributeValueDeleted emitted
    function deleteNFTAttribute(uint256 _tokenId,string memory _traitType) external;

    // @notice - This function let knows the TNFT attribute index in array
    // @dev- This is careted for intenal purpose and can also called anyone
    // @param tokenId- It is the id of TNFT
    // @param traitType- It is the TNFT attribute name 
    // return TNFT attribute index in array
    function getAttributeIndex(uint256 _tokenId, string memory _traitType)external view  returns(uint256);

    // @notice - This function is used to let knows the TNFT attribute value
    // @dev Any one can call this function
    // @param tokenId- It is the id of TNFT
    // @param traitType- It is the TNFT attribute name 
    // return TNFT attribute value 
    function getAttributeValue(uint256 _tokenId, string memory _traitType)external view  returns(string memory);
    
    // @notice - This function is used to let knows all TNFT attribute values
    // @dev - Any one can call this function
    // @param tokenId- It is the id of TNFT
    // @return the array of all TNFT attribute values
    function getAttributeValues(uint256 _tokenId)external view returns(string[] memory);

    // @notice - This function is used to let knows all TNFT attribute names
    // @dev - Any one can call this function
    // @param tokenId- It is the id of TNFT
    // @return the array of all TNFT attribute names
    function getAttributeTraitTypes(uint256 _tokenId)external view returns(string[] memory);
}


// @title interface for the market Item
interface MarketplaceInterface {
    
    // @dev struct to store market item details
    struct MarketItem {
        uint256 itemId; // marketplace item id
        address nftContract; // contract address of the NFT contract
        address assetContract; // contract address of the asset contract
        uint256 tokenId; // id of the token
        address payable seller; // address for seller or address that giving on rent
        address payable user; // value for purchaser address or rent user address
        uint256 price; // value for sale or per cycle rent price
        bool sold; // true if item is sold
        bool cancelled; // true item is  cancelled from market listing
        bool resale; // true if item is going resale
    }

    // @dev This emits new market item is created
    event MartketItemCreated(MarketItem _marketItem);

    // @dev This emits  market item is sold
    event MartketItemSold(MarketItem _marketItem);

    // @dev This emits canceled to sold
    event MartketItemCancelled(MarketItem _marketItem);

    //@dev This event emits when market place contract owner received the listing fees
    event ReceivedListingFees(address owner, uint256 price);

    // @notice The functions is used to get the listing price to sale on market
    // @dev Anybody  can call this function
    function getListingPrice() external view returns (uint256);

    // @notice The functions is used to add a NFT for market sale or An item can be resale
    // @dev This function can be called by the owner of NFT or user of NFT (User of the NFT : Referring Asset interface)
    // @param nftContract is contract address where NFT is created.
    // @param assetContract is contract address where NFT is asset and user details exist.
    // @param tokenId is the token id.
    // @param price is at which , item will be sold.
    // @return the market place Item id
    function createMarketItem(
        address nftContract, // NFT contract address
        address assetContract, // Asset contrcat address
        uint256 tokenId, // NFT token id
        uint256 price // Saling or Renting price
    ) external payable  returns(uint256);

    

    // @notice The functions is used to cancel a NFT for market sale. Returns the listing fees to seller.
    // @dev This function can be called by the seller of NFT
    // @param itemId is market place item id.
    function cancelMarketItem(uint256 itemId) external;

    // @notice The functions is used where any user can purchase the item. 
    // After purchase the price  will be transfered to seller account 
    // and listing fees will be transfered to owner of marketplace contract
    // @dev This function can be called by anyone
    // @param itemId is market place item id.
    function createMarketSale(
        uint256 itemId // Market place item id
    ) external payable;

    // @notice The functions is used to get the martket items which are for sale. 
    // @dev This function can be called by anyone
    // @return the market place Items list
    function fetchMarketItems() external view returns (MarketItem[] memory);

    // @notice The functions is used to get the martket items which are purchased by me. 
    // @dev This function can be called by buyer of NFTs
    // @return the market place Items list
    function fetchMyPurchasedNFTs() external view returns (MarketItem[] memory);
    

    // @notice The functions is used to get the martket items which are created by me. 
    // @dev This function can be called by seler of NFTs
    // @return the market place Items list
    function fetchItemsCreatedForSell() external view returns (MarketItem[] memory);
}

// @title interface for the Rent functions
interface RentplaceInterface {
    // @dev struct to store rent item details
    struct RentItem {
        uint256 itemId; // rentplace item id
        address nftContract; // contract address of the NFT contract
        address assetContract; // contract address of the asset contract
        uint256 tokenId; // id of the token
        address payable rentOwner; // address for seller or address that giving on rent
        address payable rentUser; // value for purchaser address or rent user address
        uint256 price; // value for sale or per cycle rent price
        bool cancelled; // true item is  cancelled from market listing
        bool rented; // true if item is gone on rent
        uint64 rentCycleTime; // hour value for rent expire
    }

    
    // @dev This emits rent item is created
    event RentItemCreated(RentItem _rentItem);

    // @dev This emits canceled to sold
    event RentItemCancelled(RentItem _rentItem);

    // @dev This emits  rent item is rented
    event MartketItemRented(RentItem _rentItem);

    //@dev This event emits when rent place contract owner received the listing fees
    event ReceivedListingFees(address owner, uint256 price);

    // @notice The functions is used to get the listing price to rent on market
    // @dev Anybody  can call this function
    function getRentListingPrice() external view returns (uint256);

    // @notice The functions is used to add a NFT for rent on rentplace
    // @dev This function can be called by the owner of NFT or user of NFT (User of the NFT : Referring Asset interface)
    // @param nftContract is contract address where NFT is created.
    // @param assetContract is contract address where NFT is asset and user details exist.
    // @param tokenId is the token id.
    // @param price is at which , item will be sold.
    // @param rentCycleTime is time in hour. It defines that price will be for rentCycleTime period
    // @return the market place Item id
    function createRentItem(
        address nftContract, // NFT contract address
        address assetContract, // Asset contrcat address
        uint256 tokenId, // NFT token id
        uint256 price, // Saling or Renting price
        uint64 rentCycleTime // hours value if item for rent
    ) external payable ;

    // @notice The functions is used to cancel a NFT for rent from Rentplace. Returns the listing fees to rentplace owner.
    // @dev This function can be called by the owner/user of NFT
    // @param itemId is market place item id.
    function cancelRentItem(uint256 itemId) external;

    // @notice The functions is used where any user can take the item on rent. 
    // After taking renting the price  will be transfered to rent owner account 
    // and listing fees will be transfered to owner of marketplace contract
    // @dev This function can be called by anyone
    // @param itemId is rent place item id.
    // @param rentCycleTime  - It is no. of cycles for which user wants to take it on rent
    function createMarketRent(
        uint256 itemId, // Market place item id
        uint256 rentCycleTime // 
    ) external payable;

    // @notice The functions is used to get the martket items which are for rent. 
    // @dev This function can be called by anyone
    // @return the rent place Items list
    function fetchRentItems() external view returns (RentItem[] memory);

    // @notice The functions is used to get the martket items which are taken on rent by me. 
    // @dev This function can be called by renter of NFTs
    // @return the market place Items list
    function fetchMyRentedNFTs() external view returns (RentItem[] memory);
    
    // @notice The functions is used to get the martket items which are created by me. 
    // @dev This function can be called by rent owner of NFTs
    // @return the market place Items list
    function fetchItemsCreatedForRent() external view returns (RentItem[] memory);
}

contract Verify {

    function splitSignature(bytes memory sig)
       public
       pure
       returns (uint8, bytes32, bytes32)
    {
       require(sig.length == 65);
       bytes32 r;
       bytes32 s;
       uint8 v;
       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
     
       return (v, r, s);
    }

    function VerifyMessage(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function VerifyMessage2(bytes32 _hashedMessage, bytes memory sig) public pure returns (address) {
        uint8 _v; bytes32 _r; bytes32 _s;
        (_v,_r,_s) = splitSignature(sig);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

}


// @title - AssetContract it is for tying the TNFT with the asset
contract AssetContract is IAssetContract ,Ownable{

    // Start here Martket place item variable
    TNFTContract public NFTContract;

    // @variable for TNFT contract address
    address public NFTContractAddress;

    // @variable for Marketplace contract address
    address public MarketContract;

    // @variable for Rentplace contract address
    address public RentContract;

    // @variable for RentTNFTContract
    RentTNFTContract public rentTNFTContract;

    // @variable for Rentplace contract address
    address public RentTNFTContractAddress;
    
    // Mapping from asset  address to assetId
    mapping(address => uint256)  private _assetAddressToAssetId;

    // Mapping from asset address to asset user
    mapping(address => address) private  _assetAddressToAssetUser;

    // Mapping from asset id to asset user
    mapping(uint256 => address) private  _assetIdToAssetUser;

    // Mapping from asset id to asset address
    mapping(uint256 => address)  _assetIdToAssetAddress;

    // Mapping user address to token count
    mapping(address=> uint256) private  _userBalances;

    // Mapping for token count
    // uint256 private _totalTokens;

    // Mapping from owner address to token ids
    uint256[] private  tokenIds;
    
    // Mapping from token id to enum tokenMarketPlaceStatus
    mapping(uint256=>tokenMarketPlaceStatus) public TokenMarketPlaceStatus;

    // Mapping from token id to enum redemptionInfo
    mapping(uint256 =>redemptionInfo) TokenRedemptionInfo;

    
    // mapping the token id from asset user engagement state
    mapping(uint256=>_assetUserState) public assetUserState;

    // @variable for containing the redeemed assets ids
    uint256[] public redeemedAssets;

    // Mapping usership from token ID to approved address
    mapping(uint256 => address) private _tokenUserApprovals;

    
   

    // @notice this function is used by owner of this interface 
    // @dev this function will be initialized by NFT contract address.
    // @param nftContract is the ERC721 contract address.
    // @note nftContract address should be intialzed to run this contract
    function initNFTContract(address nftContract) public onlyOwner{
        require(_isERC721(nftContract) == true,"Not a vaild ERC-721 contract address");
        NFTContract = TNFTContract(nftContract);
        NFTContractAddress = nftContract;
    }


    // @notice this function is used by owner of this interface 
    // @dev this function will be initialized by Rent TNFT contract address.
    // @param rentTNFTContractAddress is the TNFT rent contract contract address.
    // @note rentTNFTContractAddress address should be intialzed to if asset neede to be gone on rent.
    function initRentTNFTContract(address rentTNFTContractAddress) public onlyOwner{
        rentTNFTContract = RentTNFTContract(rentTNFTContractAddress);
        RentTNFTContractAddress = rentTNFTContractAddress;
    }

    function getRentTNFTContractAddress() public view returns(address){
        return RentTNFTContractAddress;
    }
    

    // @notice this function is used by owner of this interface 
    // @dev this function will be set by Marketplace contract address.
    // @dev only the owner of Asset contract can call this and it should updated only one time
    // @param marketContract is the Marketplace contract address.
    // @note It is option to intialze with marketContract address
    function initMarketContract(address marketContract) public onlyOwner{
        MarketContract = marketContract;
    }

    // @notice this function is used by owner of this interface 
    // @dev this function will be set by Rentplace contract address.
    // @dev only the owner of Asset contract can call this and it should updated only one time
    // @param rentContract is the Rentplace contract address.
    // @note It is option to intialze with rentContract address
    function initRentplaceContract(address rentContract) public onlyOwner{
        RentContract = rentContract;
    }
    

    
    // @notice  it is the modifier for checking caller is NFTContract
    modifier onlyNFTContract(){
        require(NFTContractAddress != address(0) ,'NFTContract Address is not set !');
        require(NFTContractAddress == msg.sender,'Unauthorized !');
        _;
    }

    // @dev - It is modifier for NFT owner and NFT user
    modifier onlyUserAndOnlyNFTOwner (uint256 tokenId){
        if(userOf(tokenId) != address(0)){
            require((msg.sender == userOf(tokenId) || getUserApproved(tokenId) == msg.sender ),"Not Authorized by user!");
        }else{
            require( (msg.sender == NFTContract.ownerOf(tokenId) || NFTContract.getApproved(tokenId)==msg.sender) ,"Not Authorized by owner!");
        }
        _;
    }

    // @notice - It is used to validate a TNFT contract address
    function _isERC721(address contractAddress) internal view returns (bool) {
        return IERC721(contractAddress).supportsInterface(0x80ac58cd);
    }
    
    


    // Marketplace/Rent place functions start here
    function getTokenMarketPlaceStatus(uint256 tokenId) public view returns (uint){
        return uint(TokenMarketPlaceStatus[tokenId]);
    }


    function updateTokenMarketPlaceStatus(uint256 tokenId,uint status) public override{
        if(MarketContract != address(0) && RentContract != address(0)){
            require(MarketContract == msg.sender || RentContract == msg.sender,"Sender is niether metaching with MarketContract nor RentContract");
        }else if(MarketContract != address(0) && RentContract == address(0)){
            require(MarketContract == msg.sender,"Sender is not metaching with MarketContract");
        }else if(MarketContract == address(0) && RentContract != address(0)){
            require(RentContract == msg.sender,"Sender is not metaching with RentContract");
        }

        TokenMarketPlaceStatus[tokenId] = tokenMarketPlaceStatus(status);

    }

    // Marketplace/Rent place functions end here
    

    // Attribute customization functions end


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
    function afterMint(uint256 tokenId,address assetAddress,address userAddress) public onlyNFTContract  {
        
        if(assetAddress != address(0)){
            require(!assetAddressExists(assetAddress), "ERC721: asset address already exist");
            _assetAddressToAssetId[assetAddress] = tokenId;
            _assetAddressToAssetUser[assetAddress] = userAddress;
            _assetIdToAssetAddress[tokenId] = assetAddress;

            
            emit AssetAssigned(tokenId,  assetAddress);
        }

        if(userAddress != address(0)){
            _userBalances[userAddress] += 1;
            _assetIdToAssetUser[tokenId] = userAddress;
            emit UserAssigned(tokenId, userAddress,NFTContract.ownerOf(tokenId));
        }

        
        // _totalTokens += 1;
        tokenIds.push(tokenId);
        
        if(userAddress == address(0)){
            assetUserState[tokenId] =_assetUserState.waitingForUser;
        }else{
            assetUserState[tokenId] =_assetUserState.UserEngaged;
        }
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
     * This function can be called when no user associated with asset
     */
    function afterBurn(uint256 tokenId) public  onlyNFTContract {
        
        // remove the tokenId from the array tokenIds
        tokenIds = deleteTokenId(tokenId,tokenIds);
        
        address assetAddress = BCAFromTokenID(tokenId);
        if(assetAddress != address(0)){
            delete _assetAddressToAssetId[assetAddress];
        }
        
        delete _assetIdToAssetAddress[tokenId];
        delete TokenMarketPlaceStatus[tokenId];
        delete TokenRedemptionInfo[tokenId];
        
        emit AssetBurned(tokenId);
        
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function assetAddressExists(address assetAddress) public view virtual returns (bool) {
        return _assetAddressToAssetId[assetAddress] !=0;
    }


    function getTotaltokens() public view returns(uint256){
         return tokenIds.length;   
    }

    /// @notice This function defines how the NFT is assigned as utility of a new user (if "addressUser" is defined).
    /// @dev Only the owner of the EIP-4519 NFT can assign a user. If "addressAsset" is defined, then the state of the token must be
    /// "engagedWithOwner","waitingForUser" or "engagedWithUser" and this function changes the state of the token defined by "_tokenId" to
    /// "waitingForUser". If "addressAsset" is not defined, the state is set to "userAssigned". In both cases, this function sets the parameter 
    /// "addressUser" to "_addressUser". 
    /// @param _tokenId is the tokenId of the EIP-4519 NFT tied to the asset.
    function setUser(uint256 _tokenId, address _addressUser) public override{
        require(msg.sender == NFTContract.ownerOf(_tokenId) || msg.sender == MarketContract,"Only owner can set the user !");
        if(msg.sender != MarketContract){
            require(userOf(_tokenId) == address(0),"User is already assigned !");
        }
        
        _setUser(_tokenId, _addressUser);
    }


    function _setUser(uint256 _tokenId, address _addressUser) private {
        _assetIdToAssetUser[_tokenId] = _addressUser;
        _userBalances[_addressUser] += 1;
        if(_assetIdToAssetAddress[_tokenId] != address(0)){
            _assetAddressToAssetUser[_assetIdToAssetAddress[_tokenId]] = _addressUser;
        }
        emit UserAssigned(_tokenId, _addressUser,msg.sender);

        assetUserState[_tokenId] =_assetUserState.UserEngaged;
    }


    function setAssetAddress(uint256 _tokenId, address _addressAsset) public {
        require(msg.sender == NFTContract.ownerOf(_tokenId),"Only owner can set the asset address !");
        require(!assetAddressExists(_addressAsset), "ERC721: asset address already exist");
        require(NFTContract.tookenExist(_tokenId) == true, "ERC721: token id is not exist");

        _assetAddressToAssetId[_addressAsset] = _tokenId;
        _assetIdToAssetAddress[_tokenId] = _addressAsset;

        if(userOf(_tokenId) != address(0)){
            _assetAddressToAssetUser[_addressAsset] = userOf(_tokenId);
        }

        emit AssetAssigned(_tokenId,  _addressAsset);
    }

    // @notice This function lets obtain the tokenId from an address. 
    // @dev Everybody can call this function. The code executed only reads from Ethereum.
    // / @param _addressAsset is the address to obtain the tokenId from it.
    // @return tokenId of the token tied to the asset that generates _addressAsset.
    function tokenFromBCA(address assetAddress) public view returns (uint256){
        require(assetAddress != address(0), "ERC721: address zero is not a valid asset address");
        return _assetAddressToAssetId[assetAddress];
    }

    function BCAFromTokenID(uint256  tokenId) public view returns (address){
        return _assetIdToAssetAddress[tokenId];
    }

    /// @notice This function lets know the owner of the token from the address of the asset tied to the token.
    /// @dev Everybody can call this function. The code executed only reads from Ethereum.
    /// @param _addressAsset is the address to obtain the owner from it.
    /// @return owner of the token bound to the asset that generates _addressAsset.
    function ownerOfFromBCA(address _addressAsset) public view returns (address){
        return NFTContract.ownerOf(tokenFromBCA(_addressAsset));
    }

    /// @notice This function lets know the user of the token from its tokenId.
    /// @dev Everybody can call this function. The code executed only reads from Ethereum.
    /// @param _tokenId is the tokenId of the EIP-4519 NFT tied to the asset.
    /// @return user of the token from its _tokenId.
    function userOf(uint256 _tokenId) public view returns (address){
        return _assetIdToAssetUser[_tokenId];
    }

    

    /// @notice This function lets know the user of the token from the address of the asset tied to the token.
    /// @dev Everybody can call this function. The code executed only reads from Ethereum.
    /// @param _addressAsset is the address to obtain the user from it.
    /// @return user of the token tied to the asset that generates _addressAsset.
    function userOfFromBCA(address _addressAsset) public view returns (address){
        return _assetAddressToAssetUser[_addressAsset];
    }

    

    /// @notice This function lets know how many tokens are assigned to a user.
    /// @dev Everybody can call this function. The code executed only reads from Ethereum.
    /// @param _addressUser is the address of the user.
    /// @return number of tokens assigned to a user.
    function userBalanceOf(address _addressUser) public view returns (uint256){
        return _userBalances[_addressUser];
    }


    

    /// @notice This function lets know tokens ids are assigned to a owner.
    /// @dev Everybody can call this function. The code executed only reads from Ethereum.
    /// @param owner is the address of the owner.
    /// @return array of tokens ids assigned to a owner.
    function getOwnerTokens(address owner) public view returns(uint256[] memory){
        uint256 j=0;
        for(uint256 i=0;i< tokenIds.length;i++){
            if(NFTContract.ownerOf(tokenIds[i])== owner){
                j++;
            }
        }
        uint256[] memory _ownerTokensId = new uint256[](j);
        j=0;
        for(uint256 i=0;i< tokenIds.length;i++){
            if(NFTContract.ownerOf(tokenIds[i])== owner){
                _ownerTokensId[j]= tokenIds[i];
                j++;
            }
        }
        return _ownerTokensId;
    }



    // @notice This function lets know tokens ids are assigned to a user.
    // @dev Everybody can call this function. The code executed only reads from Ethereum.
    // @param user is the address of the user.
    // @return array of tokens ids assigned to a user.
    function getUserTokens(address _user) public view returns(uint256[] memory){
        uint256 j=0;
        for(uint256 i=0;i< tokenIds.length;i++){
            if(userOf(tokenIds[i])== _user){
                j++;
            }
        }
        uint256[] memory _userTokensId = new uint256[](j);
        j=0;
        for(uint256 i=0;i< tokenIds.length;i++){
            if(userOf(tokenIds[i])== _user){
                _userTokensId[j]= tokenIds[i];
                j++;
            }
        }
        return _userTokensId;
    }

    function isTokenExist(uint256 _tokenId)public view returns(bool){
        bool exist = false;
        for(uint256 i=0;i< tokenIds.length;i++){
            if(tokenIds[i]== _tokenId){
                exist = true;
            }
        }
        return exist;
    }

    function deleteTokenId(uint256 _tokenId,uint256 [] memory _tokenIds) private pure returns(uint256 [] memory _userTokensId) {
        uint256 j=0;
        // uint256[] memory _userTokensId = new uint256[](_tokenIds.length-1);
        for(uint256 i=0;i< _tokenIds.length;i++){
            if(_tokenIds[i]== _tokenId){
                
            }else{
                _userTokensId[j]= _tokenIds[i];
                j++;
            }
        }
        _tokenIds = _userTokensId;
        return _userTokensId;
    }


    // @notice This function lets know how many tokens of a particular owner are assigned to a user.
    // @dev Everybody can call this function. The code executed only reads from Ethereum.
    // @param _addressUser is the address of the user.
    // @param _addressOwner is the address of the owner.
    // @return number of tokens assigned to a user from an owner.
    function userBalanceOfAnOwner(address _addressUser, address _addressOwner) public view returns (uint256){
        uint256 _userBalanceOfAnOwner = 0;
        // _assetOwnerToAssetAddress[]
        uint256[] memory _ownerTokensId =  getOwnerTokens(_addressOwner);
        for(uint256 i=0;i<_ownerTokensId.length;i++){
            if(userOf(_ownerTokensId[i])==_addressUser){
                _userBalanceOfAnOwner++;
            }
        }

        return _userBalanceOfAnOwner;
    }

    function splitSignature(bytes memory sig)
       public
       pure
       returns (uint8, bytes32, bytes32)
    {
       require(sig.length == 65);
       bytes32 r;
       bytes32 s;
       uint8 v;
       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
     
       return (v, r, s);
    }

    function verifyAssetUser(address assetAdress,bytes32 _hashedMessage, bytes memory sig) public {
        uint8 _v; bytes32 _r; bytes32 _s;
        (_v,_r,_s) = splitSignature(sig);

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        require(assetAddressExists(assetAdress)==true,"Asset address is not exist !");

        uint256 tokenId = tokenFromBCA(assetAdress);

        
        require(signer == userOfFromBCA(assetAdress),"Unauthorized aaset user !");
        assetUserState[tokenId] =_assetUserState.UserEngaged;
        emit UserAuthenticated(tokenId);
    
    }

    function userBurnAsset(address assetAdress) public {
        uint256 tokenId = tokenFromBCA(assetAdress);
        // require(msg.sender == NFTContract.ownerOf(tokenId),"Only owner can burn it !");
        // require(msg.sender == userOfFromBCA(assetAdress),"Unauthorized aaset user !");

        require(getUserApproved(tokenId) == msg.sender || msg.sender == userOfFromBCA(assetAdress),"You are not approved !");
        
        require(assetAddressExists(assetAdress) == true,"Asset address is not exist !");
        require(canAssetBeRedeeded(tokenId)==true,"Asset can not be redeemed !");

    
        require(assetUserState[tokenId] != _assetUserState.UserRedeemAsset,"Asset is already redeemed!");
        assetUserState[tokenId] =_assetUserState.UserRedeemAsset;
        redeemedAssets.push(tokenId);


        emit AssetBurned(tokenId);
        emit UserRedeemedAsset(tokenId,msg.sender);
    }


    function isAssetRedeemed(uint256 tokenId) public view override returns(bool){
        require(isTokenExist(tokenId)==true, "Token is not exist!");
        return assetUserState[tokenId] == _assetUserState.UserRedeemAsset;
    }

    function getUserApproved(uint256 tokenId) public view returns (address) {
        require(isTokenExist(tokenId)==true, "Token is not exist!");
        return _tokenUserApprovals[tokenId];
    }


    function approveUser(address to, uint256 tokenId) public  override {
        address user = userOf(tokenId);
        require(to != user, "ERC721: approval to current user");

        require(
            msg.sender == user ,
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenUserApprovals[tokenId] = to;
        emit UserApproval(userOf(tokenId), to, tokenId);
    }

    
    //----------RENT  TNFT functions start here-------------
    function getRentUser(uint256 tokenId) public view returns(address){
        if(RentTNFTContractAddress != address(0)){
            return rentTNFTContract.getRentUser(tokenId);
        }else{
            return address(0);
        }
    }

    //----------RENT  TNFT functions end here-------------

    //----------redeption date functions start here-------------

    // @notice This function is to update the the TNFT redemption start date and end date
    // @dev This function should be called by TNFT Contract
    // @parm tokenId- It is the id of TNFT
    // @param _startDate - It the TNFT redemption start date . 
    // @param _endDate - It the TNFT redemption end date .
    function addRedeptionDate(uint256 tokenId ,uint256 _startDate, uint256 _endDate) public 
    onlyNFTContract
    {
        require(isTokenExist(tokenId)==true, "Token is not exist!");
        TokenRedemptionInfo[tokenId] = redemptionInfo(tokenId,_startDate,_endDate);

        emit RedemptionInfoUpdated(tokenId,_startDate,_endDate);
    }

    // @notice This function lets know asset can be redeemed or not
    // @dev Any one can call this function
    // @param tokenId- It is the id of TNFT
    // @return true - if TNFT can be redeemed .
    function canAssetBeRedeeded(uint256 tokenId) public view returns(bool CanRedeem){
        uint256 startDate = TokenRedemptionInfo[tokenId].startDate;
        uint256 endDate = TokenRedemptionInfo[tokenId].endDate;
        CanRedeem =  false;
        if(startDate == 0 && endDate == 0){
            CanRedeem = true;
        }else if(startDate == 0 && endDate != 0){
            if(block.timestamp <= endDate){
                CanRedeem = true;
            }
        }else if(startDate != 0 && endDate == 0){
            if(block.timestamp >= startDate){
                CanRedeem = true;
            }
        }else if(startDate != 0 && endDate != 0){
            if(block.timestamp >= startDate && block.timestamp <= endDate){
                CanRedeem = true;
            }
        }
        return CanRedeem;
    }

    // @notice This function lets know the full information about TNFT redemption date
    // @dev Any one can call this function
    // @param tokenId- It is the id of TNFT
    // @return redemptionInfo - it returns the struct of  TNFT redemption date.    
    function getTokenRedemptionInfo(uint256 tokenId) public view returns (redemptionInfo memory){
        redemptionInfo memory tokenRedemptionInfo;
        tokenRedemptionInfo = TokenRedemptionInfo[tokenId];
        return tokenRedemptionInfo;
    }
    
    //----------redeption date functions end here-------------

    function contractAddress() public view returns (address) {  
       address contAddress = address(this); //contract address  
       return contAddress;  
    } 

    
}

// @title - RentTNFTContract This contract is used to use the Renting features
contract RentTNFTContract is RentInterface,Ownable{
    // Start here Martket place item variable
    TNFTContract public NFTContract;

    // @variable for TNFT contract address
    address public NFTContractAddress;

    // @varibales declaration for assetContract
    AssetContract public assetContract;
    address public assetContractAddress;

    // mapping from token id to rent info
    mapping (uint256  => RentInfo) internal _rentedAssets;

    // @variable for having the total rented TNFTs 
    uint256[] public rentItemIds;

    // @variable for Rentplace contract address
    address public RentContract;

    // mapping the token id from asset user engagement state
    mapping(uint256=>_assetRentUserState) public assetRentUserState;

    // Mapping usership from token ID to approved address
    mapping(uint256 => address) private _tokenRentUserApprovals;


    
    // @dev - It is modifier for NFT owner and NFT user
    modifier onlyUserAndOnlyNFTOwner (uint256 tokenId){
        if(assetContract.userOf(tokenId) != address(0)){
            require((msg.sender == assetContract.userOf(tokenId) || assetContract.getUserApproved(tokenId) == msg.sender ),"Not Authorized by user!");
        }else{
            require( (msg.sender == NFTContract.ownerOf(tokenId) || NFTContract.getApproved(tokenId)==msg.sender) ,"Not Authorized by owner!");
        }
        _;
    }

    // @notice this function is used by owner of this interface 
    // @dev this function will be initialized by NFT contract address.
    // @param nftContract is the ERC721 contract address.
    // @note nftContract address should be intialzed to run this contract
    function initNFTContract(address nftContract) public onlyOwner{
        require(_isERC721(nftContract) == true,"Not a vaild ERC-721 contract address");
        NFTContract = TNFTContract(nftContract);
        NFTContractAddress = nftContract;

        assetContractAddress = NFTContract.getAssetContractAddress();
        assetContract = AssetContract(assetContractAddress);
    }

    // @notice this function is used by owner of this interface 
    // @dev this function will be set by Rentplace contract address.
    // @dev only the owner of Asset contract can call this and it should updated only one time
    // @param rentContract is the Rentplace contract address.
    // @note It is option to intialze with rentContract address
    function initRentplaceContract(address rentContract) public onlyOwner{
        RentContract = rentContract;
    }

    // @notice - It is used to validate a TNFT contract address
    function _isERC721(address contractAddress) internal view returns (bool) {
        return IERC721(contractAddress).supportsInterface(0x80ac58cd);
    }

    // @notice -This function is used to get rentplace contract address
    // @dev anyone can call this function
    // @return the rentplace contract address
    function getRentplaceContractAddress() public view returns(address){
        return RentContract;
    }

    
    // @notice This function is used to add the rent owner for a TNFT. 
    // @dev Only Rent marketplace contract , ower or user can call this function
    // @param tokenId - it is TNFT token id
    // @param rentUser - Ethereum address of the user who takes it on rent
    // @param expires - it is rent expiry time
    // @param startedAt - it is rent starting at time
    // @param rentOwner - it is ehereum address of the rent owner (TNFT owner/ TNFT user who purchased it)
    function addRentUser(uint256 tokenId, address rentUser, uint256 expires,uint256 startedAt,uint256 price,address rentOwner)public override {
        
        require(getRentUser(tokenId)==address(0),"Asset is already on rent !");
        if(assetContract.userOf(tokenId) != address(0)){
            require((msg.sender == assetContract.userOf(tokenId) ||  assetContract.getUserApproved(tokenId) == msg.sender ) || RentContract == msg.sender,"Not Authorized!");
        }else{
            require( (msg.sender == NFTContract.ownerOf(tokenId) ) || RentContract == msg.sender,"Not Authorized!");
        }
        if(_rentedAssets[tokenId].tokenId != tokenId){
            rentItemIds.push(tokenId);
        }
        _rentedAssets[tokenId] = RentInfo(tokenId,rentUser,expires,startedAt,price,rentOwner,false);

        assetRentUserState[tokenId] =_assetRentUserState.RentUserEngaged;
        emit AssetRented(tokenId, rentUser,expires,startedAt,price,rentOwner);

    }

    // @notice Renews the subscription to an NFT
    // Throws if `tokenId` is not a valid NFT
    // @param tokenId The NFT to renew the subscription for
    // @param duration The number of seconds to extend a subscription for
    function renewSubscription(uint256 tokenId, uint256 duration) public payable onlyUserAndOnlyNFTOwner(tokenId) {
        require(getRentInfo(tokenId).tokenId == tokenId,"Subscription is not exist");
       
        uint256 currentExpiration = userExpires(tokenId);
        uint256 newExpiration;
        newExpiration = currentExpiration + duration;
        _rentedAssets[tokenId].expires = newExpiration;
        emit SubscriptionUpdate(tokenId, newExpiration);
    }

    /// @notice Cancels the subscription of an NFT
    /// @dev Throws if `tokenId` is not a valid NFT
    /// @param tokenId The NFT to cancel the subscription for
    function cancelSubscription(uint256 tokenId) external payable onlyUserAndOnlyNFTOwner(tokenId) {
        delete _rentedAssets[tokenId];
        // remove the tokenId from the array tokenIds
        rentItemIds = deleteTokenId(tokenId,rentItemIds);

        delete assetRentUserState[tokenId];
        

        emit SubscriptionUpdate(tokenId, 0);
    }
    
    // @notice this function lets know the rent user for a TNFT
    // @dev anybody can call this function
    // @param tokenId - it is TNFT token id
    // @return the rent user address if it  exist and it is not expired. if it is not exist 
    // if it is not exist it will return empty address
    function getRentUser(uint256 tokenId) public view returns(address){
        address rentUser = address(0);
        if(_rentedAssets[tokenId].tokenId == tokenId &&  uint256(_rentedAssets[tokenId].expires) >=  block.timestamp){
            rentUser = _rentedAssets[tokenId].user;
        } 
        return rentUser;
    }

     // @notice this lets know the user expiry time
    // @dev anybody can call this function
    // @param tokenId - it is TNFT token id
    // @return it return the rent user expiry time if rent user exist. 
    function userExpires(uint256 tokenId) public view  returns(uint256){
       return _rentedAssets[tokenId].expires;
    }

    // @notice this lets know the all attributes values regarding rent
    // @dev anybody can call this function
    // @param tokenId - it is TNFT token id
    // @return it return the RentInfo struct data. 
    function getRentInfo(uint256 tokenId)public view returns(RentInfo memory){
        RentInfo memory _rentInfo;
        _rentInfo =  _rentedAssets[tokenId];
        return _rentInfo;
    }

    // @notice this lets know the rent inforamations for all TNFTs
    // @dev anybody can call this function
    // @param active - if can be true or false
    // @return  if active==true , it will renturn only non expired  rent informations 
    // otherwise it will return   rent inforamations for all TNFTs
    function getAllRentInfo(bool active)public view returns(RentInfo [] memory){
        uint256 rentItemsCount = rentItemIds.length;
        RentInfo[] memory _allRentInfo = new RentInfo[](rentItemsCount);
        for(uint256 i=0;i< rentItemsCount;i++){
            uint256 tokenId = rentItemIds[i];
            if(active == true){
                if(uint256(_rentedAssets[tokenId].expires) >=  block.timestamp){
                    _allRentInfo[i] = _rentedAssets[tokenId];   
                }
            }else{
                _allRentInfo[i] = _rentedAssets[tokenId];    
            }
           
        }
        return _allRentInfo;
    }

    // @notice it is the private function and used to delete the any value from an array
    // @dev it can be call inside the current contrcat
    // @param _tokenId - It the key of the array
    // @param - _tokenIds It is the array ,in which value is being to be delete
    // @return -_userTokensId It return the new array 
    function deleteTokenId(uint256 _tokenId,uint256 [] memory _tokenIds) private pure returns(uint256 [] memory _userTokensId) {
        uint256 j=0;
        // uint256[] memory _userTokensId = new uint256[](_tokenIds.length-1);
        for(uint256 i=0;i< _tokenIds.length;i++){
            if(_tokenIds[i]== _tokenId){
                
            }else{
                _userTokensId[j]= _tokenIds[i];
                j++;
            }
        }
        _tokenIds = _userTokensId;
        return _userTokensId;
    }

    // @notice this function is used to split the signature into v,r,s
    // @param - Signature
    // @returns Signature in splited part v,r,s
    function splitSignature(bytes memory sig)
       public
       pure
       returns (uint8, bytes32, bytes32)
    {
       require(sig.length == 65);
       bytes32 r;
       bytes32 s;
       uint8 v;
       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
     
       return (v, r, s);
    }

    // @notice This function is used when user verify own address identity by signing the message.
    // This function check whether the message is signed with  asset user. if message is verified ,A event RentUserAuthenticated emits.
    // if the message is successfully verified then asset state is changed to UserEngaged.
    // @event UserAuthenticated event emits
    // @param assetAdress is the address of the user.
    // @param _hashedMessage is the hash of the message.
    // @params sig is the signatured message
    function verifyAssetRentUser(uint256 tokenId,bytes32 _hashedMessage, bytes memory sig) public {
        uint8 _v; bytes32 _r; bytes32 _s;
        (_v,_r,_s) = splitSignature(sig);

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        

        require(getRentUser(tokenId) != address(0),"Rent user is not exist");
        require(signer == getRentUser(tokenId),"Signature is not matched");

        assetRentUserState[tokenId] =_assetRentUserState.RentUserAuthenticated;
        emit RentUserAuthenticated(tokenId);
    
    }

    // @notice this function is used to mark as TNFT is temperorly redeedem.
    // rent user first approve the sytem to do this action. when user approve the system pay TNFT and update it in smart contract as redeemed
    // @dev - only the approved account or rent user self can use this function
    // @param tokenId -TNFT token id
    function rentUserRedeemAsset(uint256 tokenId) public {
        require(isAssetRedeemed(tokenId)== false,"TNFT is already temperory redeemed !");
        require(getRentUserApproved(tokenId) == msg.sender || msg.sender == getRentUser(tokenId),"You are not approved to redeem the rent TNFT !");

        assetRentUserState[tokenId] =_assetRentUserState.RentUserRedeemAsset;
        
        _rentedAssets[tokenId].isRedeemed = true;

        emit UserRedeemedRentAsset(tokenId,msg.sender);
    }

    // @notice this function lets know whether asset is redeeded or not
    // @param  tokenId  it is the NFT Id
    // return true if NFT/Asset is redeemed
    function isAssetRedeemed(uint256 tokenId) public view override returns(bool){
        require(getRentUser(tokenId) != address(0),"Rent user is not exist");
        return assetRentUserState[tokenId] == _assetRentUserState.RentUserRedeemAsset;
    }

    // @notice This function lets know any user is  approved by Asset user
    // @dev This function can be called by anyone
    // @param tokenId - it is TNFT token id
    // @return - it returns the approved user address
    function getRentUserApproved(uint256 tokenId) public view returns (address) {
        require(getRentUser(tokenId) != address(0),"Rent user is not exist");
        return _tokenRentUserApprovals[tokenId];
    }

    // @notice This function is used to approve a user
    // @dev This function can be called by anyone
    // @param to - it is address of to user
    // @param tokenId - it is TNFT token id
    function approveRentUser(address to, uint256 tokenId) public  override {
        address rentUser = getRentUser(tokenId);
        require(to != rentUser, "Rent user can not approve ownself !");

        require(
            msg.sender == rentUser ,
            "ERC721: approve caller is not token rent user"
        );

        _approve(to, tokenId);
    }

    // @notice This is used for internal purpose to approve the user by rent user
    // @dev only internally can be called
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenRentUserApprovals[tokenId] = to;
        emit RentUserApproval(getRentUser(tokenId), to, tokenId);
    }

}

// @title - NFTMarketPlace Contract for marketplace functions
contract NFTMarketPlace is ReentrancyGuard,Ownable, MarketplaceInterface {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemSold;
    Counters.Counter private _itemCancelled;

    uint256 internal listingPrice;

    
    IAssetContract AssetContract;

    mapping(uint256 => MarketItem) public idToMarketItem;

    constructor(uint256 _listingPrice) {
        listingPrice = _listingPrice;
    }


    // @notice The functions is used to get the listing price to sale on market
    // @dev Anybody  can call this function
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

   

    // @notice The functions is used to add a NFT for market sale or An item can be resale
    // @dev This function can be called by the owner of NFT or user of NFT (User of the NFT : Referring Asset interface)
    // @param nftContract is contract address where NFT is created.
    // @param assetContract is contract address where NFT is asset and user details exist.
    // @param tokenId is the token id.
    // @param price is at which , item will be sold.
    // @return the market place Item id
    function createMarketItem(
        address nftContract, // NFT contract address
        address assetContract, // Asset contrcat address
        uint256 tokenId, // NFT token id
        uint256 price// Saling or Renting price
    ) public payable nonReentrant returns(uint256){
        AssetContract = IAssetContract(assetContract);
        IERC721 NFTContract = IERC721(nftContract);
        bool resale = false; 
        require(price > 0, "Price must be atleast 1 wei");
        uint256 itemId;

        
        if(AssetContract.userOf(tokenId)== address(0)){
            require(msg.sender == NFTContract.ownerOf(tokenId) ,"TNFT owner can only list! ");
            resale = false;
        }else{
            resale = true;
            require(AssetContract.userOf(tokenId)== msg.sender,"Only user can sell!");
            require(AssetContract.isAssetRedeemed(tokenId) == false,"Asset can not be sold !");
        }
        require(
            msg.value >= listingPrice,
            "Price must be equal to listing price"
        );
        
        require(AssetContract.getTokenMarketPlaceStatus(tokenId) == 0,"NFT can not be placed on marketplace !");

        _itemIds.increment();
        itemId = _itemIds.current();
        MarketItem memory _marketItem = MarketItem(
            itemId,
            nftContract,
            assetContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false,
            false,
            resale
        );
        idToMarketItem[itemId] = _marketItem;
        // IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        AssetContract.setUser(tokenId, address(this));  
        emit MartketItemCreated(_marketItem);

        AssetContract.updateTokenMarketPlaceStatus(tokenId,1);

        
        // TokenMarketPlaceStatus    
        return itemId;
    }

    // @notice The functions is used to cancel a NFT for market sale. Returns the listing fees to marketplace owner.
    // @dev This function can be called by the seller of NFT
    // @param itemId is market place item id.
    function cancelMarketItem(uint256 itemId) public  {
        require(idToMarketItem[itemId].itemId ==itemId ,"Item is not exist");
        require(msg.sender == idToMarketItem[itemId].seller,"You are not the seller !");
        require(idToMarketItem[itemId].sold==false,"item is sold out.You can not cancel it!");
        
        AssetContract = IAssetContract(idToMarketItem[itemId].assetContract);
        if(idToMarketItem[itemId].resale==false){
            AssetContract.setUser(idToMarketItem[itemId].tokenId, address(0));
        }else{
            AssetContract.setUser(idToMarketItem[itemId].tokenId, idToMarketItem[itemId].seller);
        }
        idToMarketItem[itemId].cancelled = true;
        _itemCancelled.increment();
        payable(owner()).transfer(listingPrice);

        uint256 tokenId = idToMarketItem[itemId].tokenId;
        AssetContract.updateTokenMarketPlaceStatus(tokenId,0);

        emit MartketItemCancelled(idToMarketItem[itemId]);
    }

    // @notice The functions is used where any user can purchase the item. 
    // After purchase the price  will be transfered to seller account 
    // and listing fees will be transfered to owner of marketplace contract
    // @dev This function can be called by anyone
    // @param itemId is market place item id.
    function createMarketSale(
        uint256 itemId // Market place item id
    )
        public
        payable
        nonReentrant
    {
        require(idToMarketItem[itemId].itemId ==itemId ,"Item is not exist");
        require(idToMarketItem[itemId].cancelled == false,"It is not for sale!");
        require(idToMarketItem[itemId].sold == false,"Item is already sold!");
        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;

        AssetContract = IAssetContract(idToMarketItem[itemId].assetContract);

        require(
            msg.value >= price,
            "Please submit the asking price in order to complete the purchase"
        );

        idToMarketItem[itemId].seller.transfer(msg.value);

        AssetContract.setUser(tokenId, msg.sender);


        idToMarketItem[itemId].user = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemSold.increment();
        
        payable(owner()).transfer(listingPrice);
        emit ReceivedListingFees(msg.sender, msg.value);

        MarketItem memory _marketItem = idToMarketItem[itemId];

        AssetContract.updateTokenMarketPlaceStatus(tokenId,0);
        emit MartketItemSold(_marketItem);
    
    
    }

    // @notice The functions is used to get the martket items which are for sale. 
    // @dev This function can be called by anyone
    // @return the market place Items list
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemcount = _itemIds.current() - _itemSold.current() - _itemCancelled.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemcount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].user == address(0) && idToMarketItem[i + 1].cancelled == false) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    

    // @notice The functions is used to get the martket items which are purchased by me. 
    // @dev This function can be called by buyer of NFTs
    // @return the market place Items list
    function fetchMyPurchasedNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].user == msg.sender) {
                itemCount++;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].user == msg.sender) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // @notice The functions is used to get the martket items which are created by me. 
    // @dev This function can be called by seler of NFTs
    // @return the market place Items list
    function fetchItemsCreatedForSell() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount++;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

}

// @title - NFTRentPlace Contract for rentplace functions
contract NFTRentPlace is ReentrancyGuard,Ownable, RentplaceInterface {
    using Counters for Counters.Counter;
    
    uint256 internal rentlistingPrice;

    Counters.Counter private _itemRentIds;
    Counters.Counter private _itemRented;
    Counters.Counter private _itemRentCancelled;
    IAssetContract AssetContract;

    mapping(uint256 => RentItem) public idToRentItem;
    RentTNFTContract public rentTNFTContract;

    constructor(uint256 _rentlistingPrice) {
        rentlistingPrice = _rentlistingPrice;
    }
    
    // @notice The functions is used to get the listing price to rent on market
    // @dev Anybody  can call this function
    function getRentListingPrice() public view returns (uint256) {
        return rentlistingPrice;
    }

    // @notice The functions is used to add a NFT for rent on rentplace
    // @dev This function can be called by the owner of NFT or user of NFT (User of the NFT : Referring Asset interface)
    // @param nftContract is contract address where NFT is created.
    // @param assetContract is contract address where NFT is asset and user details exist.
    // @param tokenId is the token id.
    // @param price is at which , item will be sold.
    // @param rentCycleTime is time in hour. It defines that price will be for rentCycleTime period
    // @return the market place Item id 
    function createRentItem(
        address nftContract, // NFT contract address
        address assetContract, // Asset contrcat address
        uint256 tokenId, // NFT token id
        uint256 price, // Saling or Renting price
        uint64 rentCycleTime // hours value if item for rent
    ) public payable nonReentrant 
    {
        AssetContract = IAssetContract(assetContract);
        IERC721 NFTContract = IERC721(nftContract);
        require(price > 0, "Price must be atleast 1 wei");
        uint256 itemId;

    
        // item is being created for rent
        require(AssetContract.getRentUser(tokenId) == address(0),"NFT is already on rent");
        if(AssetContract.userOf(tokenId) != address(0)){
            require(msg.sender == AssetContract.userOf(tokenId) ,"You are not the user of this NFT ");
        }else{
            require(NFTContract.ownerOf(tokenId)== msg.sender,"You are not the owner of this NFT");
        }
        require(
            msg.value >= rentlistingPrice,
            "Price must be equal to rent listing price"
        );

        // check item is already on rent
        require(AssetContract.getRentUser(tokenId) == address(0),"Item is already on rent!");

        require(AssetContract.getTokenMarketPlaceStatus(tokenId)==0,"NFT can not be placed on rent place !");

        _itemRentIds.increment();
        itemId = _itemRentIds.current();
        RentItem memory _rentItem = RentItem(
            itemId,
            nftContract,
            assetContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false,
            false,
            rentCycleTime
        );
        idToRentItem[itemId] = _rentItem;

        AssetContract.updateTokenMarketPlaceStatus(tokenId,2);
        emit RentItemCreated(_rentItem);
        
    }

    // @notice The functions is used to cancel a NFT for rent from Rentplace. Returns the listing fees to rentplace owner.
    // @dev This function can be called by the owner/user of NFT
    // @param itemId is market place item id.
    function cancelRentItem(uint256 itemId) public  {
        require(idToRentItem[itemId].itemId ==itemId ,"Item is not exist");
        require(msg.sender == idToRentItem[itemId].rentOwner,"You are not the rent owner !");
        require(idToRentItem[itemId].rented==false,"item is rent out.You can not cancel it!");
        
         idToRentItem[itemId].cancelled = true;
        _itemRentCancelled.increment();
        payable(owner()).transfer(rentlistingPrice);

        uint256 tokenId = idToRentItem[itemId].tokenId;
        address assetContract = idToRentItem[itemId].assetContract;
        AssetContract = IAssetContract(assetContract);
        AssetContract.updateTokenMarketPlaceStatus(tokenId,0);

        emit RentItemCancelled(idToRentItem[itemId]);
    }
    
    // @notice The functions is used where any user can take the item on rent. 
    // After taking renting the price  will be transfered to rent owner account 
    // and listing fees will be transfered to owner of marketplace contract
    // @dev This function can be called by anyone
    // @param itemId is rent place item id.
    // @param rentCycleTime  - It is no. of cycles for which user wants to take it on rent
    function createMarketRent(
        uint256 itemId, // Market place item id
        uint256 rentCycleTime // lets know rent is for how many clycles
    )
        public
        payable
        nonReentrant
    {
        
        require(idToRentItem[itemId].itemId ==itemId ,"Item is not exist");
        require(idToRentItem[itemId].cancelled == false,"It is not for rent!");
        require(idToRentItem[itemId].rented == false,"Item is already on rent!");
        
        require(msg.sender != idToRentItem[itemId].rentOwner,"You can not take item on rent by yourself !");

        rentCycleTime = idToRentItem[itemId].rentCycleTime;
        uint256 rentPrice = rentCycleTime*idToRentItem[itemId].price;
        
        require(
            msg.value >= rentCycleTime*idToRentItem[itemId].price,
            "Please submit the asking price in order to complete the rent"
        );

        
        uint256 startedAt = block.timestamp;
        uint256 expires = startedAt+rentCycleTime*60*60;

        address rentTNFTContractAddress = AssetContract.getRentTNFTContractAddress();
        rentTNFTContract = RentTNFTContract(rentTNFTContractAddress);

        require(rentTNFTContract.getRentplaceContractAddress()== address(this),"Rent TNFT Contract is not initialzed with Rent Place contract !");
        rentTNFTContract.addRentUser(idToRentItem[itemId].tokenId,msg.sender,expires,startedAt,rentPrice,idToRentItem[itemId].rentOwner);
        

        idToRentItem[itemId].rentUser = payable(msg.sender);
        idToRentItem[itemId].rented = true;
        emit ReceivedListingFees(msg.sender, rentPrice);

        RentItem memory _rentItem = idToRentItem[itemId];
        _itemRented.increment();

        uint256 tokenId = idToRentItem[itemId].tokenId;
        AssetContract.updateTokenMarketPlaceStatus(tokenId,0);
        emit MartketItemRented(_rentItem);
        
    }

    // @notice The functions is used to get the martket items which are for rent. 
    // @dev This function can be called by anyone
    // @return the rent place Items list
    function fetchRentItems() public view returns (RentItem[] memory) {
        uint256 itemCount = _itemRentIds.current();
        uint256 unrentedItemcount = _itemRentIds.current() - _itemRented.current() - _itemRentCancelled.current();
        uint256 currentIndex = 0;

        RentItem[] memory items = new RentItem[](unrentedItemcount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToRentItem[i + 1].rentUser == address(0) && idToRentItem[i + 1].cancelled == false) {
                uint256 currentId = idToRentItem[i + 1].itemId;
                RentItem storage currentItem = idToRentItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // @notice The functions is used to get the martket items which are taken on rent by me. 
    // @dev This function can be called by renter of NFTs
    // @return the market place Items list
    function fetchMyRentedNFTs() public view override returns (RentItem[] memory) {
        uint256 totalItemCount = _itemRentIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToRentItem[i + 1].rentUser == msg.sender) {
                itemCount++;
            }
        }
        RentItem[] memory items = new RentItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToRentItem[i + 1].rentUser == msg.sender) {
                uint256 currentId = idToRentItem[i + 1].itemId;
                RentItem storage currentItem = idToRentItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }


    // @notice The functions is used to get the martket items which are created by me. 
    // @dev This function can be called by rent owner of NFTs
    // @return the market place Items list
    function fetchItemsCreatedForRent() public view returns (RentItem[] memory) {
        uint256 totalItemCount = _itemRentIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToRentItem[i + 1].rentOwner == msg.sender) {
                itemCount++;
            }
        }
        RentItem[] memory items = new RentItem[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToRentItem[i + 1].rentOwner == msg.sender) {
                uint256 currentId = idToRentItem[i + 1].itemId;
                RentItem storage currentItem = idToRentItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}

// @title - AssetCustomizationContract contract has the TNFT attributes related functions
abstract contract AssetCustomizationContract is AssetCustomizationInterface,ERC721{
    
    //Keeping the NFT on chain attributes trait type
    mapping(uint256=>string[]) private attributeTraitTypeTemp;
    mapping(uint256=>string[]) public attributeTraitType;

    //Keeping the NFT on chain attributes trait value
    mapping(uint256=>string[]) private attributeTraitValueTemp;
    mapping(uint256=>string[]) public attributeTraitValue;

    uint256 public tokenAtributesLimit = 5;
    uint256 public stringLimit = 45;

    // @notice - This function is used to add the TNFT attributes
    // @dev - Only the TNFT owner can call this function
    // @param tokenId- It is the id of TNFT
    // @param traitType - It is the array of TNFT attributes names like Color, Height, Weight etc may be attributes.
    // @param traitValue -It is the array of TNFT attributes values.    
    function _addTokenAttributes(uint256 _tokenId, string [] memory  _traitType , string [] memory  _traitValue) public  virtual override{
        
        require(_traitType.length == _traitValue.length,"invalid attributes count");
        if(_traitType.length >0 ){
             require(attributeTraitType[_tokenId].length+_traitType.length <= tokenAtributesLimit,"Attributes limit reached !");

            for(uint256 i=0;i< _traitType.length;i++){
                require(bytes(_traitType[i]).length <= stringLimit, "String input exceeds limit.");
                require(bytes(_traitValue[i]).length <= stringLimit, "String input exceeds limit.");
            }

            for(uint256 i=0;i< _traitType.length;i++){
                attributeTraitType[_tokenId].push(_traitType[i]);
                attributeTraitValue[_tokenId].push(_traitValue[i]);
            }
        }
        emit AttributesAdded(_tokenId);
       
    }

    // @notice - This function is used to lets know TNFT attributes is exist or not
    // @dev any one can call this function
    // @param tokenId- It is the id of TNFT
    // @param traitType - It is the array of TNFT attributes names.
    // @returns true if attribute is exist
    function _attributeTraitTypeExists(uint256 _tokenId, string memory _traitType ) external view returns (bool){
        return attributeTraitTypeExists(_tokenId, _traitType);
    }

    // @dev - it is the private function for internla purpose
    function attributeTraitTypeExists(uint256 _tokenId, string memory _traitType ) private view  returns (bool){
        bool isExist = false;
        for(uint256 i=0;i< attributeTraitType[_tokenId].length;i++){
            if(attributeTraitType[_tokenId].length > 0 && keccak256(abi.encodePacked(attributeTraitType[_tokenId][i])) == keccak256(abi.encodePacked(_traitType))){
                isExist = true;
            }
        }
        
        return (isExist);
    }

    // @notice - This function is used to let knows the count of TNFT attributes
    // @dev - Any one can call this function
    // @param tokenId- It is the id of TNFT 
    // @retun the count of attributes
    function _getTokenAttributeCount(uint256 _tokenId) external view returns(uint256){
        return attributeTraitType[_tokenId].length;
    }

    // @notice - This function is used to update the TNFT attribute value
    // @dev - This  function will be override in TNFT contract
    // @param tokenId- It is the id of TNFT
    // @param traitType- It is the TNFT attribute name
    // @param traitValue- It is the TNFT attribute value
    // @event AttributeValueUpdated emitted
    function _updateTokenAttributeValue(uint256 _tokenId, string memory _traitType,string memory _traitValue) public virtual override{
        bool isExist = attributeTraitTypeExists(_tokenId,_traitType);
        require(isExist == true,"Trait type is not exist!");
        require(bytes(_traitValue).length <= stringLimit, "String input exceeds limit.");
        for(uint256 i=0;i< attributeTraitType[_tokenId].length;i++){
            if(attributeTraitType[_tokenId].length  > 0 && keccak256(abi.encodePacked(attributeTraitType[_tokenId][i])) == keccak256(abi.encodePacked(_traitType))){
                attributeTraitValue[_tokenId][i] = _traitValue;
            }
        }

        emit AttributeValueUpdated(_tokenId);
    }

    // @notice - This function is used to delete the attribute the TNFT
    // @dev - This  function will be override in TNFT contract
    // @param tokenId- It is the id of TNFT
    // @param traitType- It is the TNFT attribute name 
    // @event AttributeValueDeleted emitted
    function deleteNFTAttribute(uint256 _tokenId,string memory _traitType) public virtual override {
        bool isExist = attributeTraitTypeExists(_tokenId,_traitType);
        require(isExist == true,"Trait type is not exist!");
        
        
        attributeTraitTypeTemp[_tokenId] = new string[](0);
        attributeTraitValueTemp[_tokenId] = new string[](0);
        for(uint256 i=0;i< attributeTraitType[_tokenId].length;i++){
            if(attributeTraitType[_tokenId].length > 0 && keccak256(abi.encodePacked(attributeTraitType[_tokenId][i])) == keccak256(abi.encodePacked(_traitType))){
                // delete attributeTraitType[_tokenId][i];
                // delete attributeTraitValue[_tokenId][i];
            }
            else{
                attributeTraitTypeTemp[_tokenId].push(attributeTraitType[_tokenId][i]);
                attributeTraitValueTemp[_tokenId].push(attributeTraitValue[_tokenId][i]);
            }
        }

        attributeTraitType[_tokenId] = attributeTraitTypeTemp[_tokenId];
        attributeTraitValue[_tokenId] = attributeTraitValueTemp[_tokenId];

        attributeTraitTypeTemp[_tokenId] = new string[](0);
        attributeTraitValueTemp[_tokenId] = new string[](0);
        
        emit AttributeValueDeleted(_tokenId);
        
    }

    // @notice - This function let knows the TNFT attribute index in array
    // @dev- This is careted for intenal purpose and can also called anyone
    // @param tokenId- It is the id of TNFT
    // @param traitType- It is the TNFT attribute name 
    // return TNFT attribute index in array
    function getAttributeIndex(uint256 _tokenId, string memory _traitType)public view virtual override returns(uint256){
        uint256 index;
        for(uint256 i=0;i< attributeTraitType[_tokenId].length;i++){
            if(attributeTraitType[_tokenId].length  > 0 && keccak256(abi.encodePacked(attributeTraitType[_tokenId][i])) == keccak256(abi.encodePacked(_traitType))){
                index = i;
            }
        }
        return index;
    }

    // @notice - This function is used to let knows the TNFT attribute value
    // @dev Any one can call this function
    // @param tokenId- It is the id of TNFT
    // @param traitType- It is the TNFT attribute name 
    // return TNFT attribute value 
    function getAttributeValue(uint256 _tokenId, string memory _traitType)public view virtual override  returns(string memory){
        require(attributeTraitTypeExists(_tokenId,_traitType) == true,"Attribute not exist");
        uint256 index = getAttributeIndex(_tokenId,_traitType);
        return attributeTraitValue[_tokenId][index];
    }

    // @notice - This function is used to let knows all TNFT attribute values
    // @dev - Any one can call this function
    // @param tokenId- It is the id of TNFT
    // @return the array of all TNFT attribute values
    function getAttributeValues(uint256 _tokenId)public view virtual override returns(string[] memory){
        return attributeTraitValue[_tokenId];
    }

    // @notice - This function is used to let knows all TNFT attribute names
    // @dev - Any one can call this function
    // @param tokenId- It is the id of TNFT
    // @return the array of all TNFT attribute names
    function getAttributeTraitTypes(uint256 _tokenId)public view virtual override returns(string[] memory){
        return attributeTraitType[_tokenId];
    }
}


// @title - The contract for creating the TNFT
// @dev - It implements some buit in contracts and one AssetCustomizationContract contract
// AssetCustomizationContract contract has the TNFT attributes related functions
contract TNFTContract is 
    ERC721,
    ERC721URIStorage, 
    ERC721Burnable, 
    Ownable,
    AssetCustomizationContract 
{
    // @varibales declaration for assetContract
    AssetContract public assetContract;
    address public assetContractAddress;

    // @title - constructor function
    constructor() ERC721("INFINITY RIFT TNFT", "IRTNFT") {
    }

    // @notice - This function is used in the begining . It require to initialze the Asset contract address.
    // @dev - Only the owner of this contract can initize it. It should be call only one time
    function initAssetContract(address _assetContract) public onlyOwner{
        assetContract = AssetContract(_assetContract);
        assetContractAddress = _assetContract;
    }

    // @dev - It is modifier for NFT owner
    modifier onlyNFTOwner (uint256 _tokenId){
        require(ownerOf(_tokenId) == msg.sender ,"unautorized owner");
        _;
    }

    // @dev - It is modifier for NFT owner and NFT user
    modifier onlyUserAndOnlyNFTOwner (uint256 _tokenId){
        if(assetContract.userOf(_tokenId) == address(0)){
            require(ownerOf(_tokenId) == msg.sender,"Invalid owner");
        }else{
            require(assetContract.userOf(_tokenId) == msg.sender || ownerOf(_tokenId) == msg.sender ,"unautorized action");
        }
        _;
    }


    // @dev - This fumction is used to mint the TNFT
    // @parm to - TNFT owner address
    // @param tokenId -  TNFT no.,It can be any number greator than 0.
    // @param uri - It will have the url of token meta data json like IPFS URL
    // @param assetAddress - It is for tying the TNFT with digital or physical asset.  It be set later also.
    // if you do not want to set at time of minting .You can pass the default value address 0x0000000000000000000000000000000000000000 
    // @param addressUser - it is asset user address. It is optional to set at minting time. The default value is address 0x0000000000000000000000000000000000000000 
    // @param traitType - It is the array of TNFT attributes names like Color, Height, Weight etc may be attributes. The default value is [].
    // @param traitValue -It is the array of TNFT attributes values. The default value is [] .
    // @param redemptionStartDate - It the TNFT redemption start date . The default value is 0.
    // @param redemptionEndDate - It the TNFT redemption end date . The default value is 0.
    // @note: only 5 attributes can be added and every attribute character length should not be more than 45.
    // if you want to change it . You can change in AssetCustomizationContract before contract deployment
    function safeMint(
        address to, 
        uint256 tokenId, 
        string memory uri,
        address assetAddress,
        address addressUser,
        string [] memory traitType , 
        string [] memory traitValue,
        uint256 redemptionStartDate,
        uint256 redemptionEndDate
    )
        public
        //onlyOwner
    {
        require(assetContractAddress != address(0),"AssetContract is not intialized !");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        assetContract.afterMint(tokenId,assetAddress,addressUser);
        assetContract.addRedeptionDate(tokenId ,redemptionStartDate, redemptionEndDate);
        super._addTokenAttributes(tokenId,traitType,traitValue);
    }

    // @dev - It is in built internal function
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    // @notice - This function is used to burn the TNFT. When it is burn, all records in other contracts belongs to this , will be deleted 
    // @dev - It can called by TNFT owner or its approved address
    // @parm tokenId- It is the id of TNFT
    function burn(uint256 tokenId) public override(ERC721Burnable){
        require(assetContractAddress != address(0),"AssetContract is not intialized !");

        require(assetContract.getTokenMarketPlaceStatus(tokenId) == 0,"TNFT can not be placed on marketplace or rent place !");
        // require(assetContract.isAssetRedeemed(tokenId) == false,"TNFT is already redeemed!");
        require(assetContract.getRentUser(tokenId)== address(0),"TNFT is on rent. It can not be transfered in Multiverse");

        address user = assetContract.userOf(tokenId);
        address owner = ownerOf(tokenId);
        address spender = msg.sender;
        if(user == address(0)){ // user is not assigned
            require(spender == owner || isApprovedForAll(owner, spender) ||  getApproved(tokenId) == spender,"ERC721: caller is not token owner nor approved");
        }else{
            require(spender == user || spender == assetContract.getUserApproved(tokenId),"ERC721: caller is not token user");
        }
        assetContract.afterBurn(tokenId);
        
        
        _burn(tokenId);
    }

    // @title - It is in-built for updating token url
    // @parm tokenId- It is the id of TNFT
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // @title - It is in-built for updating token url
    // @parm interfaceId - It is the interface Id
    // @return true -if the interface is exist
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721 
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // @notice This function lets the token id is exist or not
    // @dev Anyone can call this function
    // @param tokenId- It is the id of TNFT 
    // @return true if token id exist
    function tookenExist(uint256 _tokenId)public view returns (bool){
        return _exists(_tokenId);
    }

    // @notice This function lets the asset contract address
    // @dev Anyone can call this function
    function getAssetContractAddress() public view returns(address){
        return assetContractAddress;
    }

    // @notice This function is to update the the TNFT redemption start date and end date
    // @dev Only the TNFT owner can call this function
    // @param tokenId- It is the id of TNFT
    // @param redemptionStartDate - It the TNFT redemption start date . 
    // @param redemptionEndDate - It the TNFT redemption end date . 
    function addRedeptionDate(uint256 tokenId ,uint256 redemptionStartDate, uint256 redemptionEndDate) public onlyNFTOwner(tokenId){
        assetContract.addRedeptionDate(tokenId ,redemptionStartDate, redemptionEndDate);
    }

    // ----------------Attribute customization functions start here ---------------

    // @notice - This function is used to add the TNFT attributes
    // @note: only 5 attributes can be added and every attribute character length should not be more than 45.
    // if you want to change it . You can change in AssetCustomizationContract before contract deployment 
    // @dev - Only the TNFT owner can call this function
    // @param tokenId- It is the id of TNFT
    // @param traitType - It is the array of TNFT attributes names like Color, Height, Weight etc may be attributes.
    // @param traitValue -It is the array of TNFT attributes values.    
    function _addTokenAttributes(uint256 _tokenId, string [] memory  _traitType , string [] memory  _traitValue) 
    public override 
    onlyNFTOwner(_tokenId)
    {
        require(_exists(_tokenId), "ERC721: token not minted");
        super._addTokenAttributes(_tokenId,_traitType,_traitValue);

    }
    
    // @notice This function is used updated the TNFT attribute value
    // @dev - Only the TNFT owner or TNFT user can call this function
    // @param tokenId- It is the id of TNFT
    // @param traitType- It is the TNFT attribute name
    // @param traitValue- It is the TNFT attribute value
    function _updateTokenAttributeValue(uint256 _tokenId, string memory traitType,string memory traitValue)public override onlyUserAndOnlyNFTOwner(_tokenId) {
        super._updateTokenAttributeValue(_tokenId,traitType,traitValue);
    }

    // @notice - This function is used to delete the attribute the TNFT
    // @dev - Only the TNFT owner can call this function
    // @param tokenId- It is the id of TNFT
    // @param traitType- It is the TNFT attribute name 
    function deleteNFTAttribute(uint256 _tokenId,string memory _traitType) public override onlyNFTOwner(_tokenId){ 
        super.deleteNFTAttribute(_tokenId,_traitType);
    }

    // ----------------Attribute customization functions end here ---------------

}

// @title - IMetaMultiverse Interface for Meta-Multiverse
interface IMetaMultiverse{

    // @dev struct for source metaverse
    struct delegateData{
        address NFTContractAddress;
        uint256 tokenId;
    }
    // @dev event emits when TNFT is tranfered in MetaMultiverse
    event NFTTransfered(delegateData DelegateData,address newContractAddress , uint256 newTokenId);

    // @notice this function is used to transfer the TNFT from one Metaverse to another metaverse
    // @dev this function can be called by the TNFT user  or if user is not assigned TNFT owner can call this
    // @dev this function have some validation checks like TNFT should not be on rent, IT should not be listed on martketplace for selling , same it should not be on rentplace for renting
    // @dev It should not be redeemed
    // @param DelegateData - it is struct containg the source TNFT metaverse contract addres and token id
    // @param newContractAddress - New mataverse contract address
    // @param newTokenId  new metaverse contract id.
    function transferNFT(delegateData memory DelegateData, address newContractAddress,uint256 newTokenId) external;


}


// title- Contract for implementing the Meta-Multiverse things
// @dev - This contract is required if there is need to transfer the TNFT in Multiverse.
// @dev - It is comptible with ERC-721 NFT Tokens and it also required the Asset Contract
contract MetaMultiverse is IMetaMultiverse{
    
    // @notice this function is used to transfer the TNFT from one Metaverse to another metaverse
    // @dev this function can be called by the TNFT user  or if user is not assigned TNFT owner can call this
    // @dev this function have some validation checks like TNFT should not be on rent, IT should not be listed on martketplace for selling , same it should not be on rentplace for renting
    // @dev It should not be redeemed
    // @param DelegateData - it is struct containg the source TNFT metaverse contract addres and token id
    // @param newContractAddress - New mataverse contract address
    // @param newTokenId  new metaverse contract id.
    function transferNFT(delegateData memory DelegateData, address newContractAddress,uint256 newTokenId)public{
        address NFTContractAddress = DelegateData.NFTContractAddress;
        uint256 tokenId = DelegateData.tokenId;

        require(_isERC721(NFTContractAddress)==true,"NFTContractAddress is not a valid ERC-721 contract address !");
        require(_isERC721(newContractAddress)==true,"newContractAddress is not a valid ERC-721 contract address !");

        address NFTOwner = IERC721(NFTContractAddress).ownerOf(tokenId);
        string memory tokenUri = TNFTContract(NFTContractAddress).tokenURI(tokenId);
        string[] memory attributesTraitTypes =  TNFTContract(NFTContractAddress).getAttributeTraitTypes(tokenId);
        string[] memory attributesValues =  TNFTContract(NFTContractAddress).getAttributeValues(tokenId);

       
        
        address assetContractAddress = TNFTContract(NFTContractAddress).getAssetContractAddress();
        require(assetContractAddress != address(0),"Asset contract is not linked with new NFT contract");

        AssetContract assetContract = AssetContract(assetContractAddress);

        // if the NFT is not sold then its owner.creator can do Multiverse transfer
        if(assetContract.userOf(tokenId) == address(0) ){
            require(NFTOwner == msg.sender,"You are not NFT owner!");
            require(TNFTContract(NFTContractAddress).getApproved(tokenId) == address(this),"You have not aproved to do that action by the owner");
        }else{
            require(assetContract.userOf(tokenId) == msg.sender,"You are not NFT user!");
            require(assetContract.getUserApproved(tokenId) == address(this),"You have not aproved to do that action by the user");

        }
        
        
        // check is item on rent
        require(assetContract.getRentUser(tokenId)== address(0),"TNFT is on rent. It can not be transfered in Multiverse");
        require(assetContract.getTokenMarketPlaceStatus(tokenId) == 0,"TNFT can not be placed on marketplace or rent place !");
        require(assetContract.isAssetRedeemed(tokenId) == false,"TNFT is already redeemed!");


        
        address assetAddress = assetContract.BCAFromTokenID(tokenId);
        address addressUser = assetContract.userOf(tokenId);

        uint256 startDate = assetContract.getTokenRedemptionInfo(tokenId).startDate;
        uint256 endDate = assetContract.getTokenRedemptionInfo(tokenId).endDate;

        TNFTContract(newContractAddress).safeMint(NFTOwner,newTokenId,tokenUri,assetAddress,addressUser,attributesTraitTypes,attributesValues,startDate,endDate);

        
        TNFTContract(NFTContractAddress).burn(tokenId);
        emit NFTTransfered(DelegateData,newContractAddress,newTokenId);
        
    }

    // @notice - It is used to validate a TNFT contract address
    function _isERC721(address contractAddress) internal view returns (bool) {
        return IERC721(contractAddress).supportsInterface(0x80ac58cd);
    }
}