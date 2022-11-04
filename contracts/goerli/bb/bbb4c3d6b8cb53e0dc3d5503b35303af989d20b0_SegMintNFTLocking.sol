/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


////////////////////////////////
////    Import libraries    ////
////////////////////////////////



// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
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

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

contract ERC721Holder is IERC721Receiver {
   
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

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


// import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
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


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
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


// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}







///////////////////////////////////////////////////////////
////    SegMintNFTLocking: Single contract per user    ////
///////////////////////////////////////////////////////////


contract SegMintNFTLocking is  ERC721Holder, ERC1155Holder{ //ERC20Holder,
    
    //////////////////////
    ////    Fields    ////
    //////////////////////

    // owner of NFT wallet address
    address _ownerWalletAddress;

     // staking info
    struct STAKINGINFO {
        // address of staker
        address stakerAddress;
        // staking start date
        uint256 stakingStartDate;
        // stakind end date
        uint256 stakingEndDate;
    }

    // fractioning info
    struct FRACTIONINGINFO {
        // address of fractioner
        address fractionerAddress;
        // fractioned date
        uint256 fractionedDate;
    }

    // NFTs Imported: contractAddress => TokenID => timestamp 0(not imported) / <> 0 (imported)
    mapping(address => mapping(uint256 => uint256)) importedNFTs;

    // Mapping from contractAddress => TokenID => Staking Info
    mapping(address => mapping(uint256 => STAKINGINFO)) private _stakers;

    // Mapping contractAddress =>  TokenID => approved Stakers address
    mapping(address => mapping(uint256 => address)) private _stakersApprovals;

    // Mapping from token ID to approved for all Stakers address
    // mapping(address => mapping(address => bool)) private _stakersApprovalForAll;

    // Mapping from token ID to fractioner address (fractioner can lock/unlock and transfer)
    mapping(address => mapping(uint256 => FRACTIONINGINFO)) private _fractioners;
    
    // Mapping from token ID to approved fractioners address
    mapping(address => mapping(uint256 => address)) private _fractionersApprovals;

    // // Mapping from token ID to approved for fractioners address
    // mapping(address => mapping(address => bool)) private _fractionersApprovalForAll;


    ///////////////////////////
    ////    Constructor    ////
    ///////////////////////////

    constructor() { _ownerWalletAddress = msg.sender;}


    //////////////////////
    ////    Events    ////
    //////////////////////

    // Import NFT //
    event SafeTransferFromEvent(address sender, address SegMintNFTLocking, address contractAddress, uint256 tokenId);


    // Staking events //
    event ApproveStakerEvent(address sender, address approvedStakerAddress, address contractAddress, uint256 tokenId);

    // event ApprovalForAllStakerEvent(address sender, address approveForAllStakerAddress, bool approved);

    event StartStakingEvent(address sender, address contractAddress, uint256 tokenId);

    event EndStakingEvent(address sender, address contractAddress, uint256 tokenId);


    // Fractioning events //
    event ApproveFractionerEvent(address sender, address approvedFractionerAddress, address contractAddress, uint256 tokenId);

    // event ApprovalForAllFractionerEvent(address sender, address approveForAllFractionerAddress, bool approved);

    event FractionerLockEvent(address sender, address contractAddress, uint256 tokenId);

    event FractionerUnlockEvent(address sender, address contractAddress, uint256 tokenId);





    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // Modifier to check that the caller is the owner wallet address.
    modifier onlyOwner() {
        require(msg.sender == _ownerWalletAddress, "Not owner!");
        _;
    }

    // Modifier to check that the caller is the staker .
    modifier onlyStaker(address contractAddress, uint256 tokenId) {
        require(msg.sender == _stakerOf(contractAddress, tokenId), "Not staker!");
        _;
    }

    // Modifier to check that the caller is the fractioner .
    modifier onlyFractioner(address contractAddress, uint256 tokenId) {
        require(msg.sender == _fractionerOf(contractAddress, tokenId), "Not fractioner!");
        _;
    }

    // Modifier to check that the caller is the approved staker .
    modifier onlyApprovedStaker(address contractAddress, uint256 tokenId) {
        require(msg.sender == _stakersApprovals[contractAddress][tokenId], "Not approved staker!");
        _;
    }

    // Modifier to check that the caller is the approved fractioner .
    modifier onlyApprovedFractioner(address contractAddress, uint256 tokenId) {
        require(msg.sender == _fractionersApprovals[contractAddress][tokenId], "Not approved fractioner!");
        _;
    }


    ////////////////////////////////
    ////    Public Functions    ////
    ////////////////////////////////

   ////    Staking Specific TokenID   ////

    function approveStaker(address approveStakerAddress, address contractAddress, uint256 tokenId) public onlyOwner returns(bool){

        // require NFT be imported
        require(isImported(contractAddress, tokenId) ,"NFT is not imported!");
        
        // require approveStakerAddress not be 0 address
        require(approveStakerAddress != address(0), "Cannot approve address(0)");

        // require sender be the owner wallet address
        // require(msg.sender == _ownerWalletAddress, "Sender is not the owner wallet address!");

        // require sender be the owner of the NFT
        // require(IERC721(contractAddress).ownerOf(tokenId) == _ownerWalletAddress, "Sender is not owner!");

        // require NFT be transfered to SegMintNFTLocking contract
        // require(IERC721(contractAddress).ownerOf(tokenId) == address(this), "NFT is not transfered to SegMintNFTLocking contract!");

        // require not staked
        _requireNotStaked(contractAddress, tokenId);

        // require not fractioned
        _requireNotFractioned(contractAddress, tokenId);

        // sender should not be the approveStakerAddress
        require(msg.sender != approveStakerAddress, "ERC721: staker approval to owner, approved, or operator");

        // address of the approved staker
        address currentApprovedStaker = _stakersApprovals[contractAddress][tokenId];

        // address of current approved staker should be address(0)
        require(currentApprovedStaker == address(0), "TokenId is currently approved for a staker");

        // address of the approved fractioner
        address currentApprovedFractioner = _fractionersApprovals[contractAddress][tokenId];

        // require address of current approved fractioner be address(0)
        require(currentApprovedFractioner == address(0), "TokenId is currently approved for a fractioner");
        
        // update approved staker address
        _approveStaker(msg.sender, approveStakerAddress, contractAddress,tokenId);

        // return
        return true;

    }

    function stakerOf(address contractAddress, uint256 tokenId) public view virtual returns (address) {
        
        // require NFT be imported
        require(isImported(contractAddress, tokenId), "NFT is not imported!");

        // address of tokenId  staker
        address staker = _stakerOf(contractAddress, tokenId);

        // return staker
        return staker;
    }

    function getApprovedStaker(address contractAddress, uint256 tokenId) public view virtual returns (address) {    
        
        // require NFT be imported
        require(isImported(contractAddress, tokenId), "NFT is not imported!");

        return _stakersApprovals[contractAddress][tokenId];
    }

    function renounceApprovedStaker(address contractAddress, uint256 tokenId) public returns(bool){
        
        // require NFT be imported
        require(isImported(contractAddress, tokenId), "NFT is not imported!");

        // require approved staker not be address(0)
        require(_stakersApprovals[contractAddress][tokenId] != address(0), "No address is approved for staking!");

        // require sender be the owner wallet address
        require(msg.sender == _ownerWalletAddress, "Sender is not the owner wallet address!");

        // require not staked
        _requireNotStaked(contractAddress, tokenId);

        // require not fractioned
        _requireNotFractioned(contractAddress, tokenId);

        // update approved staker address to address(0) ==> renouncing
        _approveStaker(msg.sender, address(0), contractAddress, tokenId);

        // return
        return true;        

    }



    ////    Fractioner Locking Specific TokenID   ////

    function approveFractioner(address approveFractionerAddress, address contractAddress, uint256 tokenId) public onlyOwner returns(bool){

        // require NFT be imported
        require(isImported(contractAddress, tokenId) ,"NFT is not imported!");

        // require approveFractionerAddress not be 0 address
        require(approveFractionerAddress != address(0), "Cannot approve address(0)");

        // require sender be the owner
        // require(msg.sender == _ownerWalletAddress, "Sender is not the owner wallet address!");

        // require sender be the owner of the NFT
        // require(IERC721(contractAddress).ownerOf(tokenId) == _ownerWalletAddress, "Sender is not owner!");        

        // require NFT be transfered to SegMintNFTLocking contract
        // require(IERC721(contractAddress).ownerOf(tokenId) == address(this), "NFT is not transfered to SegMintNFTLocking contract!");

        // require not fractioned
        _requireNotFractioned(contractAddress, tokenId);

        // require not staked
        _requireNotStaked(contractAddress, tokenId);

        // approveFractionerAddress should not be the current owner
        require(msg.sender != approveFractionerAddress, "ERC721: fractioner approval to owner wallet address!");

        // address of the approved staker
        address currentApprovedStaker = _stakersApprovals[contractAddress][tokenId];

        // require currentApprovedStaker not be securedly approved
        require(currentApprovedStaker == address(0), "TokenId is already approved for a staker!");

        // address of the approved fractioner
        address currentApprovedFractioner = _fractionersApprovals[contractAddress][tokenId];

        // require approveFractionerAddress not be approved
        require(currentApprovedFractioner == address(0), "TokenId is already approved for a fractioner");
        
        // update approved fractioner address
        _approveFractioner(msg.sender, approveFractionerAddress, contractAddress, tokenId);

        // return
        return true;

    }

    function fractionerOf(address contractAddress, uint256 tokenId) public view virtual returns (address) {
        
        // require NFT be imported
        require(isImported(contractAddress, tokenId), "NFT is not imported!");

        // address of tokenId locker
        address fractioner = _fractionerOf(contractAddress, tokenId);

        // return locker
        return fractioner;
    }

    function getApprovedFractioner(address contractAddress, uint256 tokenId) public view virtual returns (address) {    
        
        // require NFT be imported
        require(isImported(contractAddress, tokenId), "NFT is not imported!");

        return _fractionersApprovals[contractAddress][tokenId];
    }

    function renounceApprovedFractioner(address contractAddress, uint256 tokenId) public returns(bool){

        // require NFT be imported
        require(isImported(contractAddress, tokenId), "NFT is not imported!");

        // require approved fractioner not be address(0)
        require(_fractionersApprovals[contractAddress][tokenId] != address(0), "No address is approved for fractioning!");

        // require sender be the owner wallet address
        require(msg.sender == _ownerWalletAddress, "Sender is not the owner wallet address!");

        // require not staked
        _requireNotStaked(contractAddress, tokenId);

        // require not fractioned
        _requireNotFractioned(contractAddress, tokenId);

        // update approved fractioner address
        _approveFractioner(msg.sender, address(0), contractAddress, tokenId);

        // return
        return true;        

    }
    
    
    
    
    ////    Import and Withdraw NFT    ////

    // // approve SegMintNFTLocking in ERC721
    // function approveSegMintNFTLocking(address contractAddress, uint256 tokenId) public onlyOwner returns (bool){

    //     // check if the sender is the owner of the NFT
    //     require(msg.sender == IERC721(contractAddress).ownerOf(tokenId), "Sender is not the NFT owner!");

    //     // approve SegMintNFTLocking contract
    //     IERC721(contractAddress).approve(address(this), tokenId);

    //     // return
    //     return true;
    // }

    // import NFT by NFT owner wallet address
    function importNFTs(address contractAddress, uint256 tokenId) public onlyOwner returns (bool){

        // require sender be the owner
        // require(msg.sender == _ownerWalletAddress, "Sender is not the owner wallet address!");
        
        // check if the owner of the tokenId is the sender
        require(IERC721(contractAddress).ownerOf(tokenId) == msg.sender, "Sender is not the owner!");

        // check if SegMintNFTLocking contract is approved 
        require(address(this) == IERC721(contractAddress).getApproved(tokenId), "SegMintNFTLocking is not approved!");

        // safeTransferFrom NFT to SegMintNFTLocking contract
        IERC721(contractAddress).safeTransferFrom(msg.sender, address(this), tokenId, "");

        // emit Event for safe Transfer
        emit SafeTransferFromEvent(msg.sender, address(this), contractAddress, tokenId);

        // add NFT to the importedNFTs
        importedNFTs[contractAddress][tokenId] = block.timestamp;
        // importedNFTs[contractAddress][tokenId] = NFTInfo({
        //     importedTime : block.timestamp, 
        //     isImported : true,
        //     isStaked: false,
        //     stakingInfo: STAKINGINFO({
        //         stakerAddress: address(0),
        //         stakingStartDate: 0,
        //         stakingEndDate: 0
        //     }),
        //     isFractioned: false,
        //     fractioningInfo: FRACTIONINGINFO({
        //         fractionerAddress: address(0),
        //         fractionedDate: 0
        //     })
        // });

        // return
        return true;

    }

    // this is temporary
    function withdrawNFTs(address contractAddress, uint256 tokenId) public onlyOwner returns (bool){

        // require NFT be imported
        require(isImported(contractAddress, tokenId), "NFT is not imported!");

        // require sender be the owner
        // require(msg.sender == _ownerWalletAddress, "Sender is not the owner wallet address!");

        // require NFT not staked
        _requireNotStaked(contractAddress, tokenId);
        // require(importedNFTs[contractAddress][tokenId].isStaked == false, "NFT is staked!");

        // require NFT not fractioned
        _requireNotFractioned(contractAddress, tokenId);
        // require(importedNFTs[contractAddress][tokenId].isFractioned == false, "NFT is fractioned!");

        // safeTransferFrom NFT to SegMintNFTLocking contract
        IERC721(contractAddress).safeTransferFrom(address(this), msg.sender, tokenId, "");

        // delete NFT from importedNFTs
        // delete importedNFTs[contractAddress][tokenId];
        importedNFTs[contractAddress][tokenId] = 0;

        // update approved staker / fractioner
        _stakersApprovals[contractAddress][tokenId] = address(0);
        _fractionersApprovals[contractAddress][tokenId] = address(0);

        // return
        return true;

    }




    ////    Airdrops/Rewars Withdawal    ////
    
    // withdarw ERC20
    function withdrawERC20(address ERC20ContractAddress, uint256 amount) public onlyOwner returns (bool){

        // require having enough balance
        require(IERC20(ERC20ContractAddress).balanceOf(address(this)) >= amount, "Entered amount is more than the balance!");

        // require amount > 0
        require(amount > 0 , "amount should be greater than zero!");

        // transfer amount to NFT owner
        IERC20(ERC20ContractAddress).transferFrom(address(this), _ownerWalletAddress, amount);

        // return
        return true;
    }

    // withdraw ERC721 (except the ones imported)
    function withdrawERC721(address ERC721ContractAddress, uint256 tokenId) public onlyOwner returns (bool){

        // require holding that NFT tokenId
        require(IERC721(ERC721ContractAddress).ownerOf(tokenId) == address(this) , "NFT is not held in your SegMintNFTLocking contract!");

        // require this NFT is either Airdrops or Rewards NOT the imported NFTs
        require(importedNFTs[ERC721ContractAddress][tokenId] == 0, "This NFT is not Airdrop nor Reward, this is an imported NFT by owner!");

        // transfer NFT
        IERC721(ERC721ContractAddress).safeTransferFrom(address(this), _ownerWalletAddress, tokenId, "");

        // return
        return true;
    }

    // withdraw ERC1155
    function withdrawERC1155(address ERC1155ContractAddress, uint256 tokenId, uint256 amount) public onlyOwner returns (bool){

        // require having enough balance
        require(IERC1155(ERC1155ContractAddress).balanceOf(address(this), tokenId) >= amount, "Entered amount is more thant the balance!");

        // require amount > 0
        require(amount > 0, "amount should be greater than zero!");
        // transfer amount to NFT owner
        IERC1155(ERC1155ContractAddress).safeTransferFrom(address(this), _ownerWalletAddress, tokenId, amount, "");

        // return
        return true;
    }





    ////    Getters    ////

    // get owner Wallet Address
    function getOwnerWalletAddress() public view  returns (address) { return _ownerWalletAddress; }
    
    // get SegMint Locking contract address
    function getSegMintNFTLockingAddress() public view returns (address) { return address(this); }

    //  isImported NFT
    function isImported(address contractAddress, uint256 tokenId) public view returns(bool) {
        return importedNFTs[contractAddress][tokenId] > 0;
    }

    // isStaked NFT
    function isStaked(address contractAddress, uint256 tokenId) public view returns(bool){
        // return importedNFTs[contractAddress][tokenId].isStaked;
        return _stakerOf(contractAddress, tokenId) != address(0);
    }

    // get staker address
    function getStakerAddress(address contractAddress, uint256 tokenId) public view returns(address){
        // return importedNFTs[contractAddress][tokenId].stakingInfo.stakerAddress;
        return _stakers[contractAddress][tokenId].stakerAddress;
    }

    // get staked NFT start date
    function getStakingStartDate(address contractAddress, uint256 tokenId) public view returns(uint256){
        // return importedNFTs[contractAddress][tokenId].stakingInfo.stakingStartDate;
        return _stakers[contractAddress][tokenId].stakingStartDate;
    }

    // get staked NFT end date
    function getStakingEndDate(address contractAddress, uint256 tokenId) public view returns(uint256){
        // return importedNFTs[contractAddress][tokenId].stakingInfo.stakingEndDate;
        return _stakers[contractAddress][tokenId].stakingEndDate;
    }

    // isFractioned NFT
    function isFractioned(address contractAddress, uint256 tokenId) public view returns(bool){
        // return importedNFTs[contractAddress][tokenId].isFractioned;
        return _fractionerOf(contractAddress, tokenId) != address(0);
    }

    // get fractioner address
    function getFractionerAddress(address contractAddress, uint256 tokenId) public view returns(address){
        // return importedNFTs[contractAddress][tokenId].fractioningInfo.fractionerAddress;
        return _fractioners[contractAddress][tokenId].fractionerAddress;
    }

    // get fractioned date
    function getFractionedDate(address contractAddress, uint256 tokenId) public view returns(uint256){
        // return importedNFTs[contractAddress][tokenId].fractioningInfo.fractionedDate;
        return _fractioners[contractAddress][tokenId].fractionedDate;
    }




    ////    Staking tokenId   ////

    function stakerLock(address contractAddress, uint256 tokenId, uint256 endDate) public returns(bool){

        // require NFT be imported
        require(isImported(contractAddress, tokenId), "NFT is not imported!");
        
        // require not staked
        _requireNotStaked(contractAddress, tokenId);

        // require not fractioned
        _requireNotFractioned(contractAddress, tokenId);

        // require sender be an approved staker for the tokenId
        require(msg.sender == getApprovedStaker(contractAddress, tokenId), "Sender is not approved as a staker");

        // update _stakers
        _stakers[contractAddress][tokenId].stakerAddress = msg.sender;
        _stakers[contractAddress][tokenId].stakingStartDate = block.timestamp;
        _stakers[contractAddress][tokenId].stakingEndDate = uint256(endDate);

        // update approvedStaker to address(0)
        _stakersApprovals[contractAddress][tokenId] = address(0);

        // emit event
        emit StartStakingEvent(msg.sender, contractAddress, tokenId);

        // return
        return true;
    }
    
    function stakerUnlock(address contractAddress, uint256 tokenId) public returns(bool){

        // require NFT be imported
        require(isImported(contractAddress, tokenId), "NFT is not imported!");

        // require NFT be staked
        require(isStaked(contractAddress, tokenId), "NFT is not staked!");

        // before end date only staker can unstake and 
        // afeter end date owner/approved/operator can unstake
        if(_stakers[contractAddress][tokenId].stakingEndDate <= block.timestamp){

            // require sender be the owner
            require(msg.sender == _ownerWalletAddress || msg.sender == _stakerOf(contractAddress, tokenId), "Sender is not the owner or staker!");

        }else{
            
            // require sender be the staker for the tokenId
            require(msg.sender == _stakerOf(contractAddress, tokenId), "Sender is not the staker!");
        
        }

        // update staking info ==> Unstake or remove staker 
        _stakers[contractAddress][tokenId].stakerAddress = address(0);
        _stakers[contractAddress][tokenId].stakingStartDate = 0;
        _stakers[contractAddress][tokenId].stakingEndDate = 0;

        // emit event
        emit EndStakingEvent(msg.sender, contractAddress,tokenId);

        // return
        return true;
    }


    ////    fractioner Lock/Unlock tokenId     ////

    function fractionerLock(address contractAddress, uint256 tokenId) public returns(bool){

        // require NFT be imported
        require(isImported(contractAddress, tokenId), "NFT is not imported!");

        // require not staked
        _requireNotStaked(contractAddress, tokenId);

        // require not fractioned
        _requireNotFractioned(contractAddress, tokenId);

        // require sender be a fractioner approved for the tokenId
        require(msg.sender == getApprovedFractioner(contractAddress, tokenId), "Sender is not approved as an fractioner");

        // update _fractioner
        _fractioners[contractAddress][tokenId].fractionerAddress = msg.sender;
        _fractioners[contractAddress][tokenId].fractionedDate = block.timestamp;

        // update approvedFractioner to address(0)
        _fractionersApprovals[contractAddress][tokenId] = address(0);

        // emit event
        emit FractionerLockEvent(msg.sender, contractAddress, tokenId);

        // return
        return true;
    }
    
    function fractionerUnlock(address contractAddress, uint256 tokenId) public returns(bool){

        // require NFT be imported
        require(isImported(contractAddress, tokenId), "NFT is not imported!");

        // require NFT be fractioned
        require(isFractioned(contractAddress, tokenId), "NFT is not fractioned!");

        // require sender be the fractioner for the tokenId
        require(msg.sender == _fractionerOf(contractAddress, tokenId), "Sender is not the fractioner");

        // update fractioner 
        _fractioners[contractAddress][tokenId].fractionerAddress = address(0);
        _fractioners[contractAddress][tokenId].fractionedDate = 0;

        // emit event
        emit FractionerUnlockEvent(msg.sender, contractAddress, tokenId);

        // return
        return true;
    }

    function fractionerUnlockAndTransfer(address contractAddress, uint256 tokenId, address _transferToAddress) public returns(bool){

        // require NFT be imported
        require(isImported(contractAddress, tokenId), "NFT is not imported!");

        // require NFT be fractioned
        require(isFractioned(contractAddress, tokenId), "NFT is not fractioned!");
        
        // require sender be the fractioner for the tokenId
        require(msg.sender == _fractionerOf(contractAddress, tokenId), "Sender is not the fractioner");

        // transfer tokenId to an address
        IERC721(contractAddress).safeTransferFrom(address(this), _transferToAddress, tokenId);

        // update fractioner 
        _fractioners[contractAddress][tokenId].fractionerAddress = address(0);
        _fractioners[contractAddress][tokenId].fractionedDate = 0;

        // emit event
        emit FractionerUnlockEvent(msg.sender, contractAddress, tokenId);

        // return
        return true;
    }








    /////////////////////////////////
    ////    Private Functions    ////
    /////////////////////////////////

    // require not staked token
    function _requireNotStaked(address contractAddress, uint256 tokenId) internal view virtual {
        require(_stakerOf(contractAddress, tokenId) == address(0), "TokenId is staked");
    } 

    // _stakerOf
    function _stakerOf(address contractAddress, uint256 tokenId) internal view virtual returns (address) {
        return _stakers[contractAddress][tokenId].stakerAddress;
    }

    // approve staker
    function _approveStaker(address sender, address approveStakerAddress, address contractAddress, uint256 tokenId) internal virtual {
        
        // update approved staker
        _stakersApprovals[contractAddress][tokenId] = approveStakerAddress;

        // emit
        emit ApproveStakerEvent(sender, approveStakerAddress, contractAddress, tokenId);
    }
    
    // require not fractioned
    function _requireNotFractioned(address contractAddress, uint256 tokenId) internal view virtual {
        require(_fractionerOf(contractAddress, tokenId) == address(0), "TokenId is locked by fractioner");
    }

    // _fractionerOf
    function _fractionerOf(address contractAddress, uint256 tokenId) internal view virtual returns (address) {
        return _fractioners[contractAddress][tokenId].fractionerAddress;
    }

    // approve fractioner
    function _approveFractioner(address sender, address approveFractionerAddress, address contractAddress, uint256 tokenId) internal virtual {
        
        // update approved fractioner
        _fractionersApprovals[contractAddress][tokenId] = approveFractionerAddress;

        // emit
        emit ApproveFractionerEvent(sender, approveFractionerAddress, contractAddress, tokenId);
    }
     

}