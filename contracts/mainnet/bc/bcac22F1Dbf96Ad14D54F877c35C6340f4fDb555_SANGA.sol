// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SANSoulbindable.sol";

interface ISAN is SANSoulbindable {
    function tokenLevel(uint256 _tokenId)
        external
        view
        returns (SoulboundLevel _level);

    function ownerOf(uint256 _tokenId) external view returns (address owner);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISANGA {
    enum SaleState {
        Paused, // 0
        Open    // 1
    }

    event SaleStateChanged(
        SaleState newSaleState
    );

    error EpochIsNotMintable(uint256 epoch);
    error ExceedsMaxRoyaltiesPercentage();
    error SalePhaseNotActive();
    error TokenAlreadyUsedThisEpoch(uint256 tokenId);
    error TokenIsNotGold(uint256 tokenId);
    error TokenIsNotSoulbound(uint256 tokenId);
    error TokenIsNotOwned(uint256 tokenId);
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract SAN1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     */
    function _mintSimple(
        uint256 id,
        uint256 amount
    ) internal virtual {
        _balances[id][_msgSender()] += amount;
        emit TransferSingle(_msgSender(), address(0), _msgSender(), id, amount);
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
 * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _mintBatchSimple(
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        for (uint256 i = 0; i < ids.length; ++i) {
            _balances[ids[i]][_msgSender()] += amounts[i];
        }
        emit TransferBatch(_msgSender(), address(0), _msgSender(), ids, amounts);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/***
 *    ███████╗ █████╗ ███╗   ██╗ ██████╗  █████╗
 *    ██╔════╝██╔══██╗████╗  ██║██╔════╝ ██╔══██╗
 *    ███████╗███████║██╔██╗ ██║██║  ███╗███████║
 *    ╚════██║██╔══██║██║╚██╗██║██║   ██║██╔══██║
 *    ███████║██║  ██║██║ ╚████║╚██████╔╝██║  ██║
 *    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
 *
 * cromagnus the name
 * mystery in his brush strokes
 * art must always flow
 */

import "./SAN1155.sol";
import "./token/ERC2981ContractWideRoyalties.sol";
import "./token/TokenRescuer.sol";
import "./ISAN.sol";
import "./SANSoulbindable.sol";
import "./ISANGA.sol";

/**
 * @title SANGA by Cromagnus
 * @author Aaron Hanson <[email protected]> @CoffeeConverter
 */
contract SANGA is
    ISANGA,
    SAN1155,
    ERC2981ContractWideRoyalties,
    TokenRescuer,
    SANSoulbindable
{
    /// The maximum ERC-2981 royalties percentage (two decimals).
    uint256 public constant MAX_ROYALTIES_PCT = 333; // 3.33%

    /// The SAN contract.
    ISAN public immutable SAN;

    /// The start time of the first minting epoch.
    uint256 immutable public FLOW_ORIGINATION_TIME;

    /// The length of a minting epoch.
    uint256 immutable public FLOW_RATE;

    /// The token name.
    string public name;

    /// The token symbol.
    string public symbol;

    /// The contract URI for contract-level metadata.
    string public contractURI;

    /// The token sale state (0=Paused, 1=Open).
    SaleState public saleState = SaleState.Open;

    /// Tracks which minting epochs have been skipped.
    mapping(uint256 => bool) private epochSkipped;

    /// Tracks which SAN tokens have been used to mint in this epoch.
    /// epoch => bitfield array
    mapping(uint256 => uint256[40]) private epochSanUsed;

    uint256[40] private sanGoldTokenBitfield = [
        36893488147419103232,
        11150373928493307355683732040131241033334784,
        2305843009213693952,
        1606938044258990275541962092341162602522202993782792835301376,
        55213970774324510299478046898216203619608871796705905555134260602470400,
        21267647932558658688827395834130726912,
        205688069665150755269371147819668813122841983204197482918576128,
        1725438232202198268064731120538439917384279064465366950225789614817280,
        0,
        441711766194596180475538996311607334714920236071836368927967390581391360,
        28269553036454155550626057352616065595456100367924597067487529538800320512,
        452312848583266388373324160190187140051835877600177796092245021597705961472,
        784637716923424298460267800393524444885885024004028235776,
        11692013098647223345629478661730264157247460343808,
        187437584987688299259622580400326207078187935989760,
        514220174162876888173427869550470107021738738992833002368795136,
        1461501648222607500259002564945408316080753213440,
        102844034834071955311312418498074979830122465414226416383295488,
        10889077279844899109449015681787216527362,
        27606985387162267410077494795375679823640796408330383623876468071727104,
        79228162514264337593543950336,
        57896044618658097711785492504343953926634992332820282019728792003956564819968,
        6277101735386680763835789423207666416102355444466181996545,
        40728227292489011044181186969600,
        2147549184,
        13164036483089576991093975194192356474276505269525381895124156416,
        12855504354071922204335696738729300820187068683228081972838912,
        21778071482940216404160885548167527923712,
        2722258935525964032735525534641233608740,
        862718704724959803824391304722084463551968387438819483148461178617856,
        3369993333394596315640628243330772752694576644254665679320626757633,
        36028938752884736,
        0,
        2993155353253689176481146537402947624255349864792064,
        411376139330488582748320651213029957181100864178446488307761664,
        14474011154717180573780651719434947495500583299404132133890181186165372092416,
        365380984519025362206706592108638917004359630848,
        10385861367669883486462489361645568,
        383123885216472214589749016064406509268076358556188672,
        0
    ];

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _baseURI,
        address _royaltiesReceiver,
        uint256 _royaltiesPercent,
        uint256 _flowOriginationTime,
        uint256 _flowRate,
        address _sanContract
    )
        SAN1155(_baseURI)
    {
        name = _name;
        symbol = _symbol;
        contractURI = _contractURI;
        setRoyalties(
            _royaltiesReceiver,
            _royaltiesPercent
        );
        FLOW_ORIGINATION_TIME = _flowOriginationTime;
        FLOW_RATE = _flowRate;
        SAN = ISAN(_sanContract);
    }

    /**
     * @notice Mints SANGA tokens.
     * @param _sanIdsForGold SAN token IDs to be used to mint gold SANGA.
     * @param _sanIdsForColor SAN token IDs to be used to mint color SANGA.
     * @param _sanIdsForMono SAN token IDs to be used to mint monochrome SANGA.
     */
    function mint(
        uint256[] calldata _sanIdsForGold,
        uint256[] calldata _sanIdsForColor,
        uint256[] calldata _sanIdsForMono
    )
        external
    {
        if (saleState == SaleState.Paused) revert SalePhaseNotActive();

        uint256 epoch = _currentEpoch();
        if (epochIsMintable(epoch) == false) revert EpochIsNotMintable(epoch);

        unchecked {
            for (uint i = 0; i < _sanIdsForGold.length; ++i) {
                uint256 tokenId = _sanIdsForGold[i];

                if (!sanTokenIsGold(tokenId))
                    revert TokenIsNotGold(tokenId);

                if (tokenWasUsedInEpoch(epoch, tokenId))
                    revert TokenAlreadyUsedThisEpoch(tokenId);

                if (SAN.ownerOf(tokenId) != _msgSender())
                    revert TokenIsNotOwned(tokenId);

                _setTokenUsedThisEpoch(tokenId);
            }

            for (uint i = 0; i < _sanIdsForColor.length; ++i) {
                uint256 tokenId = _sanIdsForColor[i];

                if (tokenWasUsedInEpoch(epoch, tokenId))
                    revert TokenAlreadyUsedThisEpoch(tokenId);

                if (SAN.ownerOf(tokenId) != _msgSender())
                    revert TokenIsNotOwned(tokenId);

                if (SAN.tokenLevel(tokenId) == SoulboundLevel.Unbound)
                    revert TokenIsNotSoulbound(tokenId);

                _setTokenUsedThisEpoch(tokenId);
            }

            for (uint i = 0; i < _sanIdsForMono.length; ++i) {
                uint256 tokenId = _sanIdsForMono[i];

                if (tokenWasUsedInEpoch(epoch, tokenId))
                    revert TokenAlreadyUsedThisEpoch(tokenId);

                if (SAN.ownerOf(tokenId) != _msgSender())
                    revert TokenIsNotOwned(tokenId);

                _setTokenUsedThisEpoch(tokenId);
            }

            uint256 idCount;
            if (_sanIdsForMono.length > 0) ++idCount;
            if (_sanIdsForColor.length > 0) ++idCount;
            if (_sanIdsForGold.length > 0) ++idCount;

            if (idCount == 1) {
                if (_sanIdsForMono.length > 0) {
                    _mintSimple(currentMonoTokenId(), _sanIdsForMono.length);
                }
                else if (_sanIdsForColor.length > 0) {
                    _mintSimple(currentColorTokenId(), _sanIdsForColor.length);
                }
                else {
                    _mintSimple(currentGoldTokenId(), _sanIdsForGold.length);
                }
            }
            else {
                uint256[] memory ids = new uint256[](idCount);
                uint256[] memory amounts = new uint256[](idCount);
                uint256 curIndex;

                if (_sanIdsForMono.length > 0) {
                    ids[curIndex] = currentMonoTokenId();
                    amounts[curIndex] = _sanIdsForMono.length;
                    ++curIndex;
                }
                if (_sanIdsForColor.length > 0) {
                    ids[curIndex] = currentColorTokenId();
                    amounts[curIndex] = _sanIdsForColor.length;
                    ++curIndex;
                }
                if (_sanIdsForGold.length > 0) {
                    ids[curIndex] = currentGoldTokenId();
                    amounts[curIndex] = _sanIdsForGold.length;
                }

                _mintBatchSimple(ids, amounts);
            }
        }
    }

    /**
     * @notice (only owner) Sets the contract URI for contract metadata.
     * @param _newContractURI The new contract URI.
     */
    function setContractURI(
        string calldata _newContractURI
    )
        external
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    /**
     * @notice (only owner) Sets if an epoch should be skipped (non-mintable).
     * @param _epoch The epoch.
     * @param _isSkipped Whether or not the epoch should be skipped.
     */
    function setEpochSkipped(
        uint256 _epoch,
        bool _isSkipped
    )
        external
        onlyOwner
    {
        epochSkipped[_epoch] = _isSkipped;
    }


    /**
     * @notice (only owner) Sets the saleState to `_newSaleState`.
     * @param _newSaleState The new sale state
     * (0=Paused, 1=Open).
     */
    function setSaleState(
        SaleState _newSaleState
    )
        external
        onlyOwner
    {
        saleState = _newSaleState;
        emit SaleStateChanged(_newSaleState);
    }

    /**
     * @notice (only owner) Sets the token URI for token metadata.
     * @param _newURI The new URI.
     */
    function setURI(
        string calldata _newURI
    )
        external
        onlyOwner
    {
        _setURI(_newURI);
    }

    /**
     * @notice Returns the current minting epoch number.
     * @return epoch_ The current minting epoch number.
     */
    function currentEpoch()
        external
        view
        returns (uint256 epoch_)
    {
        epoch_ = _currentEpoch();
    }

    /**
     * @notice Zeroes out token IDs user already minted with this epoch.
     * @param _sanTokenIds The list of SAN token IDs to check.
     * @return unusedTokenIds_ The token ID list with used ones zeroed out.
     */
    function tokensUnusedThisEpoch(
        uint256[] calldata _sanTokenIds
    )
        external
        view
        returns (uint256[] memory unusedTokenIds_)
    {
        uint256 epoch = _currentEpoch();
        unusedTokenIds_ = new uint256[](_sanTokenIds.length);
        unchecked {
            for(uint i = 0; i < _sanTokenIds.length; ++i) {
                uint256 tokenId = _sanTokenIds[i];
                if (tokenWasUsedInEpoch(epoch, tokenId) == false) {
                    unusedTokenIds_[i] = tokenId;
                }
            }
        }
    }

    /**
     * @notice (only owner) Sets ERC-2981 royalties recipient and percentage.
     * @param _recipient The address to which to send royalties.
     * @param _value The royalties percentage (two decimals, e.g. 1000 = 10%).
     */
    function setRoyalties(
        address _recipient,
        uint256 _value
    )
        public
        onlyOwner
    {
        if (_value > MAX_ROYALTIES_PCT) revert ExceedsMaxRoyaltiesPercentage();

        _setRoyalties(
            _recipient,
            _value
        );
    }

    /**
     * @notice Gets the current Gold SANGA token ID.
     * @return _tokenId The current Gold SANGA token ID.
     */
    function currentGoldTokenId()
        public
        view
        returns (uint256 _tokenId)
    {
        unchecked {
            return 3 + _currentEpoch() * 10;
        }
    }

    /**
     * @notice Gets the current Color SANGA token ID.
     * @return _tokenId The current Color SANGA token ID.
     */
    function currentColorTokenId()
        public
        view
        returns (uint256 _tokenId)
    {
        unchecked {
            return 2 + _currentEpoch() * 10;
        }
    }

    /**
     * @notice Gets the current Mono SANGA token ID.
     * @return _tokenId The current Mono SANGA token ID.
     */
    function currentMonoTokenId()
        public
        view
        returns (uint256 _tokenId)
    {
        unchecked {
            return 1 + _currentEpoch() * 10;
        }
    }

    /**
     * @notice Checks if the current epoch is mintable.
     * @return isMintable_ True if the current epoch is mintable.
     */
    function currentEpochIsMintable()
        public
        view
        returns (bool isMintable_)
    {
        uint256 epoch = _currentEpoch();
        isMintable_ = epochIsMintable(epoch);
    }

    /**
     * @notice Checks if an epoch is mintable.
     * @param _epoch The epoch number to check.
     * @return isMintable_ True if the epoch is mintable.
     */
    function epochIsMintable(
        uint256 _epoch
    )
        public
        view
        returns (bool isMintable_)
    {
        isMintable_ = _epoch > 0 && epochSkipped[_epoch] == false;
    }

    /**
     * @notice Checks if a SAN token ID is a gold character.
     * @param _sanTokenId The SAN token ID to check.
     * @return isGold_ True if the SAN token ID is a gold character.
     */
    function sanTokenIsGold(
        uint256 _sanTokenId
    )
        public
        view
        returns (bool isGold_)
    {
        uint256 bucket = _sanTokenId >> 8;
        uint256 mask = 1 << (_sanTokenId & 0xff);
        isGold_ = sanGoldTokenBitfield[bucket] & mask > 0;
    }

    /**
     * @notice Checks if a SAN token ID has been used to mint in some epoch.
     * @param _epoch The epoch number.
     * @param _sanTokenId The SAN token ID.
     * @return hasBeenUsed_ True if this SAN token ID has minted in the epoch.
     */
    function tokenWasUsedInEpoch(
        uint256 _epoch,
        uint256 _sanTokenId
    )
        public
        view
        returns (bool hasBeenUsed_)
    {
        uint256 bucket = _sanTokenId >> 8;
        uint256 mask = 1 << (_sanTokenId & 0xff);
        hasBeenUsed_ = epochSanUsed[_epoch][bucket] & mask > 0;
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (SAN1155, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function _setTokenUsedThisEpoch(
        uint256 _sanTokenId
    )
        private
    {
        uint256 bucket = _sanTokenId >> 8;
        uint256 mask = 1 << (_sanTokenId & 0xff);
        epochSanUsed[_currentEpoch()][bucket] |= mask;
    }

    function _currentEpoch()
        private
        view
        returns (uint256 epoch_)
    {
        if (block.timestamp < FLOW_ORIGINATION_TIME) {
            epoch_ = 0;
        }
        else {
            unchecked {
                epoch_ = 1 + (block.timestamp - FLOW_ORIGINATION_TIME) / FLOW_RATE;
            }
        }
    }

    function ___ART_MUST_FLOW___()
        external
        pure
        returns (string memory haiku_)
    {
        haiku_ =
            "cromagnus the name ||| "
            "mystery in his brush strokes ||| "
            "art must always flow";
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface SANSoulbindable {
    enum SoulboundLevel { Unbound, One, Two, Three, Four }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC2981Royalties.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
	struct RoyaltyInfo {
		address recipient;
		uint24 amount;
	}

	/// @inheritdoc	ERC165
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override
		returns (bool)
	{
		return
			interfaceId == type(IERC2981Royalties).interfaceId ||
			super.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./ERC2981Base.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is ERC2981Base {
	RoyaltyInfo private _royalties;

	/// @dev Sets token royalties
	/// @param _recipient recipient of the royalties
	/// @param _value percentage (using 2 decimals - 10000 = 100, 0 = 0)
	function _setRoyalties(
		address _recipient,
		uint256 _value
	)
		internal
	{
		// unneeded since the derived contract has a lower _value limit
		// require(_value <= 10000, "ERC2981Royalties: Too high");
		_royalties = RoyaltyInfo(_recipient, uint24(_value));
	}

	/// @inheritdoc	IERC2981Royalties
	function royaltyInfo(
		uint256,
		uint256 _value
	)
		external
		view
		override
		returns (address receiver, uint256 royaltyAmount)
	{
		RoyaltyInfo memory royalties = _royalties;
		receiver = royalties.recipient;
		royaltyAmount = (_value * royalties.amount) / 10000;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
	/// @notice Called with the sale price to determine how much royalty
	///         is owed and to whom.
	/// @param _tokenId - the NFT asset queried for royalty information
	/// @param _value - the sale price of the NFT asset specified by _tokenId
	/// @return _receiver - address of who should be sent the royalty payment
	/// @return _royaltyAmount - the royalty payment amount for value sale price
	function royaltyInfo(uint256 _tokenId, uint256 _value)
		external
		view
		returns (address _receiver, uint256 _royaltyAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IStuckERC20 {
    function transfer(
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IStuckERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IStuckTokens.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IStuckERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IStuckERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IStuckTokens.sol";
import "./SafeERC20.sol";
import "../utils/Ownable.sol";

error ArrayLengthMismatch();

contract TokenRescuer is Ownable {
    using SafeERC20 for IStuckERC20;

    function rescueBatchERC20(
        address _token,
        address[] calldata _receivers,
        uint256[] calldata _amounts
    )
        external
        onlyOwner
    {
        if (_receivers.length != _amounts.length) revert ArrayLengthMismatch();
        unchecked {
            for (uint i; i < _receivers.length; i += 1) {
                _rescueERC20(_token, _receivers[i], _amounts[i]);
            }
        }
    }

    function rescueERC20(
        address _token,
        address _receiver,
        uint256 _amount
    )
        external
        onlyOwner
    {
        _rescueERC20(_token, _receiver, _amount);
    }

    function rescueBatchERC721(
        address _token,
        address[] calldata _receivers,
        uint256[][] calldata _tokenIDs
    )
        external
        onlyOwner
    {
        if (_receivers.length != _tokenIDs.length) revert ArrayLengthMismatch();
        unchecked {
            for (uint i; i < _receivers.length; i += 1) {
                uint256[] memory tokenIDs = _tokenIDs[i];
                for (uint j; j < tokenIDs.length; j += 1) {
                    _rescueERC721(_token, _receivers[i], tokenIDs[j]);
                }
            }
        }
    }

    function rescueERC721(
        address _token,
        address _receiver,
        uint256 _tokenID
    )
        external
        onlyOwner
    {
        _rescueERC721(_token, _receiver, _tokenID);
    }

    function _rescueERC20(
        address _token,
        address _receiver,
        uint256 _amount
    )
        private
    {
        IStuckERC20(_token).safeTransfer(_receiver, _amount);
    }

    function _rescueERC721(
        address _token,
        address _receiver,
        uint256 _tokenID
    )
        private
    {
        IStuckERC721(_token).safeTransferFrom(
            address(this),
            _receiver,
            _tokenID
        );
    }
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// With renounceOwnership() removed

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";

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