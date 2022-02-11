/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT
/*

██╗    ██╗ █████╗  ██████╗██╗  ██╗██╗
██║    ██║██╔══██╗██╔════╝██║ ██╔╝██║
██║ █╗ ██║███████║██║     █████╔╝ ██║
██║███╗██║██╔══██║██║     ██╔═██╗ ╚═╝
╚███╔███╔╝██║  ██║╚██████╗██║  ██╗██╗
 ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝
        By Devko.dev#7286                    
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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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

// File: contract.sol


pragma solidity ^0.8.2;


contract WACK is ERC721, ERC1155Holder, Ownable {
    using Counters for Counters.Counter;
    mapping(uint256 => uint256) public tokenIds;
    using Strings for uint256;
    string private _tokenBaseURI = "https://gateway.pinata.cloud/ipfs/QmbHhnkMmeZ3WPNnZoHr5YqAyHApPhPaAEJth4qqPdAQvk/";
    uint256 public WACK_MAX = 26;
    uint256 public WACK_PRICE = 0.15 ether;
    mapping(address => bool) public WHITELIST;
    bool public mintLive;
    bool public mintWLLive;
    Counters.Counter public _tokensMinted;

    constructor() ERC721("WACK", "WACK") {
        WHITELIST[0xd12BF6b7D7F4D8F8BDe032CD6CDd06aF298A8F7f] = true;
        WHITELIST[0xF1c77f664a05ba2Cb11B00a9583Fec8b85a0d5c2] = true;
        WHITELIST[0x874fd599ea7b6c34FA5DAfd8d08Da89Da0A61B7f] = true;
        WHITELIST[0xA9263191b5cAfcc0BE2C8F72245124472F3C9082] = true;
        WHITELIST[0xc29e526E7F60C9941E8086197c05944f21d85Eb6] = true;
        WHITELIST[0x5C854cd12bf090A604d6f526FaA5Fe07F29Fdb29] = true;
        WHITELIST[0x84C885ceD0010564F6E729A2553A06153B18B917] = true;
        WHITELIST[0x3A8B8d1d156477BF6Fd20f248eF8b2f1d03fB251] = true;
        WHITELIST[0x700e1C20FbB2a273f7dec0Cec6333F99B9141ed3] = true;
        WHITELIST[0x8983ad6D63D7AB3701D74E1E72Fd9DaDF113F3F9] = true;
        WHITELIST[0xD1d6c35052f2c21d3B5652B2C1F50b075E51D842] = true;
        WHITELIST[0x54D031E6e03b4Dc8f8BB318FA5410c46aF063bfD] = true;
        WHITELIST[0xFC8723d8278D470Db2768455b5CB6a876Dd76755] = true;
        WHITELIST[0x76Fb3c5ABe51698f18eB8Cf34B0e6f079Aa273CF] = true;
        WHITELIST[0x5A6fE598c161923d355cb82B4323299894Fab15F] = true;
        WHITELIST[0x85C385dA631F7CF7436304480040d2F36B791336] = true;
        WHITELIST[0xf941F9b6A5ad002C1f40e09510d6a298B0880651] = true;
        WHITELIST[0x87a4Fa61CBF1BEB104a66e096da26229c636efb5] = true;
        WHITELIST[0x60dA1A6e343Ae0269e86395f7fccCd77F6824b67] = true;
        WHITELIST[0x08c3d4a4fE4e28F4ea0402fcCF35D5B81E8f1EC8] = true;
        WHITELIST[0xBAaEac4Dd925D0BA9CD608Dbe3C390e6E4fa2816] = true;
        WHITELIST[0xeA5BF3c40d34AA3397F5306FF7e9A34943cB61E6] = true;
        WHITELIST[0x85400bd71e1a94802E6C9eaD32a6F79b74B6D787] = true;
        WHITELIST[0xf958C5EB003C527488E887605aB55fD76B6B9e88] = true;
        WHITELIST[0xcd5F8Ab0C26639F8fAf89a0D373cD1e7AB18d6eE] = true;
        WHITELIST[0xa949697af62155768Cf95A074738930CB9Cd497C] = true;

        tokenIds[37113267255361574183604483851777514579287633297905833288271730518549422145537] = 174;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730517449910517761] = 173;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730516350398889985] = 172;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730515250887262209] = 171;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730514151375634433] = 170;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730513051864006657] = 169;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730511952352378881] = 168;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730510852840751105] = 167;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730509753329123329] = 166;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730508653817495553] = 165;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730507554305867777] = 164;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730506454794240001] = 163;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730505355282612225] = 162;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730504255770984449] = 161;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730503156259356673] = 160;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730502056747728897] = 159;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730500957236101121] = 158;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730499857724473345] = 157;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730498758212845569] = 156;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730497658701217793] = 155;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730496559189590017] = 154;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730495459677962241] = 153;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730494360166334465] = 152;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730493260654706689] = 151;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730492161143078913] = 150;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730491061631451137] = 149;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730489962119823361] = 148;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730488862608195585] = 147;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730487763096567809] = 146;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730486663584940033] = 145;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730485564073312257] = 144;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730484464561684481] = 143;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730483365050056705] = 142;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730482265538428929] = 141;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730481166026801153] = 140;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730480066515173377] = 139;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730478967003545601] = 138;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730477867491917825] = 137;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730476767980290049] = 136;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730475668468662273] = 135;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730474568957034497] = 134;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730473469445406721] = 133;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730472369933778945] = 132;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730471270422151169] = 131;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730470170910523393] = 130;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730469071398895617] = 129;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730467971887267841] = 128;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730466872375640065] = 127;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730465772864012289] = 126;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730464673352384513] = 125;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730463573840756737] = 124;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730462474329128961] = 123;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730461374817501185] = 122;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730460275305873409] = 121;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730459175794245633] = 120;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730458076282617857] = 119;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730456976770990081] = 118;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730455877259362305] = 117;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730454777747734529] = 116;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730453678236106753] = 115;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730452578724478977] = 114;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730451479212851201] = 113;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730450379701223425] = 112;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730449280189595649] = 111;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730448180677967873] = 110;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730447081166340097] = 109;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730445981654712321] = 108;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730444882143084545] = 107;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730443782631456769] = 106;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730442683119828993] = 105;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730441583608201217] = 104;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730440484096573441] = 103;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730439384584945665] = 102;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730438285073317889] = 101;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730437185561690113] = 100;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730436086050062337] = 99;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730434986538434561] = 98;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730433887026806785] = 97;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730432787515179009] = 96;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730431688003551233] = 95;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730430588491923457] = 94;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730429488980295681] = 93;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730428389468667905] = 92;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730427289957040129] = 91;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730426190445412353] = 90;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730425090933784577] = 89;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730423991422156801] = 88;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730422891910529025] = 87;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730421792398901249] = 86;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730420692887273473] = 85;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730419593375645697] = 84;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730418493864017921] = 83;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730417394352390145] = 82;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730416294840762369] = 81;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730415195329134593] = 80;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730414095817506817] = 79;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730412996305879041] = 78;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730411896794251265] = 77;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730410797282623489] = 76;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730409697770995713] = 75;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730408598259367937] = 74;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730407498747740161] = 73;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730406399236112385] = 72;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730405299724484609] = 71;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730404200212856833] = 70;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730403100701229057] = 69;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730402001189601281] = 68;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730400901677973505] = 67;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730399802166345729] = 66;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730398702654717953] = 65;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730397603143090177] = 64;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730396503631462401] = 63;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730395404119834625] = 62;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730394304608206849] = 61;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730393205096579073] = 60;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730392105584951297] = 59;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730382209980301313] = 58;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730381110468673537] = 57;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730380010957045761] = 56;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730378911445417985] = 55;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730377811933790209] = 54;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730376712422162433] = 53;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730375612910534657] = 52;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730374513398906881] = 51;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730373413887279105] = 50;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730372314375651329] = 49;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730371214864023553] = 48;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730370115352395777] = 47;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730369015840768001] = 46;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730367916329140225] = 45;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730366816817512449] = 44;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730365717305884673] = 43;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730364617794256897] = 42;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730363518282629121] = 41;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730362418771001345] = 40;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730361319259373569] = 39;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730360219747745793] = 38;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730359120236118017] = 37;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730358020724490241] = 36;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730356921212862465] = 35;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730355821701234689] = 34;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730354722189606913] = 33;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730353622677979137] = 32;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730352523166351361] = 30;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730351423654723585] = 31;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730350324143095809] = 29;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730349224631468033] = 28;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730348125119840257] = 27;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730347025608212481] = 26;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730345926096584705] = 25;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730344826584956929] = 24;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730343727073329153] = 23;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730342627561701377] = 22;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730341528050073601] = 21;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730340428538445825] = 20;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730339329026818049] = 19;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730338229515190273] = 18;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730337130003562497] = 16;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730334930980306945] = 17;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730333831468679169] = 15;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730332731957051393] = 14;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730331632445423617] = 13;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730330532933795841] = 12;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730329433422168065] = 11;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730328333910540289] = 10;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730327234398912513] = 9;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730326134887284737] = 8;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730325035375656961] = 7;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730323935864029185] = 6;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730322836352401409] = 5;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730321736840773633] = 4;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730320637329145857] = 3;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730319537817518081] = 2;
        tokenIds[37113267255361574183604483851777514579287633297905833288271730318438305890305] = 1;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function changeId(uint256 oldId, uint256 newId) external onlyOwner {
            tokenIds[oldId] = newId;
    }

    function onERC1155Received(address, address from, uint256 id, uint256, bytes calldata) public override returns (bytes4) {
        require(msg.sender == 0x495f947276749Ce646f68AC8c248420045cb7b5e, "INVALID_NFT_CONTRACT");
        require(tokenIds[id] > 0, "INVALID_NFT_ID");
        _safeMint(from, tokenIds[id]);
        return this.onERC1155Received.selector;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mint() external payable {
        require(mintLive, "MINT_CLOSED");
        require(_tokensMinted.current() + 1 <= WACK_MAX, "EXCEED_MAX");
        require(WACK_PRICE <= msg.value, "INSUFFICIENT_ETH");
        _tokensMinted.increment();
        _safeMint(msg.sender, _tokensMinted.current() + 174);
    }

    function mintWL() external payable {
        require(mintWLLive, "MINT_CLOSED");
        require(_tokensMinted.current() + 1 <= WACK_MAX, "EXCEED_MAX");
        require(WHITELIST[msg.sender], "NOT_WHITLISED");
        require(WACK_PRICE <= msg.value, "INSUFFICIENT_ETH");
        _tokensMinted.increment();
        _safeMint(msg.sender, _tokensMinted.current() + 174);
    }

    function togglePublicMintStatus() external onlyOwner {
        mintLive = !mintLive;
    }

    function toggleWLMintStatus() external onlyOwner {
        mintWLLive = !mintWLLive;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        WACK_PRICE = newPrice;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    function totalSupply() public view returns (uint256) {
        return _tokensMinted.current();
    }

    receive() external payable {}
}