// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

// Changes:
// - Replaced error messages with custom error objects.

error CallFailed();
error CallToNonContract();
error InsufficientBalance();
error UnableToSend();

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
        if (address(this).balance < amount) {
            revert InsufficientBalance();
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert UnableToSend();
        }
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
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`],
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
        if (address(this).balance < value) {
            revert InsufficientBalance();
        }
        if (!isContract(target)) {
            revert CallToNonContract();
        }

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract();
        }

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract();
        }

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata
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
                revert CallFailed();
            }
        }
    }
}


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

/** @dev Extension of ERC1155 that adds tracking of total supply per id. */
interface IERC1155Supply {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}


// This does not fully conform to EIP-1155:
// - Does not emit TransferSingle, TransferBatch events.
// - Does not implement

address constant ZERO_ADDRESS = address(0);

error ArrayLengthMismatch();
error CallerNotOwnerNorApproved();
error ERC1155ReceiverRejectedTokens();
error NonERC1155ReceiverImplementer();
error SettingApprovalForSelf();
error ZeroAddress();

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * Fork of OpenZeppelin's ERC1155Supply:
 * - Uses custom error messages instead of strings.
 * - Does not emit any events.
 * - Does not implement safeTransferFrom, safeBatchTransferFrom,
 */
abstract contract ERC1155SupplyNE is Context, ERC165, IERC1155, IERC1155MetadataURI, IERC1155Supply {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // The total supply of each issued token.
    mapping(uint256 => uint256) private _totalSupply;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC1155Supply).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * Get the base URI that all token types share.
     */
    function baseURI() public view virtual returns (string memory) {
        return _uri;
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

    // Balances //

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        if (account == ZERO_ADDRESS) {
            revert ZeroAddress();
        }

        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        if (accounts.length != ids.length) {
            revert ArrayLengthMismatch();
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyNE.totalSupply(id) > 0;
    }

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    // Approvals //

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
        if (owner == operator) {
            revert SettingApprovalForSelf();
        }

        _operatorApprovals[owner][operator] = approved;

        emit ApprovalForAll(owner, operator, approved);
    }

    // Transfers //

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burnSingle(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (from == ZERO_ADDRESS) {
            revert ZeroAddress();
        }

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) {
            revert InsufficientBalance();
        }

        unchecked {
            _balances[id][from] = fromBalance - amount;
            _totalSupply[id] -= amount;
        }
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mintSingle(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == ZERO_ADDRESS) {
            revert ZeroAddress();
        }

        _balances[id][to] += amount;
        _totalSupply[id] += amount;

        // We allow this contract to be an owner of any of its tokens, without extra checks.
        if (to != address(this) && to.isContract()) {
            _doSafeTransferAcceptanceCheck(ZERO_ADDRESS, to, id, amount, data);
        }
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFromSingle(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert CallerNotOwnerNorApproved();
        }

        if (to == ZERO_ADDRESS) {
            revert ZeroAddress();
        }

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) {
            revert InsufficientBalance();
        }

        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        // We allow this contract to be an owner of any of its tokens, without extra checks.
        if (to != address(this) && to.isContract()) {
            _doSafeTransferAcceptanceCheck(from, to, id, amount, data);
        }
    }

    /**
     * @dev Ensures that transfers (including mints) are either to ERC1155Receiver contracts or externally-
     * -owned-accounts (inasmuch as they can be identified).
     */
    function _doSafeTransferAcceptanceCheck(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        try IERC1155Receiver(to).onERC1155Received(_msgSender(), from, id, amount, data) returns (bytes4 response) {
            if (response != IERC1155Receiver.onERC1155Received.selector) {
                revert ERC1155ReceiverRejectedTokens();
            }
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert NonERC1155ReceiverImplementer();
        }
    }
}


// How many bits to shift to get the token adadress (NFT vs metatoken).
uint256 constant TOKEN_ADDRESS_SHIFT = 96;
// The mask to get the metatoken address from a given token id.
uint256 constant TOKEN_ADDRESS_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000;
// The mask to get the NFT id from a given token id.
uint256 constant TOKEN_ID_MASK = 0x0000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;

// Which hooks a metatoken has enabled.
uint16 constant CAT_HAS_HOOK_NFT_BURN      = 0x01;
uint16 constant CAT_HAS_HOOK_NFT_MINT      = 0x04;
uint16 constant CAT_HAS_HOOK_NFT_TRANSFER  = 0x08;
uint16 constant CAT_HAS_HOOK_META_BURN     = 0x10;
uint16 constant CAT_HAS_HOOK_META_MINT     = 0x40;
uint16 constant CAT_HAS_HOOK_META_TRANSFER = 0x80;

/**
 * @dev A metatoken is an extension of metadata and logic on top of an ERC-1155 NFT.
 *
 * The highest-order (big-endian) 20 bytes of the token ID is the address of the metatoken extension
 * contract. The next 4 bytes are optional metadata. The remaining 8 bytes are the token ID.
 *
 * Libraries that implement metatokens will be trustfully registered to ERC-1155 NFT contracts.
 *
 * To reduce unintentional confusion between interacting with the root NFT and its metatokens,
 * the naming of the hooks differs slightly: before/after is used when writing NFT logic, pre/post
 * is used when writing metatoken logic.
 *
 * Base ERC-1155M Hooks:
 * - beforeBurn(address from, uint256 id, uint256 amount)
 * - afterBurn(address from, uint256 id, uint256 amount)
 * - beforeMint(address to, uint256 id, uint256 amount, bytes data)
 * - afterMint(address to, uint256 id, uint256 amount, bytes data)
 * - beforeTransfer(address from, address to, uint256 id, uint256 amount, bytes data)
 * - afterTransfer(address from, address to, uint256 id, uint256 amount, bytes data)
 *
 * Metatoken Hooks:
 * - preMetaBurn(address from, uint256 id, uint256 amount)
 * - postMetaBurn(address from, uint256 id, uint256 amount)
 * - preMetaMint(address to, uint256 id, uint256 amount, bytes data)
 * - postMetaMint(address to, uint256 id, uint256 amount, bytes data)
 * - preMetaTransfer(address from, address to, uint256 id, uint256 amount, bytes data)
 * - postMetaTransfer(address from, address to, uint256 id, uint256 amount, bytes data)
 *
 */
interface IMetatoken1155 is IERC165 {
    //////////////////////////////////////
    /// Metatoken Registration Details ///
    //////////////////////////////////////

    /**
     * @dev Which hooks this metatoken has enabled
     */
    function metatokenHooks() external pure returns (uint16);

    ////////////////////////////
    /// NFT - Precheck Hooks ///
    ////////////////////////////

    /**
     * @dev Called prior to the burn of the root NFT.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * burning of an NFT.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Example: Checking to make sure the metatoken exists before burning it.
     */
    function beforeBurn(
        address from,
        uint256 id,
        uint256 amount
    ) external view;

    /**
     * @dev Called prior to the mint of the root NFT.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * minting of an NFT.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * Example: Checking to make sure the metatoken does not exist before minting it.
     */
    function beforeMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external view;

    /**
     * @dev Called prior to the transfer of the root NFT.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * transferring of an NFT.
     *
     * Example: Checking to make sure the metatoken has the correct amount before transferring it.
     */
    function beforeTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external view;

    //////////////////////////////
    /// NFT - Postaction Hooks ///
    //////////////////////////////

    /**
     * @dev Called after the burn of the root NFT.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * burning of an NFT.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are cleared.
     */
    function afterBurn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @dev Called after the mint of the root NFT.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * minting of an NFT.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are set.
     */
    function afterMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev Called prior to the transfer of the root NFT.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * transferring of an NFT.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are updated.
     */
    function afterTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    //////////////////////////////////
    /// Metatoken - Precheck Hooks ///
    //////////////////////////////////

    /**
     * @dev Called prior to the burn of the metatoken.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * burning of a metatoken.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Example: Checking to make sure the metatoken exists before burning it.
     */
    function preMetaBurn(
        address from,
        uint256 id,
        uint256 amount
    ) external view;

    /**
     * @dev Called prior to the mint of the metatoken.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * minting of a metatoken.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * Example: Checking to make sure the metatoken does not exist before minting it.
     */
    function preMetaMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external view;

    /**
     * @dev Called prior to the transfer of the metatoken.
     *
     * This should not modify state as it is used solely as a test for invariance prior to the
     * transferring of a metatoken.
     *
     * Example: Checking to make sure the metatoken has the correct amount before transferring it.
     */
    function preMetaTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external view;

    ////////////////////////////////////
    /// Metatoken - Postaction Hooks ///
    ////////////////////////////////////

    /**
     * @dev Called after the burn of the metatoken.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * burning of a metatoken.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are cleared.
     */
    function postMetaBurn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @dev Called after the mint of the metatoken.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * minting of a metatoken.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are set.
     */
    function postMetaMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev Called prior to the transfer of the metatoken.
     *
     * This may modify state if necessary, however it must also test for invariances after the
     * transferring of a metatoken.
     *
     * Example: Checking to make sure secondary addresses associated with the metatoken are updated.
     */
    function postMetaTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

// Used to configure proxied calls.
uint256 constant PROXY_INCLUDE_SENDER = 0x1;
uint256 constant PROXY_SEND_RAW = 0x2;

interface IERC1155M {

    // The details for each registered metatoken.
    struct MetatokenDetails {
        uint16 status;
        uint16 hooks;
    }

    /**
     * @dev Returns the details for the provided metatoken extension.
     *
     * Returns:
     * - Metatoken status
     * - Metatoken hooks
     */
    function getMetatokenDetails(IMetatoken1155 metatoken) external view returns (MetatokenDetails memory);

    /**
     * @dev Returns the true metatoken address for a given registered metatoken address.
     */
    function getMetatokenImplementation(IMetatoken1155 metatoken) external view returns (IMetatoken1155);

    /**
     * @dev Checks if the provided selector is in the allowlist.
     */
    function isProxiedSelectorAllowed(uint256 selector) external view returns (bool);

    /**
     * @dev Proxies a CALL to a registered metatoken. The CALL will be executed via DELEGATECALL.
     * This allows for exposing new external functions for a metatoken (e.g., for compatability
     * layers for ERC-20 or ERC-721).
     *
     * @param options bit array with these flags:
     *     PROXY_INCLUDE_SENDER
     *     PROXY_SEND_RAW
     */
    function proxyMetatokenCall(
        address metatoken,
        bytes4 selector,
        uint8 options,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @dev Proxies a STATICCALL to a registered metatoken. The STATICCALL will be executed
     * via DELEGATECALL. This allows for exposing new external functions for a metatoken (e.g.,
     * for compatability layers for ERC-20 or ERC-721).
     *
     * The current metatoken and sender will be prefixed to the calldata, if requested.
     *
     * @param options bit array with these flags:
     *     PROXY_INCLUDE_SENDER
     *     PROXY_SEND_RAW
     */
    function proxyMetatokenView(
        address metatoken,
        bytes4 selector,
        uint8 options,
        bytes calldata data
    ) external view returns (bytes memory);
}


// ERC1155M Errors
error ImplementationAlreadySet();
error IsImplementation();
error IsNotImplementation();
error MetatokenAlreadyDisabled();
error MetatokenAlreadyEnabled();
error MetatokenAlreadyRegistered();
error MetatokenNotEnabled();
error NoRegisteredMetatoken();
error NotApprovedForTransfer();
error NotValidMetatoken();
error NotAllowedMetatokenSelector();

// Metatoken Errors
error AddressMismatch();

contract ERC1155M is ERC1155SupplyNE, IERC1155M, ReentrancyGuard {
    using Address for address;

    //////////////////
    /// Metatokens ///
    //////////////////

    // Possible metatoken statuses.
    uint16 constant M_STATUS_REGISTERED = 0x1;
    uint16 constant M_STATUS_IS_IMPLEMENTATION = 0x2;
    uint16 constant M_STATUS_ENABLED = 0x4;

    // The details for each registered metatoken.
    mapping(IMetatoken1155 => MetatokenDetails) private _metatokenDetails;
    // The allowed proxied function selectors for each registered metatoken.
    mapping(uint256 => bool) private _allowedMetatokenSelectors;

    // Which NFT hooks are enabled for each registered metatoken.
    IMetatoken1155[] private _nftHookBurnExtensions;
    IMetatoken1155[] private _nftHookMintExtensions;
    IMetatoken1155[] private _nftHookTransferExtensions;

    // The currently executing metatoken.
    IMetatoken1155 private _currentMetatoken;

    // Used to update the implementation address for a given metatoken. By default this is
    // the same as the initial address. The implementation address will only be used when
    // executing the delegate calls, in all other cases the original metatoken address will
    // be used. If a metatoken's implementation address is updated, the updated address
    // is permanently denylisted from registration as a metatoken to prevent unintentional
    // or malicious misuse of the address.
    //
    // Should only be read via _getMetatokenImplementation().
    mapping(IMetatoken1155 => IMetatoken1155) private _metatokenAddresses;

    /**
     * @dev Ensures that a metatoken's status matches the provided bit flag.
     *
     * @param status must be a valid metatoken status (see above).
     */
    function _metatokenStatusIs(uint16 metatokenStatus, uint16 status) internal pure returns (bool) {
        return (metatokenStatus & status) == status;
    }

    /**
     * @dev Sets the appropriate bit flag for a given metatoken's status.
     *
     * @param status must be a valid metatoken status (see above), or combination of statuses.
     */
    function _setMetatokenStatus(IMetatoken1155 metatoken, uint16 status) internal {
        _metatokenDetails[metatoken].status |= status;
    }

    /**
     * @dev Clears the appropriate bit flag for a given metatoken's status.
     *
     * @param status must be a valid metatoken status (see above), or combination of statuses.
     */
    function _unsetMetatokenStatus(IMetatoken1155 metatoken, uint16 status) internal {
        _metatokenDetails[metatoken].status &= ~status;
    }

    /**
     * @dev Returns the details for the provided metatoken extension.
     *
     * Returns:
     * - Metatoken status
     * - Metatoken hooks
     */
    function getMetatokenDetails(IMetatoken1155 metatoken) external view returns (MetatokenDetails memory) {
        return _metatokenDetails[metatoken];
    }

    /**
     * @dev Returns the true metatoken address for a given registered metatoken address.
     *
     * Assumes that the metatoken is registered and enabled.
     */
    function _getMetatokenImplementation(IMetatoken1155 metatoken) internal view returns (IMetatoken1155) {
        IMetatoken1155 trueAddress = _metatokenAddresses[metatoken];

        if (address(trueAddress) == ZERO_ADDRESS) {
            return metatoken;
        }

        return trueAddress;
    }

    /**
     * @dev Returns the true metatoken address for a given registered metatoken address.
     */
    function getMetatokenImplementation(IMetatoken1155 metatoken) external view returns (IMetatoken1155) {
        // Validate the call is allowed.
        uint16 status = (_metatokenDetails[IMetatoken1155(metatoken)]).status;
        if (!_metatokenStatusIs(status, M_STATUS_REGISTERED)) {
            revert NoRegisteredMetatoken();
        }
        if (_metatokenStatusIs(status, M_STATUS_IS_IMPLEMENTATION)) {
            revert IsImplementation();
        }

        return _getMetatokenImplementation(metatoken);
    }

    /**
     * @dev Enable a prevously disabled metatoken extension.
     *
     * It is not recommended for metatokens to be re-enabled after they have been disabled,
     * as any intermediate transactions could potentially violate any constraints the metatoken
     * would place on the contract.
     */
    function _enableMetatoken(IMetatoken1155 metatoken) internal {
        // Validate the call is allowed.
        uint16 status = (_metatokenDetails[IMetatoken1155(metatoken)]).status;
        if (!_metatokenStatusIs(status, M_STATUS_REGISTERED)) {
            revert NoRegisteredMetatoken();
        }
        if (_metatokenStatusIs(status, M_STATUS_IS_IMPLEMENTATION)) {
            revert IsImplementation();
        }
        if (_metatokenStatusIs(status, M_STATUS_ENABLED)) {
            revert MetatokenAlreadyEnabled();
        }

        // Enable the metatoken.
        _setMetatokenStatus(metatoken, M_STATUS_ENABLED);

        // Enable the hooks. We pull from the external contract in case there was an update.
        _updateMetatokenHooks(metatoken, metatoken.metatokenHooks());
    }

    /**
     * @dev Disable a previously registered metatoken extension.
     */
    function _disableMetatoken(IMetatoken1155 metatoken) internal {
        // Validate the call is allowed.
        uint16 status = (_metatokenDetails[IMetatoken1155(metatoken)]).status;
        if (!_metatokenStatusIs(status, M_STATUS_REGISTERED)) {
            revert NoRegisteredMetatoken();
        }
        if (_metatokenStatusIs(status, M_STATUS_IS_IMPLEMENTATION)) {
            revert IsImplementation();
        }
        if (!_metatokenStatusIs(status, M_STATUS_ENABLED)) {
            revert MetatokenAlreadyDisabled();
        }

        // Disable the metatoken.
        _unsetMetatokenStatus(metatoken, M_STATUS_ENABLED);

        // Disable the hooks.
        _updateMetatokenHooks(metatoken, 0x0);
    }

    /**
     * @dev Register a metatoken extension.
     *
     * DO NOT REGISTER EXTENSIONS WITHOUT FULL UNDERSTANDING AND / OR CONTROL OF IT
     * DO NOT REGISTER PROXIED METATOKENS IF THE ERC1155M IS PROXIED
     * DO NOT REGISTER PROXIED METATOKENS UNLESS YOU FULLY CONTROL THE PROXY
     */
    function _registerMetatoken(IMetatoken1155 metatoken, bool enabled) internal {
        // Validate the call is allowed.
        if (!metatoken.supportsInterface(type(IMetatoken1155).interfaceId)) {
            revert NotValidMetatoken();
        }
        uint16 status = (_metatokenDetails[IMetatoken1155(metatoken)]).status;
        if (_metatokenStatusIs(status, M_STATUS_REGISTERED)) {
            revert MetatokenAlreadyRegistered();
        }

        // Register the metatoken.
        _setMetatokenStatus(metatoken, M_STATUS_REGISTERED);

        if (enabled) {
            _enableMetatoken(metatoken);
        }
    }

    /**
     * @dev Updates the implementation address for a metatoken.
     *
     * A given implementation address can be used for multiple metatokens, however no implementation
     * address can be registered as its own metatoken.
     *
     * DO NOT REGISTER EXTENSIONS WITHOUT FULL UNDERSTANDING AND / OR CONTROL OF IT
     * DO NOT REGISTER PROXIED METATOKENS IF THE ERC1155M IS PROXIED
     * DO NOT REGISTER PROXIED METATOKENS UNLESS YOU FULLY CONTROL THE PROXY
     */
    function _updateMetatokenImplementation(IMetatoken1155 metatoken, IMetatoken1155 implementation) internal {
        // Validate the call is allowed.
        IMetatoken1155 existingImplementation = IMetatoken1155(_getMetatokenImplementation(metatoken));
        if (implementation == existingImplementation) {
            revert ImplementationAlreadySet();
        }
        uint16 metatokenStatus = (_metatokenDetails[IMetatoken1155(metatoken)]).status;
        if (!_metatokenStatusIs(metatokenStatus, M_STATUS_REGISTERED)) {
            revert NoRegisteredMetatoken();
        }
        // Be able to revert.
        if (metatoken != implementation) {
            uint16 implementationStatus = (_metatokenDetails[IMetatoken1155(implementation)]).status;
            bool isRegistered = _metatokenStatusIs(implementationStatus, M_STATUS_REGISTERED);
            if (isRegistered && !_metatokenStatusIs(implementationStatus, M_STATUS_IS_IMPLEMENTATION)) {
                revert IsNotImplementation();
            }
            if (!isRegistered && !implementation.supportsInterface(type(IMetatoken1155).interfaceId)) {
                revert NotValidMetatoken();
            }

            // The implementation wasn't previously registered, so register it and denylist it.
            if (!isRegistered) {
                _setMetatokenStatus(implementation, M_STATUS_REGISTERED | M_STATUS_IS_IMPLEMENTATION);
            }
        }

        // Update the implementation address.
        _metatokenAddresses[metatoken] = implementation;
    }

    /**
     * @dev Updates the registered hooks for a given metatoken.
     */
    function _updateMetatokenHooks(IMetatoken1155 metatoken, uint16 enabledHooks) internal {
        MetatokenDetails memory details = _metatokenDetails[metatoken];
        uint16 status = details.status;
        if (!_metatokenStatusIs(status, M_STATUS_REGISTERED)) {
            revert NoRegisteredMetatoken();
        }
        if (_metatokenStatusIs(status, M_STATUS_IS_IMPLEMENTATION)) {
            revert IsImplementation();
        }
        if (!_metatokenStatusIs(status, M_STATUS_ENABLED)) {
            revert MetatokenNotEnabled();
        }

        uint16 currentHooks = details.hooks;
        _metatokenDetails[metatoken].hooks = enabledHooks;
        uint256 i;
        uint256 count;

        // Burning the NFT token.
        bool usedToBe = (currentHooks & CAT_HAS_HOOK_NFT_BURN) == CAT_HAS_HOOK_NFT_BURN;
        bool shouldBe = (enabledHooks & CAT_HAS_HOOK_NFT_BURN) == CAT_HAS_HOOK_NFT_BURN;
        if (!usedToBe && shouldBe) {
            _nftHookBurnExtensions.push(metatoken);
        } else if (usedToBe && !shouldBe) {
            // Pop and swap the hooks.
            count = _nftHookBurnExtensions.length;
            for (i; i < count; i++) {
                if (_nftHookBurnExtensions[i] == metatoken) {
                    // This metatoken is not the last in its category, so we need to swap in the last element.
                    if (i < count - 1) {
                        _nftHookBurnExtensions[i] = _nftHookBurnExtensions[count - 1];
                    }
                    _nftHookBurnExtensions.pop();
                    break;
                }
            }
        }

        // Minting the NFT token.
        usedToBe = (currentHooks & CAT_HAS_HOOK_NFT_MINT) == CAT_HAS_HOOK_NFT_MINT;
        shouldBe = (enabledHooks & CAT_HAS_HOOK_NFT_MINT) == CAT_HAS_HOOK_NFT_MINT;
        if (!usedToBe && shouldBe) {
            _nftHookMintExtensions.push(metatoken);
        } else if (usedToBe && !shouldBe) {
            // Pop and swap the hooks.
            count = _nftHookMintExtensions.length;
            for (i; i < count; i++) {
                if (_nftHookMintExtensions[i] == metatoken) {
                    // This metatoken is not the last in its category, so we need to swap in the last element.
                    if (i < count - 1) {
                        _nftHookMintExtensions[i] = _nftHookMintExtensions[count - 1];
                    }
                    _nftHookMintExtensions.pop();
                    break;
                }
            }
        }

        // Transferring the NFT token.
        usedToBe = (currentHooks & CAT_HAS_HOOK_NFT_TRANSFER) == CAT_HAS_HOOK_NFT_TRANSFER;
        shouldBe = (enabledHooks & CAT_HAS_HOOK_NFT_TRANSFER) == CAT_HAS_HOOK_NFT_TRANSFER;
        if (!usedToBe && shouldBe) {
            _nftHookTransferExtensions.push(metatoken);
        } else if (usedToBe && !shouldBe) {
            // Pop and swap the hooks.
            count = _nftHookTransferExtensions.length;
            for (i; i < count; i++) {
                if (_nftHookTransferExtensions[i] == metatoken) {
                    // This metatoken is not the last in its category, so we need to swap in the last element.
                    if (i < count - 1) {
                        _nftHookTransferExtensions[i] = _nftHookTransferExtensions[count - 1];
                    }
                    _nftHookTransferExtensions.pop();
                    break;
                }
            }
        }
    }

    /**
     * @dev Adds the provided selectors to the allowlist for proxying.
     *
     * The highest-order bytes20 are the metatoken address, the lowest order bytes4 is the proxied
     * function selector.
     */
    function _allowMetatokenSelectors(uint256[] calldata selectors) internal {
        uint256 count = selectors.length;
        for (uint256 i; i < count; i ++) {
            _allowedMetatokenSelectors[selectors[i]] = true;
        }
    }

    /**
     * @dev Removes the provided selectors to the allowlist for proxying.
     *
     * The highest-order bytes20 are the metatoken address, the lowest order bytes4 is the proxied
     * function selector.
     */
    function _denyMetatokenSelectors(uint256[] calldata selectors) internal {
        uint256 count = selectors.length;
        for (uint256 i; i < count; i ++) {
            _allowedMetatokenSelectors[selectors[i]] = false;
        }
    }

    /**
     * @dev Checks if the provided selector is in the allowlist.
     */
    function isProxiedSelectorAllowed(uint256 selector) external view returns (bool) {
        return _allowedMetatokenSelectors[selector];
    }

    /**
     * @dev Proxies a CALL to a registered metatoken. The CALL will be executed via DELEGATECALL.
     * This allows for exposing new external functions for a metatoken (e.g., for compatability
     * layers for ERC-20 or ERC-721).
     *
     * @param options bit array with these flags:
     *     PROXY_INCLUDE_SENDER
     *     PROXY_SEND_RAW
     */
    function proxyMetatokenCall(
        address metatoken,
        bytes4 selector,
        uint8 options,
        bytes calldata data
    ) external returns (bytes memory) {
        // Validate the call is allowed.
        uint16 status = (_metatokenDetails[IMetatoken1155(metatoken)]).status;
        if (!_metatokenStatusIs(status, M_STATUS_REGISTERED)) {
            revert NoRegisteredMetatoken();
        }
        if (!_metatokenStatusIs(status, M_STATUS_ENABLED)) {
            revert MetatokenNotEnabled();
        }
        if (
            !_allowedMetatokenSelectors[
                // Get t-
                (uint256(uint160(address(_getMetatokenImplementation(IMetatoken1155(metatoken))))) << TOKEN_ADDRESS_SHIFT) | uint32(selector)
            ]
        ) {
            revert NotAllowedMetatokenSelector();
        }

        // Do not do any encoding on the data if it is a raw request, other than adding the selector to the front.
        bytes memory callData;
        if (options & PROXY_SEND_RAW == PROXY_SEND_RAW) {
            callData = abi.encodePacked(selector, data);
        } else {
            callData = abi.encodeWithSelector(selector, data);
        }

        // Call the proxied function.
        bytes memory result = address(metatoken).functionDelegateCall(callData);

        return result;
    }

    /**
     * @dev Proxies a STATICCALL to a registered metatoken. The STATICCALL will be executed
     * via DELEGATECALL. This allows for exposing new external functions for a metatoken (e.g.,
     * for compatability layers for ERC-20 or ERC-721).
     *
     * The current metatoken and sender will be prefixed to the calldata, if requested.
     *
     * @param options bit array with these flags:
     *     PROXY_INCLUDE_SENDER
     *     PROXY_SEND_RAW
     */
    function proxyMetatokenView(
        address metatoken,
        bytes4 selector,
        uint8 options,
        bytes calldata data
    ) external view returns (bytes memory) {
        // Normally we would include the metatoken address and sender.
        bytes memory callData;
        if (options & PROXY_INCLUDE_SENDER == PROXY_INCLUDE_SENDER) {
            // If this is a raw request, don't encode the data.
            if (options & PROXY_SEND_RAW == PROXY_SEND_RAW) {
                callData = abi.encodePacked(
                    // We still need to encode the metatoken and sender though.
                    abi.encode(
                        metatoken,
                        msg.sender
                    ),
                    data
                );
            } else {
                callData = abi.encode(
                    metatoken,
                    msg.sender,
                    data
                );
            }
        } else {
            callData = data;
        }

        return address(this).functionStaticCall(abi.encodeWithSelector(
            // bytes4(keccak256("proxyMetatokenCall(address,bytes4,uint8,bytes)"))
            0x81638579,
            metatoken,
            // This is bytes4, but we need the padding that encodePacked() doesn't provide.
            selector,
            // Proxied view requests are always sent raw.
            PROXY_SEND_RAW,
            // Data for proxyMetatokenCall().
            callData
        ));
    }

    ///////////////
    /// ERC1155 ///
    ///////////////

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
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert NotApprovedForTransfer();
        }

        uint256[] memory ids = new uint[](1);
        ids[0] = id;
        uint256[] memory amounts = new uint[](1);
        amounts[0] = amount;

        _transferTokens(from, to, ids, amounts, data);
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
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert NotApprovedForTransfer();
        }

        _transferTokens(from, to, ids, amounts, data);
    }

    /**
     * @dev Burns any number of tokens and/or metatokens. Each operation is handled sequentially.
     *
     * Emits a {TransferBatch} event for batch transfers and a {TransferSingle} event for single transfers.
     */
    function _burnTokens(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        if (from == ZERO_ADDRESS) {
            revert ZeroAddress();
        }

        bytes4[4] memory selectors = [
            IMetatoken1155.beforeBurn.selector,
            IMetatoken1155.afterBurn.selector,
            IMetatoken1155.preMetaBurn.selector,
            IMetatoken1155.postMetaBurn.selector
        ];

        _metatokenTransfer(from, ZERO_ADDRESS, ids, amounts, _nftHookBurnExtensions, CAT_HAS_HOOK_META_BURN, selectors, "");
    }

    /**
     * @dev Mints any number of tokens and/or metatokens. Each operation is handled sequentially.
     *
     * Emits a {TransferBatch} event for batch transfers and a {TransferSingle} event for single transfers.
     */
    function _mintTokens(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to == ZERO_ADDRESS) {
            revert ZeroAddress();
        }

        bytes4[4] memory selectors = [
            IMetatoken1155.beforeMint.selector,
            IMetatoken1155.afterMint.selector,
            IMetatoken1155.preMetaMint.selector,
            IMetatoken1155.postMetaMint.selector
        ];

        _metatokenTransfer(ZERO_ADDRESS, to, ids, amounts, _nftHookMintExtensions, CAT_HAS_HOOK_META_MINT, selectors, data);
    }

    /**
     * @dev Transfers any number of tokens and/or metatokens. Each operation is handled sequentially.
     *
     * Emits a {TransferBatch} event for batch transfers and a {TransferSingle} event for single transfers.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _transferTokens(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to == ZERO_ADDRESS) {
            revert ZeroAddress();
        }

        bytes4[4] memory selectors = [
            IMetatoken1155.beforeTransfer.selector,
            IMetatoken1155.afterTransfer.selector,
            IMetatoken1155.preMetaTransfer.selector,
            IMetatoken1155.postMetaTransfer.selector
        ];

        _metatokenTransfer(from, to, ids, amounts, _nftHookTransferExtensions, CAT_HAS_HOOK_META_TRANSFER, selectors, data);
    }

    /**
     * @dev Creates the calldata for the delegatecall for the hooks.
     */
    function _encodeHookSelector(
        bytes4 selector,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private pure returns (bytes memory) {
        // Minting
        if (from == ZERO_ADDRESS) {
            return abi.encodeWithSelector(selector, to, id, amount, data);
        }
        // Burning
        else if (to == ZERO_ADDRESS) {
            return abi.encodeWithSelector(selector, from, id, amount);
        }
        // Transferring
        else {
            return abi.encodeWithSelector(selector, from, to, id, amount, data);
        }
    }

    function _metatokenTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        IMetatoken1155[] storage nftHookExtensions,
        uint256 metatokenHooksMask,
        bytes4[4] memory selectors,
        bytes memory data
    ) private nonReentrant {
        if (ids.length != amounts.length) {
            revert ArrayLengthMismatch();
        }

        MetatokenDetails memory metatokenDetails;

        // Check each token.
        for (uint256 i; i < ids.length; i++) {
            // Check to see if this is a metatoken.
            address metatokenAddress = address(uint160(ids[i] >> TOKEN_ADDRESS_SHIFT));

            // It's an NFT, so run the pre-NFT transfers.
            if (ids[i] & TOKEN_ADDRESS_MASK == 0) {
                // Run all the preaction checks.
                bytes memory callData = _encodeHookSelector(selectors[0], from, to, ids[i], amounts[i], data);
                for (uint256 j; j < nftHookExtensions.length; j++) {
                    _currentMetatoken = nftHookExtensions[j];
                    address(nftHookExtensions[j]).functionDelegateCall(callData);
                }

                // Mint the token.
                if (from == ZERO_ADDRESS) {
                    _mintSingle(to, ids[i], amounts[i], data);
                }
                // Burn the token.
                else if (to == ZERO_ADDRESS) {
                    _burnSingle(from, ids[i], amounts[i]);
                }
                // Transfer the token.
                else {
                    _safeTransferFromSingle(from, to, ids[i], amounts[i], data);
                }

                // Run all the postaction checks.
                callData = _encodeHookSelector(selectors[1], from, to, ids[i], amounts[i], data);
                for (uint256 j; j < nftHookExtensions.length; j++) {
                    _currentMetatoken = nftHookExtensions[j];
                    address(nftHookExtensions[j]).functionDelegateCall(callData);
                }
            }

            else {
                address metatokenImplementation = address(_getMetatokenImplementation(IMetatoken1155(metatokenAddress)));
                metatokenDetails = _metatokenDetails[IMetatoken1155(metatokenAddress)];
                uint16 metatokenStatus = metatokenDetails.status;
                // We can't handle tokens for non-registered metatokens.
                if (!_metatokenStatusIs(metatokenStatus, M_STATUS_REGISTERED)) {
                    revert NoRegisteredMetatoken();
                }
                // We can't handle tokens for disabled metatokens.
                if (!_metatokenStatusIs(metatokenStatus, M_STATUS_ENABLED)) {
                    revert MetatokenNotEnabled();
                }

                // This metatoken extension is enabled for its own hooks.
                if (metatokenDetails.hooks & metatokenHooksMask == metatokenHooksMask) {
                    _currentMetatoken = IMetatoken1155(metatokenAddress);

                    // Run the preaction check.
                    metatokenImplementation.functionDelegateCall(
                        _encodeHookSelector(selectors[2], from, to, ids[i], amounts[i], data)
                    );

                    // Mint the token.
                    if (from == ZERO_ADDRESS) {
                        _mintSingle(to, ids[i], amounts[i], data);
                    }
                    // Burn the token.
                    else if (to == ZERO_ADDRESS) {
                        _burnSingle(from, ids[i], amounts[i]);
                    }
                    // Transfer the token.
                    else {
                        _safeTransferFromSingle(from, to, ids[i], amounts[i], data);
                    }

                    // Run the postaction check.
                    metatokenImplementation.functionDelegateCall(
                        _encodeHookSelector(selectors[3], from, to, ids[i], amounts[i], data)
                    );
                }
            }
        }

        // Reset for the refund.
        _currentMetatoken = IMetatoken1155(ZERO_ADDRESS);

        if (ids.length == 1) {
            emit TransferSingle(_msgSender(), from, to, ids[0], amounts[0]);
        } else {
            emit TransferBatch(_msgSender(), from, to, ids, amounts);
        }
    }
}