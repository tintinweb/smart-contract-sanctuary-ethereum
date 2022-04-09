/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// File: FatWojak_flat.sol

//SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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
     * Emits a {ApprovalForAll} event.
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: contracts/FatWojak.sol





pragma solidity ^0.8.0;



/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}
contract NFT1155 is ERC1155, Ownable {
  string private svg1='<svg id="Layer_1" data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 230 219"><path d="M306.07,377.92q-55.68,0-111.35.05c-2.64,0-3.73-.11-3.72-3.43q.21-106.1,0-212.19c0-2.79.58-3.32,3.33-3.32q111.6.15,223.19,0c3.35,0,3.42,1.12,3.42,3.73q-.11,105.86,0,211.7c0,3-.63,3.58-3.59,3.57C380.3,377.87,343.18,377.92,306.07,377.92Zm67.48-138.83c.41-2.91-2.36-3.64-3.72-5.31-3.57-4.4-6.34-9.26-7-14.86a42,42,0,0,0-3.22-12.34c-7.05-15.55-20.89-24-35.05-31.36-10.91-5.7-23.32-5-35.5-5.23-12.66-.27-22.49,5.69-32.38,11.73-6.66,4.07-11.6,10.41-16.91,16.11a29.08,29.08,0,0,0-7.8,18.79c-.1,2-1.22,3-2.53,4-6.31,4.62-9.88,11-12,18.37-.4,1.37-.66,2.45-2.08,3-4.21,1.72-7.29,5.12-11.05,7.52-.24-2.83-3-2.13-3.6-1.51-1.51,1.54-.3,4.16.78,4.87,3.41,2.24,2.61,5.37,2.61,8.37,0,33.13.12,66.25-.1,99.37,0,4.94,1.06,6.48,6.29,6.45,42-.23,84.11-.13,126.17-.13,22.47,0,44.95-.08,67.42.07,3.82,0,5.17-.91,5.18-5,0-9.62-.91-19.27.51-28.87.11-.75-.72-1-1.37-1.18a11,11,0,0,0-2.91-8.09c-2.34-2.68-2.86-5.68-2.71-9.51.42-10.72-.07-21.5-7.59-30.36-1.46-1.72-.92-3.79-.91-5.73,0-6.36-.83-12.28-4.53-17.93-3.37-5.14-6.11-10.49-12.21-13-.49-.2-.55-1.43-.81-2.18,2.18-2.85,2.54-5-2-5.18Z" transform="translate(-191 -159)" style="fill:#f6f6f6"/><path d="M374.49,240c4.56.2,4.2,2.33,2,5.18-.44-.67-.94-1.49-1.84-1.08-1.21.55,0,1.24.08,1.87a2.1,2.1,0,0,1-1,2c-1.64.26-3.16.94-1.79,2.74,1.11,1.47,1.46-1.1,2.51-1,8,2.16,16.15,13.67,16.38,23,.11,4.6-.2,9.35,2.32,13.45a41.47,41.47,0,0,1,6,29.32c-.34,2.06-.62,4.27.3,6.35a5.54,5.54,0,0,0-.55,4.64c1.59-.69-.13-4.2,3.1-2.9,1.61,3.26,4.66,5.74,5.25,9.6,0,.12.68-.76.9-1.29.65.18,1.48.43,1.37,1.18-1.42,9.6-.48,19.25-.51,28.87,0,4.08-1.36,5-5.18,5-22.47-.15-44.95-.07-67.42-.07-42.06,0-84.12-.1-126.17.13-5.23,0-6.32-1.51-6.29-6.45.22-33.12.12-66.24.1-99.37,0-3,.8-6.13-2.61-8.37-1.08-.71-2.29-3.33-.78-4.87.61-.62,3.36-1.32,3.6,1.51,0,1-.78,2.18.49,3.12,2.91-2.25,5.64-4.68,8.68-6.63,3.4-2.18,7-2.66,7.6-8.7.67-7,6-12.67,12.48-16.5.88-.52,2.48-.72,2-2.35-1.93-6.89,1.43-12.52,5.17-17.41a103.39,103.39,0,0,1,18-17.84c3.22-2.56,7.59-2.69,10.58-5.25a22.44,22.44,0,0,1,13.14-5.23c20.15-1.42,39.39-.09,56.25,13.84,10.41,8.6,20.05,17.1,21.78,31a34.61,34.61,0,0,0,11.1,21.62C372.33,240.29,373.2,240.92,374.49,240ZM367,246l.37.22L367,246c-.27-.32.42-1.31-.72-1ZM355,331c.36.35.55,1.26,1.26.36L355,331c0-1.73-.91-1.5-2-1,.32-3.22,3.31-5.56,3-9,4-3.44,1.33-8,2-12l0-1c.66-2.89,2.76-.24,4-1l.4.22L362,307l1.12-2.93L365,303l1.25-.47L365,302c-.48-1.67,2.85-4-.94-5.08,0-.3,0-.6-.05-.91l0,0c.13-.09.36-.19.35-.26a3.44,3.44,0,0,0-.21-.76l.69-1c5-1.26,5.11-3.88.28-9v-2c2.73.35,5-1.75,8.28-.6,2.39.82,1.24-3.28,1.46-5.17.18-1.66-.93-2.61-2.55-1.76-5.17,2.73-6.09.34-5.43-4.27A3,3,0,0,0,365,268q0-.45,0-.9a1,1,0,0,1,.75-.2c2.61.36,3.71-.73,4.4-3.37,1.11-4.22-1.67-6.85-3.59-9.6-1.09-1.57-.47-5.39-4.09-4.52S359,248,359,245.76a6.47,6.47,0,0,0,.91-.3c1.32-.68,3.67,1.51,4-.68s-2.24-1.52-3.67-1.89a6,6,0,0,1-1.25-.7c-.37-.85-.82-1.71-1.86-1.75s-1,.88-1.18,1.61l-5.17,1.32c-1.52-1.06-3.12-2.72-4.12.51l-2,.73a3.37,3.37,0,0,0-3-1.53l.21-4c5.32-1.47,10.52-3.68,16.26-2.6.63-2-2.5-4.33.41-6.24,1.39-.91,1.78-2.12.52-3.27-1.73-1.58-2.82.1-3.56,1.24-1.75,2.68-3.45,5.78-7,5.64-5.14-.2-8.17,2.47-10.76,6.26l-.23-.28.16-.33.24-2.43c.33-.72,1.14-1.85.91-2.12-3.79-4.57-1-9.88-1.77-14.77a16.74,16.74,0,0,0,3.18-7c.24-1,1.5-1.87-.39-2.53-1.42-.5-2.59.13-2.6,1.33,0,2.69-2.34,5.24-.52,8-2.51.78-2.15,2.83-1.6,4.47,1.34,4,.72,7.78-.19,11.64l-2.61,1.23c-.75-4.77-2.53-1.07-3.95-.49-1.07.44-2.16.82-3.24,1.22-2-2.15-2.81.71-4.23,1l-1,0a3.63,3.63,0,0,0-2.67-4c-.22,2.27-5.12,1.64-3.22,5.21-1.37,1.48-2.94,1.16-4.53.49-2.42-1-4.81-2.05-7.24-3-8.54-3.44-17-1.24-25.49.24,5.62,2.13,11.59,0,17.19,1.84.29,3.27-1.5,3.16-3.63,2.13-2.57-1.22-4.13-.41-5.72,1.85-1.82,2.57-.35,3.83,1.33,5.26l.17,1c-.69,3.2-1.3,6.36,2.78,7.87v1.26c-5.55,2.89-1,4.25.91,6,.55,10.27,3.33,20.38,2.2,30.77-2.77.55-2.38,2.94-3.14,4.87-1.9,4.79,1,10.53-3.1,14.78-3.5-1.63-5.52-5.23-9.15-6.78,2.24,4.7,6,7.89,10.34,10.47a1,1,0,0,0,.69.65l.58,1.39c-.78,1.93-2.18,3.79-.57,5.94,1.5-1.66,4.71.62,5.6-2.44l5.73,6c-.24.85-1.25,1.8-.34,2.58,1.1.95,2.35.68,3.3-.5l7.05,3.85c.5,2.11-1.53,3.12-2.09,4.78l-5.07-1.09c.21-2.73-2.22-2.91-3.82-3.67-.53-.25-1,1.1-1,2-1,.24-2.05-1.29-3.06-.08a1.17,1.17,0,0,0,.25,1.12c.84.5,1.71,1.86,2.73.2l0,.11c.42,2.08,2.34,1.87,3.7,2.24,15.3,4.14,30.88,3.62,46.41,2.27,7.41-.65,12.39-5.2,13.37-10.45,3.07-1.67,3-4.23,1.82-7.13-.6,2.45-3.58,4.07-2.28,7.18-5.14,6-11.34,9.12-19.5,8.77-7.73-.34-15.49.17-23.24.31a5,5,0,0,1,.06-3.67c1.52,2.85,2.7,2.38,3.66-.36,4.33.07,8.7-1,13,.51l2,.15c.07.56,0,1.42.78,1.29,1.07-.19,1.12-1.26,1.23-2.16l2-.88c.62,2.41,2.27,1.82,3.86,1.3,2.21-.73,2.22-2.55,2.14-4.39,1.37-1.61,3.92-1.28,5.14-3.14l1.85-2C352.94,331.69,353.89,331.46,355,331ZM276,322l-1.65-.85-.3.61L276,322a1.6,1.6,0,0,0,2.42.53c.11-.07.2-.36.14-.43C277.79,321.1,276.89,322.2,276,322ZM290,336c-1.54,2.24,1.22,1.87,1.8,2.83a2.22,2.22,0,0,0,1.51-.54c.63-1.22-1.05-1.3-1.28-2.16.1-2,.18-4.09-2.31-4.7-1.79-.44-1.57,1.08-1.68,2.17-.9-.35-2.57-.55-2.17.47.53,1.35,1.72,3.61,4.16,2ZM370,252l.42.23L370,252c-.11-.89.33-2-.86-2.45-.2-.07-.87.44-.92.75C368,251.65,369,251.87,370,252ZM282.53,352.71l-.38,1.77c14.9,5,29.58,11,45.87,9.55,8.91-.81,17.66-2.4,26-5.92.87-.38,2.3-.26,1.84-1.66s-1.67-.61-2.56-.4a20.42,20.42,0,0,0-2.31.9c-18.78,6.92-37.48,6.52-56.17-.44C290.79,355,286.62,354,282.53,352.71ZM242,311.62c-5.27-6.15-13.8-9.19-16.13-18.24a41.81,41.81,0,0,1,1-25.16C215,278.4,224.49,304.42,242,311.62Zm10.72-48.48c-5.72-1.54-7.69-5.72-5.56-10.47.54-1.2,1.38-2.26,2-3.41,1.44-2.58,2.89-5,4.71-.3.36.92.76,1.5,1.72,1.21.32-.09.62-.74.66-1.17.21-2.23-1.83-3.36-2.84-4.88-.77-1.17-2.72-.33-4,.71-4.26,3.49-6.44,11.55-4.42,16.68C246.57,265.3,248.89,266.15,252.76,263.14Zm122.47,31.93c2-.69,5.14.12,5.59-3.32.3-2.28-4.77-7.09-7.14-6.37-3.14,1-2.72,4.66-3.09,7.08S373.12,294.79,375.23,295.07Zm19.24,57.87c2.3.05,3.24-2,4.37-3.46,1.32-1.7,4.57-3.69,3.1-5.44-1.63-2-2.47,2.73-4.51,2.46-1.37-1.58.41-2.44.63-3.68.16-.87,1.38-1.82.12-2.57s-1.91.6-2.05,1.38c-.68,3.78-3.61,5.35-6.5,7-1.07.61-2.72,1-1.47,2.82,2.44,0,3.94-3,6.43-2.31C395.69,350.72,392.72,351.5,394.47,352.94ZM276.31,286.45c-1.29-.72-2-2.38-3.76-2.28a3.27,3.27,0,0,0-3.26,3.07c-.14,1.7.55,3.29,2.52,3.6C274.84,291.31,274.71,288.31,276.31,286.45Zm-55.89,11.2c-1.08,5,2,10.05,5.79,10.35a3.57,3.57,0,0,0,1.81-.47,2.23,2.23,0,0,0-.23-1.27C222.91,305.75,222.84,300.81,220.42,297.65Zm158.27-15.86a1.2,1.2,0,0,0,1.05-1.33c0-.79-.58-1.21-1.22-.94a2,2,0,0,0-1.09,1.32C377.28,281.67,378,281.77,378.69,281.79ZM271.32,339.26c-1.91,2-1.21,3.6.88,5.38C273.28,342.46,271.8,340.9,271.32,339.26Zm7.08,11c-.45.22-1.18.26-1,1.15.48,2,2.45,1.86,3.81,2.56a.82.82,0,0,0,1.13-1C281.78,351.26,279.92,351.18,278.4,350.3Zm1.41-23.14c-.66-.6-.45-2-1.66-2.1s-1.41.51-1.32,1.45a2.07,2.07,0,0,0,1.88,1.91C279.43,328.52,279.75,327.87,279.81,327.16Zm84.27-5a9,9,0,0,0-1.31-.74s-.5.57-.42.74a4.89,4.89,0,0,0,.83,1.07Zm-89.14,26.3c-.35-2.08-.44-3.54-2.13-4.2-.23-.09-1,.48-1,.66A3.8,3.8,0,0,0,274.94,348.44Zm73-8.75.38-.2c-.11-.09-.21-.25-.33-.26s-.24.12-.37.19Zm-72.55,9.4-.35.35a3.43,3.43,0,0,0,.67.32c.08,0,.22-.21.33-.32Z" transform="translate(-191 -159)" style="fill:#fbfbfb"/><path d="M371.59,239.22a34.61,34.61,0,0,1-11.1-21.62c-1.73-13.94-11.37-22.44-21.78-31-16.86-13.93-36.1-15.26-56.25-13.84A22.44,22.44,0,0,0,269.32,178c-3,2.56-7.36,2.69-10.58,5.25a103.39,103.39,0,0,0-18,17.84c-3.74,4.89-7.1,10.52-5.17,17.41.45,1.63-1.15,1.83-2,2.35-6.44,3.83-11.81,9.54-12.48,16.5-.58,6-4.2,6.52-7.6,8.7-3,1.95-5.77,4.38-8.68,6.63-1.27-.94-.49-2.09-.49-3.12,3.76-2.4,6.84-5.8,11.05-7.52,1.42-.58,1.68-1.66,2.08-3,2.1-7.32,5.67-13.75,12-18.37,1.31-1,2.43-1.94,2.53-4a29.08,29.08,0,0,1,7.8-18.79c5.31-5.7,10.25-12,16.91-16.11,9.89-6,19.72-12,32.38-11.73,12.18.25,24.59-.47,35.5,5.23,14.16,7.39,28,15.81,35.05,31.36a42,42,0,0,1,3.22,12.34c.7,5.6,3.47,10.46,7,14.86,1.36,1.67,4.13,2.4,3.72,5.31Z" transform="translate(-191 -159)" style="fill:#161616"/><path d="M408.18,332c-.22.53-.88,1.41-.9,1.29-.59-3.86-3.64-6.34-5.25-9.6-.1-1.67-1.24-1.83-2.55-1.74-.92-2.08-.64-4.29-.3-6.35a41.47,41.47,0,0,0-6-29.32c-2.52-4.1-2.21-8.85-2.32-13.45-.23-9.36-8.42-20.87-16.38-23l-.72-1.75a2.1,2.1,0,0,0,1-2c-.08-.63-1.29-1.32-.08-1.87.9-.41,1.4.41,1.84,1.08.26.75.32,2,.81,2.18,6.1,2.47,8.84,7.82,12.21,13,3.7,5.65,4.54,11.57,4.53,17.93,0,1.94-.55,4,.91,5.73,7.52,8.86,8,19.64,7.59,30.36-.15,3.83.37,6.83,2.71,9.51A11,11,0,0,1,408.18,332Z" transform="translate(-191 -159)" style="fill:#161616"/><path d="M371.59,239.22l2-.13.94.93C373.2,240.92,372.33,240.29,371.59,239.22Z" transform="translate(-191 -159)" style="fill:#302b2c"/><path d="M285.85,315.61c4.12-4.25,1.2-10,3.1-14.78.76-1.93.37-4.32,3.14-4.87l2.5-.63,1.71,5.37-.54,3.13a12.46,12.46,0,0,1-2.38-.11c-.94-.22-1.65-2.18-2.78-.54a3,3,0,0,0,.33,4.05,18.67,18.67,0,0,0,3.31,2l.94.91c-1,.91-.26,1.8.28,2.37s1.4.29,1.85-.52c2.19-3.39,2.72-.42,3.66,1-2.26,3.65-.37,4.79,3,5l-1.15,8.34c-.91.42-2.44-2.8-2.85.49-2,0-3.05-1.33-4-2.84.9-.1,2.2.22,2.36-1,.12-.89-1-1-1.81-1s-1.58.15-2.37.23L293,322C291.31,319.09,288.09,317.9,285.85,315.61Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M325.22,238c1.07-.4,2.16-.78,3.23-1.22,1.42-.58,3.2-4.28,3.95.49L335,236l3,1-.24,2.43c-.67-.22-.73-1.95-1.68-1-.76.76-1.85,2.19-.94,3.24,2.24,2.56,4,6,8.34,5.51.59,3.1-.39,6-1.11,8.92a2.26,2.26,0,0,1-2.37-2c-.21-1.42-.39-3.46-2.13-3.33-1.58.12-1.57,2.16-1.9,3.61-.73,3.25-4.19,4.32-6.57,1.73-1.27-1.39-1.75-2.35-3.16-.51-.93,1.22-2,2.11-3,.25-.7-1.39.13-2.33,1.65-3,2.23-.93,4.51-.85,6.82-.9s3.62-1.23,3-3.44c-.43-1.64-1.24-3.09-3.87-1.86-1.92.89-4.51.36-7,.47.27-1.83,6.3-.28,2.1-4a7,7,0,0,0,0-.79c.68-.44,2.37-.33,1.52-1.68-.62-1-1.56.56-2.47.48C323.51,240,324.7,239,325.22,238Zm6,2.66c.11-.27.37-.6.3-.8s-.5-.24-.76-.36c-.12.27-.39.6-.31.79S331,240.54,331.24,240.66Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M358,309c-.66,4,2,8.53-2,12l-2-1c-.15-.92,0-1.88-1.59-1.75-2.47.19-2.64,2.69-4.16,3.8-2.13-1.26.17-2.88-.34-4.27,1.69-4.12,3.33-8.24-.08-12.33A3.73,3.73,0,0,1,350,303c.59,1.14,1.15,2.3,1.78,3.42,1.16,2.08,1.65.29,2.32-.43,5.4-.16.08-2.77.91-4,1-1.36,2-2.71,3-4.07,2-.56,2.84-4.9,6-1.88,0,.31,0,.61.05.91.06,2.41-1.55,4.59-1,7.07L362,307h0c-1.21.78-3.31-1.87-4,1l-2.15.48Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M359,245.76c0,2.28-.15,4.5,3.42,3.65s3,3,4.09,4.52c1.92,2.75,4.7,5.38,3.59,9.6-.69,2.64-1.79,3.73-4.4,3.37-.3-.95-1.24-1.72-.78-2.88l1.29-.41-1.13-.57c0-1.18-.3-2.46-1.58-2.58s-2.28,1-2.8,2.24c-1.72.39-2.09,1.65-2,3.18-2.09.22-4.32,1-4.94-2.29A2.23,2.23,0,0,0,351,262l-1-2.9c2.29-.79,4.92,1,7.07-.94.26,0,.52,0,.79,0,1.7,3.69,3.79,1,3.81-.37,0-2.15,1.08-2.61,2.73-3.19L348,247.05C351.66,246.52,355.26,245.42,359,245.76Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M364,296.05c-3.14-3-4,1.32-6,1.88l-.89-1c-.2-4.4-.12-8.85-2-13l-.36-2-.7-1.23c0-.62,0-1.24,0-1.85,1.7-1.26,0-3.95,2.12-5,3.1,3.05,2,7.74,4.77,12.52,0-5.84,0-10.25,0-14.67,0-2.44.82-3.06,2.9-1.64L365.13,283v2c-.09,3-.18,6-.28,9l-.69,1c-.05.34-.09.68-.14,1Z" transform="translate(-191 -159)" style="fill:#84abca"/><path d="M282.53,352.71c4.09,1.25,8.26,2.31,12.26,3.8,18.69,7,37.39,7.36,56.17.44a20.42,20.42,0,0,1,2.31-.9c.89-.21,2.15-.86,2.56.4s-1,1.28-1.84,1.66c-8.31,3.52-17.06,5.11-26,5.92-16.29,1.46-31-4.58-45.87-9.55Z" transform="translate(-191 -159)" style="fill:#191919"/><path d="M286,249c-1.68-1.43-3.15-2.69-1.33-5.26,1.59-2.26,3.15-3.07,5.72-1.85,2.13,1,3.92,1.14,3.63-2.13,5.37,1.34,10.94,2,16,4.45,1.8.89,3.37,1.11,4.81-.55a2.28,2.28,0,0,0,2.12,1.36c.86.95,3.19-.56,3.16,1.88l-.24.2c-1.6,0-3.56-.71-3.89,1.9a3.55,3.55,0,0,1-2.13,2c-2,.49-3.42-1-5.18-1.32-5.52-2.69-10.64-7.17-17.51-3.81a8,8,0,0,1-2.4.32C287.06,246.4,287.58,248.73,286,249Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M314.84,243.7c-1.44,1.66-3,1.44-4.81.55-5-2.48-10.6-3.11-16-4.45-5.6-1.83-11.57.29-17.19-1.84,8.49-1.48,16.95-3.68,25.49-.24,2.43,1,4.82,2,7.24,3,1.59.67,3.16,1,4.53-.49,1.56-.34,2.05-4.39,4.6-1.34L315.9,243Z" transform="translate(-191 -159)" style="fill:#191919"/><path d="M317.29,343.29c7.75-.14,15.51-.65,23.24-.31,8.16.35,14.36-2.82,19.5-8.77l.24.13.22-.18c-1,5.25-6,9.8-13.37,10.45-15.53,1.35-31.11,1.87-46.41-2.27-1.36-.37-3.28-.16-3.7-2.24,1.77-1.61,3.25.54,4.91.36l5.07,1.09,4.05.31c1.13.2,2.21,1.85,3.41.12C315.44,342.31,315.87,343.88,317.29,343.29Z" transform="translate(-191 -159)" style="fill:#161616"/><path d="M294.59,295.33l-2.5.63c1.13-10.39-1.65-20.5-2.2-30.77,3.2-1,6.28-2.74,9.84-1.89l-.72,2.78c-4.71-.94-6.67.81-6,5.73a60.15,60.15,0,0,1,.07,8.06c1.15-1.82,1.3-3.8,2-5.54.67-1.57-.16-4.37,3-4.3-.11,1.5,0,2.88,2,3l-.84,3.06,0,1L299,278c-2.05-.08-2.85.88-3,2.95C295.66,285.73,295.07,290.53,294.59,295.33Z" transform="translate(-191 -159)" style="fill:#8396a2"/><path d="M242,311.62c-17.55-7.2-27-33.22-15.17-43.4a41.81,41.81,0,0,0-1,25.16C228.24,302.43,236.77,305.47,242,311.62Z" transform="translate(-191 -159)" style="fill:#202020"/><path d="M359,245.76c-3.77-.34-7.37.76-11,1.29l-4.52.16c-4.32.51-6.1-3-8.34-5.51-.91-1,.18-2.48.94-3.24.95-.93,1,.8,1.68,1l-.16.33.23.28c-.12.85,0,1.87.74,2.13,1.12.39,1.11-.79,1.34-1.49.33-1,.82-1.76,2-1.67l-.21,4c-.12,2.67,1.51,1.95,3,1.53l2-.73c1.4.07,2.85.47,4.12-.51l5.17-1.32a2,2,0,0,0,3,.14,6,6,0,0,0,1.25.7c1.43.37,4-.28,3.67,1.89s-2.67,0-4,.68A6.47,6.47,0,0,1,359,245.76Z" transform="translate(-191 -159)" style="fill:#202020"/><path d="M296,324c.92,1.51,1.94,2.87,4,2.84.36,3.12,2.93,3.83,5.26,4.81A27.38,27.38,0,0,0,329,336.09l2.95-.34a1,1,0,0,0,.85.27l1.13,1.17c0,.86,0,1.72,0,2.58-4.27-1.5-8.64-.44-13-.51l-2.75-.18-4.19-1.15-1.92-.48-3.07-.68L302,332.92l-3-2.08-5.73-6a3.88,3.88,0,0,0-.3-.93l0-1.93,1.2.26Z" transform="translate(-191 -159)" style="fill:#161616"/><path d="M341.93,239.06c-1.21-.09-1.7.68-2,1.67-.23.7-.22,1.88-1.34,1.49-.76-.26-.86-1.28-.74-2.13,2.59-3.79,5.62-6.46,10.76-6.26,3.53.14,5.23-3,7-5.64.74-1.14,1.83-2.82,3.56-1.24,1.26,1.15.87,2.36-.52,3.27-2.91,1.91.22,4.24-.41,6.24C352.45,235.38,347.25,237.59,341.93,239.06Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M252.76,263.14c-3.87,3-6.19,2.16-7.69-1.63-2-5.13.16-13.19,4.42-16.68,1.26-1,3.21-1.88,4-.71,1,1.52,3,2.65,2.84,4.88,0,.43-.34,1.08-.66,1.17-1,.29-1.36-.29-1.72-1.21-1.82-4.68-3.27-2.28-4.71.3-.64,1.15-1.48,2.21-2,3.41C245.07,257.42,247,261.6,252.76,263.14Z" transform="translate(-191 -159)" style="fill:#252525"/><path d="M365.13,283l-1.23-12.93L365,268a3,3,0,0,1,1.88,3.21c-.66,4.61.26,7,5.43,4.27,1.62-.85,2.73.1,2.55,1.76-.22,1.89.93,6-1.46,5.17C370.1,281.26,367.86,283.36,365.13,283Z" transform="translate(-191 -159)" style="fill:#f6f6f6"/><path d="M375.23,295.07c-2.11-.28-5-.16-4.64-2.61s0-6.12,3.09-7.08c2.37-.72,7.44,4.09,7.14,6.37C380.37,295.19,377.23,294.38,375.23,295.07Z" transform="translate(-191 -159)" style="fill:#f6f6f6"/><path d="M394.47,352.94c-1.75-1.44,1.22-2.22.12-3.78-2.49-.64-4,2.35-6.43,2.31-1.25-1.85.4-2.21,1.47-2.82,2.89-1.67,5.82-3.24,6.5-7,.14-.78.75-2.15,2.05-1.38s0,1.7-.12,2.57c-.22,1.24-2,2.1-.63,3.68,2,.27,2.88-4.41,4.51-2.46,1.47,1.75-1.78,3.74-3.1,5.44C397.71,350.92,396.77,353,394.47,352.94Z" transform="translate(-191 -159)" style="fill:#202020"/><path d="M289,259.17c0-.42,0-.84,0-1.26.56-2.14,3.51-1.63,4.12-3.7a2.53,2.53,0,0,0,.72.12c1.45,1.62,3.35.5,5,.83.82,2.13,2.42,4,1.92,6.56C296.68,261.61,292.15,263.56,289,259.17Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M360.73,262.7c.52-1.27,1.42-2.37,2.8-2.24s1.56,1.4,1.58,2.58l-.16,1c-.46,1.16.48,1.93.78,2.88a1,1,0,0,0-.75.2c-2.78,1.89-7.13-1.36-9.22,2.8a2.18,2.18,0,0,0-2.61,0c-1-1.56-2.53-1.8-4.21-1.67l-1-1.18c2.23-1,3.73-2.36,3.1-5.07a2.23,2.23,0,0,1,2.74,1.58c.62,3.26,2.85,2.51,4.94,2.29S361.26,264.53,360.73,262.7Z" transform="translate(-191 -159)" style="fill:#7f8488"/><path d="M355.76,269.9c2.09-4.16,6.44-.91,9.22-2.8q0,.45,0,.9l-1.11,2.08c-2.08-1.42-2.93-.8-2.9,1.64.05,4.42,0,8.83,0,14.67-2.73-4.78-1.67-9.47-4.77-12.52Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M293,322l0,1.93c-2.46.78-3.14-1.74-4.73-2.57l-.58-1.39c.1-.56-.1-.8-.69-.65-4.36-2.58-8.1-5.77-10.34-10.47,3.63,1.55,5.65,5.15,9.15,6.78C288.09,317.9,291.31,319.09,293,322Z" transform="translate(-191 -159)" style="fill:#252525"/><path d="M334,339.77c0-.86,0-1.72,0-2.58,3.49-.4,6.79-1.19,9.1-4.15,2.61-.87,5.18-1.8,7-4.06l.41,0,.4,0,.27,3c-1.22,1.86-3.77,1.53-5.14,3.14l-6,3.09-2,.88c-.81,0-1.61,0-2,.87Z" transform="translate(-191 -159)" style="fill:#252525"/><path d="M289,259.17c3.17,4.39,7.7,2.44,11.79,2.55l2.26.38V265c-.32.09-.63.21-.94.33a2.77,2.77,0,0,0-2.35-2c-3.56-.85-6.64.86-9.84,1.89C288,263.42,283.43,262.06,289,259.17Z" transform="translate(-191 -159)" style="fill:#302b2c"/><path d="M276.31,286.45c-1.6,1.86-1.47,4.86-4.5,4.39-2-.31-2.66-1.9-2.52-3.6a3.27,3.27,0,0,1,3.26-3.07C274.34,284.07,275,285.73,276.31,286.45Z" transform="translate(-191 -159)" style="fill:#dbdbdb"/><path d="M351.12,331.94l-.27-3c-.23-3.45.48-6.56,3.14-9l2,1c.32,3.44-2.67,5.78-3,9h0Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M293.11,254.21c-.61,2.07-3.56,1.56-4.12,3.7-4.08-1.51-3.47-4.67-2.78-7.87l2.19.12C288.47,253.26,290.63,253.92,293.11,254.21Z" transform="translate(-191 -159)" style="fill:#252525"/><path d="M220.42,297.65c2.42,3.16,2.49,8.1,7.37,8.61a2.23,2.23,0,0,1,.23,1.27,3.57,3.57,0,0,1-1.81.47C222.38,307.7,219.34,302.6,220.42,297.65Z" transform="translate(-191 -159)" style="fill:#191919"/><path d="M338,237.05l-3-1c.91-3.86,1.53-7.68.19-11.64-.55-1.64-.91-3.69,1.6-4.47l.33.23c.74,4.89-2,10.2,1.77,14.77C339.13,235.2,338.32,236.33,338,237.05Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M336.8,219.93c-1.82-2.78.49-5.33.52-8,0-1.2,1.18-1.83,2.6-1.33,1.89.66.63,1.52.39,2.53a16.74,16.74,0,0,1-3.18,7Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M364.85,294c.1-3,.19-6,.28-9C370,290.07,369.88,292.69,364.85,294Z" transform="translate(-191 -159)" style="fill:#f6f6f6"/><path d="M288.31,321.34c1.59.83,2.27,3.35,4.73,2.57a3.88,3.88,0,0,1,.3.93c-.89,3.06-4.1.78-5.6,2.44C286.13,325.13,287.53,323.27,288.31,321.34Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M360.49,334.16l-.22.18-.24-.13c-1.3-3.11,1.68-4.73,2.28-7.18C363.51,329.93,363.56,332.49,360.49,334.16Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M340,338.17l6-3.09c.08,1.84.07,3.66-2.14,4.39C342.25,340,340.6,340.58,340,338.17Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M314.07,337.93l4.19,1.15-.91.54a5,5,0,0,0-.06,3.67c-1.42.59-1.85-1-2.84-1.31C316.28,340.44,315.83,339.12,314.07,337.93Z" transform="translate(-191 -159)" style="fill:#202020"/><path d="M326.05,242.29a7,7,0,0,1,0,.79c-2.06.28-3.83-.16-5-2,0-.68,0-1.36,0-2,1.42-.31,2.22-3.17,4.23-1-.51,1-1.7,2-.11,3.09Z" transform="translate(-191 -159)" style="fill:#dbdbdb"/><path d="M309.08,336.77l3.07.68a8.81,8.81,0,0,1-1.11,4.41l-4.05-.31C307.55,339.89,309.58,338.88,309.08,336.77Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M318.73,238.92c-2.55-3-3,1-4.6,1.34-1.9-3.57,3-2.94,3.22-5.21a3.63,3.63,0,0,1,2.67,4Z" transform="translate(-191 -159)" style="fill:#dbdbdb"/><path d="M318.73,238.92,320,239l1,0c0,.67,0,1.35,0,2-.36,2.62-2.43,1.8-4,2l-1.1,0Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M288,333.57c.11-1.09-.11-2.61,1.68-2.17,2.49.61,2.41,2.71,2.31,4.7l-2-.13,0,0C290.32,334.4,288.69,334.37,288,333.57Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M363.07,304c-.58-2.48,1-4.66,1-7.07,3.79,1.05.46,3.41.94,5.08,0,.3,0,.61,0,.92Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M301.92,340.46c-1.66.18-3.14-2-4.91-.36l0-.11c.57-.38.6-.79.08-1.24,0-.86.51-2.21,1-2C299.7,337.55,302.13,337.73,301.92,340.46Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M399.48,321.91c1.31-.09,2.45.07,2.55,1.74-3.23-1.3-1.51,2.21-3.1,2.9A5.54,5.54,0,0,1,399.48,321.91Z" transform="translate(-191 -159)" style="fill:#302b2c"/><path d="M299.07,330.84l3,2.08c-.95,1.18-2.2,1.45-3.3.5C297.82,332.64,298.83,331.69,299.07,330.84Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M378.69,281.79c-.66,0-1.41-.12-1.26-1a2,2,0,0,1,1.09-1.32c.64-.27,1.22.15,1.22.94A1.2,1.2,0,0,1,378.69,281.79Z" transform="translate(-191 -159)" style="fill:#f6f6f6"/><path d="M271.32,339.26c.48,1.64,2,3.2.88,5.38C270.11,342.86,269.41,341.25,271.32,339.26Z" transform="translate(-191 -159)" style="fill:#191919"/><path d="M278.4,350.3c1.52.88,3.38,1,4,2.7a.82.82,0,0,1-1.13,1c-1.36-.7-3.33-.6-3.81-2.56C277.22,350.56,278,350.52,278.4,350.3Z" transform="translate(-191 -159)" style="fill:#252525"/><path d="M373.78,248l.72,1.75c-1.05-.11-1.4,2.46-2.51,1C370.62,249,372.14,248.27,373.78,248Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M359,242.19a2,2,0,0,1-3-.14c.14-.73.13-1.66,1.18-1.61S358.64,241.34,359,242.19Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M317.35,339.62l.91-.54,2.75.18C320.05,342,318.87,342.47,317.35,339.62Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M370,252c-1-.16-2-.38-1.77-1.71.05-.31.72-.82.92-.75,1.19.44.75,1.56.86,2.45Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M279.81,327.16c-.06.71-.38,1.36-1.1,1.26a2.07,2.07,0,0,1-1.88-1.91c-.09-.94.24-1.59,1.32-1.45S279.15,326.56,279.81,327.16Z" transform="translate(-191 -159)" style="fill:#161616"/><path d="M288.4,250.16l-2.19-.12-.17-1c1.54-.31,1-2.64,2.73-2.77l.39,2.1A1.62,1.62,0,0,1,288.4,250.16Z" transform="translate(-191 -159)" style="fill:#302b2c"/><path d="M288,333.57c.67.8,2.3.83,2,2.44-2.44,1.64-3.63-.62-4.16-2C285.45,333,287.12,333.22,288,333.57Z" transform="translate(-191 -159)" style="fill:#161616"/><path d="M350.8,243.37c-1.27,1-2.72.58-4.12.51C347.68,240.65,349.28,242.31,350.8,243.37Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M290,336l2,.13c.23.86,1.91.94,1.28,2.16a2.22,2.22,0,0,1-1.51.54C291.2,337.84,288.44,338.21,290,336Z" transform="translate(-191 -159)" style="fill:#161616"/><path d="M364.08,322.14l-.9,1.07a4.89,4.89,0,0,1-.83-1.07c-.08-.17.37-.76.42-.74A9,9,0,0,1,364.08,322.14Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M336,339.92c.4-.9,1.2-.91,2-.87-.11.9-.16,2-1.23,2.16C336,341.34,336.05,340.48,336,339.92Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M274.94,348.44a3.8,3.8,0,0,1-3.14-3.54c0-.18.78-.75,1-.66C274.5,344.9,274.59,346.36,274.94,348.44Z" transform="translate(-191 -159)" style="fill:#191919"/><path d="M276,322c.85.24,1.75-.86,2.55.11.06.07,0,.36-.14.43A1.6,1.6,0,0,1,276,322Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M344.7,244.61c-1.47.42-3.1,1.14-3-1.53A3.37,3.37,0,0,1,344.7,244.61Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M353,330c1.09-.5,2-.73,2,1h0c-1.08.5-2,.73-2-1Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M276,322l-1.94-.25.3-.61L276,322Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M358,309l-2.12-.52L358,308Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M297.06,338.75c.52.45.49.86-.08,1.24-1,1.66-1.89.3-2.73-.2a1.17,1.17,0,0,1-.25-1.12C295,337.46,296,339,297.06,338.75Z" transform="translate(-191 -159)" style="fill:#161616"/><path d="M365,303c0-.31,0-.62,0-.92l1.24.45Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M367,246l-.73-1c1.14-.29.45.7.72,1Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M355,331l1.26.36c-.71.9-.9,0-1.26-.36Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M347.94,339.69l-.32-.27c.13-.07.26-.2.37-.19s.22.17.33.26Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M370,252l.41.24L370,252Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M367,246l.38.21L367,246Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M364,296c.05-.34.09-.68.14-1a3.44,3.44,0,0,1,.21.76C364.38,295.82,364.15,295.92,364,296Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M287,319.3c.59-.15.79.09.69.65A1,1,0,0,1,287,319.3Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M362,307l.4.23L362,307Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M275.39,349.09l.65.35c-.11.11-.25.33-.33.32a3.43,3.43,0,0,1-.67-.32Z" transform="translate(-191 -159)" style="fill:#191919"/><path d="M332.84,336a1,1,0,0,1-.85-.27c-.12-1.05.17-2.54-1.42-2.53-1.94,0-1.42,1.69-1.53,2.87a27.38,27.38,0,0,1-23.77-4.48,9.38,9.38,0,0,0-2.41-5.3c.38-2.78.77-5.56,1.15-8.34h0c1.71-.27,3.43-.54,2.12-3l-.05-2.48,0-.1,1.95-.71c3,1.68,5.84.89,9.59-.46l-3.6-.53a1.35,1.35,0,0,0-.63-.68l-.41-1.94c.37-1-.52-3.26,2.06-2.11l-.12,1.58c1.09.05,1-.81,1.12-1.48,2.78-.67,5.28,1.1,8,.92,1.13,1.35,1.66.7,2-.59,3.07-1.54,6.48,0,9.6-1.1.18,1.58.35,3.15.53,4.73-1.13,2.34-3.31,1.57-5.2,1.84-4.15.6-8.48-2-12.68.76,3,.72,5.85.47,8.7.37s6,0,9,0l-.31,2.95L324,316c-4,2.15-8,3.21-12.36,1.17a2.37,2.37,0,0,0-3.54,1.55c-.69,2.23,1,2.48,2.52,2.51,3.13.07,6.27-.05,9.41-.08.33.57.65,1.15,1,1.73-.48.87,0,1.28.75,1.52q.64,3.72,1.3,7.44c.31,1.89,1.25,3.23,3.18,2,1.09-.7.36-1.64-.89-1.82-.1-1-.21-2.05-.31-3.08,3.38-1.49,1.84-2.78-.16-4.06a.92.92,0,0,1,.23-.79l9.91.15c.67,3.29-1.54,3.87-5.25,3.89C336,329.85,336.28,331.13,332.84,336Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M295.18,310.17l-.94-.91q.75-2.72,1.52-5.43l.54-3.13a4,4,0,0,0,.85-3.41c2.31-1.37,2-4.24,3.44-6.09.62-2.67,1.85-4.91,4.42-6.2.07,1,.15,2,.23,3-.18.41-.35.83-.52,1.24a24.81,24.81,0,0,0-4.53,9.3,5.25,5.25,0,0,0-1.29,3.4c-1.13.95-1.06,2.28-1.12,3.57a4.2,4.2,0,0,0-1.09,3.26Z" transform="translate(-191 -159)" style="fill:#252525"/><path d="M297.15,297.29a4,4,0,0,1-.85,3.41l-1.71-5.37c.48-4.8,1.07-9.6,1.41-14.41.15-2.07.95-3,3-2.95-.45,4.34-1.89,8.6-1,13C297.18,293,295.93,295,297.15,297.29Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M296.69,308.78a4.2,4.2,0,0,1,1.09-3.26c2,1.8,3.58,4.38,6.75,4.48l-.46,1.33-.11,1.53,0,.09-3,0c-.94-1.38-1.47-4.35-3.66-1C297.11,310.93,296.9,309.86,296.69,308.78Z" transform="translate(-191 -159)" style="fill:#fbfbfb"/><path d="M295.76,303.83q-.76,2.71-1.52,5.43a18.67,18.67,0,0,1-3.31-2,3,3,0,0,1-.33-4.05c1.13-1.64,1.84.32,2.78.54A12.46,12.46,0,0,0,295.76,303.83Z" transform="translate(-191 -159)" style="fill:#8396a2"/><path d="M302.86,326.31a9.38,9.38,0,0,1,2.41,5.3c-2.33-1-4.9-1.69-5.26-4.81C300.42,323.51,302,326.73,302.86,326.31Z" transform="translate(-191 -159)" style="fill:#7f8488"/><path d="M301,313l3,0,.11,2.94,0,2.08h0C300.6,317.77,298.71,316.63,301,313Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M296.69,308.78c.21,1.08.42,2.15.62,3.24-.45.81-1.19,1.24-1.85.52s-1.32-1.46-.28-2.37Z" transform="translate(-191 -159)" style="fill:#8396a2"/><path d="M296,324l-1.82-1.72c.79-.08,1.58-.2,2.37-.23s1.93.09,1.81,1C298.24,324.18,296.94,323.86,296,324Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M298,291c-.9-4.43.54-8.69,1-13l.24-.94c3.62.65,4.3-.92,3-4,.55-.7,1.11-1.39,1.67-2.09,3.62,1,4.75-.57,4.1-4,.69-1.47,1.88-1,3-.77.13,1.23,0,3.06,1.88,2.45,1.46-.48,2.7-1.86,1.11-3.67,0-2.35,0-4.69,0-7l-.07.1c.11-.05.31-.11.31-.17a2,2,0,0,0-.11-.51A2,2,0,0,0,312.2,256c-1-2.1,1.7-1.74,2-3q4.65-.28,1.82-4c.33-2.61,2.29-1.89,3.89-1.9l.42,1.19a3.6,3.6,0,0,0,.49-.36c-.2-.36-.44-.69-.67-1,0-2.44-2.3-.93-3.15-1.88l0-2c1.57-.19,3.64.63,4-2,1.18,1.87,2.95,2.31,5,2,4.2,3.77-1.83,2.22-2.1,4,2.46-.11,5,.42,7-.47,2.63-1.23,3.44.22,3.87,1.86.6,2.21-.78,3.4-3,3.44s-4.59,0-6.82.9c-1.52.64-2.35,1.58-1.65,3,.93,1.86,2,1,3-.25,1.41-1.84,1.89-.88,3.16.51,2.38,2.59,5.84,1.52,6.57-1.73.33-1.45.32-3.49,1.9-3.61,1.74-.13,1.92,1.91,2.13,3.33a2.26,2.26,0,0,0,2.37,2,3,3,0,0,1-.11.79.6.6,0,0,0-.6.22c-.39,1.05-4,.28-1.65,2.88-.1,1.75.13,3.36,1.93,4.24A19.09,19.09,0,0,0,342,272l-1,1.07a7.43,7.43,0,0,1-2.91-3.1c1.34-3.25,2.11-6.33-2.32-7.87-.79-.6-1.64-2.17-1.94.4-.35,3,1,5.6,1.77,8.34a3.27,3.27,0,0,0-2.65,1.11,4.69,4.69,0,0,0-4.82-.11,4.21,4.21,0,0,0-1.25-.73c-1.15-.21-2.37-.25-3.07.94a1.32,1.32,0,0,0,.29,1.24c1.42,1.1,1.87-.77,2.88-1,.32-.08.65-.13,1-.19L333,274c1.76,1.67,3.21-.45,4.84-.39,6.52,5.67,6.42,4,1.5,11.41-1.81,0-2.4,1.21-2.69,2.72l-.83-.42a11.23,11.23,0,0,0-2.18-.49c-.6,1.43.46,2.31,1.32,3.23l0,12.83-3,0a41.34,41.34,0,0,0-.07-6.3c-.56-3.54-1.75-6.8-5.91-7.64a3.3,3.3,0,0,0-3-2.19l-.59-1.11-.43,1.23-2,.13c-.31-.52-.62-1.49-.92-1.48-1.15,0-.94,1.07-1,1.85-2.55.2-4.56-.44-5.06-3.34a2.39,2.39,0,0,0,.05-2.84l1.94-.31c2.71,1.57,2.33-1,2.84-2.21a1.09,1.09,0,0,0-1-1.43c-2.14-.18-1.72,1.47-1.84,2.71-5.88-.27-6.43.53-3.81,5.73.35.71,1,1.26.8,2.17a4.56,4.56,0,0,0-.95,3.71c.32,1.9-2.78,4.74.09,5.32,2.29.46,4.17-2.57,4.76-5.3a5.24,5.24,0,0,0-.12-1.46l3.15-.26,5.18,3.84c-.07,1.2-.29,2.44.94,3.26q0,3,0,6.1c-3.37,1.58-6.67.72-10-.28-1-2.27-2-2.52-3.09-.08l-2,0c-.3-.46-.55-1.28-.89-1.32-1-.12-1,.82-1.12,1.53l-2.62,4.18c-.79-3.45-4.1-3.77-6.49-5.23a5.25,5.25,0,0,1,1.29-3.4c4,1,2.56-3.73,4.82-4.56.21,1.46-.63,3.53,2.4,3.94L305,294l-.3-4.74.53-1.24c.79-.17,1.55-.4,1.6-1.38.06-1.27-.85-1.5-1.83-1.63-2.57,1.29-3.8,3.53-4.42,6.2Zm9.6-7.73c-.1-.27-.15-.69-.33-.77s-.53.17-.8.27c.1.27.14.69.33.77S307.34,283.38,307.61,283.27Zm21.78-15.07a3.53,3.53,0,0,0,.49-.69c.05-.12-.06-.31-.1-.46-.22.07-.62.15-.62.22A4.66,4.66,0,0,0,329.39,268.2Zm-19.12,31.18-.4-.14c0,.11-.14.3-.11.33a1.23,1.23,0,0,0,.39.16Zm6.34-30.1.14-.4c-.11,0-.3-.15-.33-.11a1.14,1.14,0,0,0-.16.39Z" transform="translate(-191 -159)" style="fill:#fbfbfb"/><path d="M342.25,256.92a3,3,0,0,0,.11-.79c.72-2.93,1.7-5.82,1.11-8.92l4.52-.16,16.41,7.57c-1.65.58-2.69,1-2.73,3.19,0,1.38-2.11,4.06-3.81.37a19.43,19.43,0,0,0-.12-3.42c-.31-1.54-1.87-1.73-3.06-2.21-.25-.11-1,.38-1.11.69-.3,1.46,1,2,1.89,2.56a3.47,3.47,0,0,1,1.61,2.37c-2.15,1.9-4.78.15-7.07.94-1-.45-2.47.34-3.23-1,.44-.85,1.25-.87,2.07-1,1.12-.19,2.92.78,3-1.4.05-1.11.18-2.41-.78-3.26-1.14-1-2.55-.51-3.77-.16-3.31.95-1.7,3.77-2.06,5.84C343.92,258.57,343.08,257.74,342.25,256.92Z" transform="translate(-191 -159)" style="fill:#302b2c"/><path d="M326.05,242.29l-.95-1.2c.91.08,1.85-1.46,2.47-.48C328.42,242,326.73,241.85,326.05,242.29Z" transform="translate(-191 -159)" style="fill:#7f8488"/><path d="M331.23,240.66c-.27-.12-.68-.18-.76-.37s.19-.52.31-.79c.26.12.68.17.76.36S331.35,240.39,331.23,240.66Z" transform="translate(-191 -159)" style="fill:#fbfbfb"/><path d="M348.94,268.26c1.68-.13,3.21.11,4.21,1.67a7.19,7.19,0,0,0-.1.92,9.37,9.37,0,0,0,.75,8.14l.32-.1c0,.61,0,1.23,0,1.85l.7,1.23.36,2c-1.57,3.66-.45,11,2,13l.89,1c-1,1.36-2,2.71-3,4.07l-2.35.11-1.11-4c1.85-1.15,1.2-1.76-.47-2.14-.34-.74-.74-1.46-1-2.22s0-2.34-1.39-2.16c-1.83.24-1,1.83-.78,2.76.5,2.56,1.23,5.07,1.87,7.61-3.21.55-6-.63-8.66-2.19-.7-2.93-1.41-5.87-2.11-8.8l1.76-1.49c.85,1.32,2.19,2.19,2.92.36,1.17-2.92,3.39-5.9,1.12-9.3,0-1.19.06-2.37.08-3.56,1-.12,1.93-.35,1.91-1.6a1.19,1.19,0,0,0-1.2-1.21c-1.25,0-1.47.93-1.6,1.91-1.51-.49-2.25-1.77-3-3l1-1.07C345.49,273,347.19,270.57,348.94,268.26Z" transform="translate(-191 -159)" style="fill:#fbfbfb"/><path d="M305.39,307.18,308,303l2-.21,2,0,3.09.08c3.29,1,6.59,1.86,10,.28l1.79-.36,2.19.18h3l3,0,3,.08,3,0a10.08,10.08,0,0,1,6.87,2.42c3.41,4.09,1.77,8.21.08,12.33l-1.89.32-.08-1.22c.38-2.55.22-4.52-3.31-3.91a37.79,37.79,0,0,1-5.33.18l-1.37-.12c-3,0-6-.08-9,0s-5.69.35-8.7-.37c4.2-2.76,8.53-.16,12.68-.76,1.89-.27,4.07.5,5.2-1.84h.43L337,310c1.76,3.59,4.77,1.78,7.29,1.53,1.53-.15,2.08-1.59,1.66-3.07-.84-2.91-3.05-3.56-5.76-3.29-.66.06-1.33,0-2,0l-2.57.14c-3.12,1.08-6.53-.44-9.6,1.1a1.27,1.27,0,0,0-2,.59c-2.73.18-5.23-1.59-8-.92l-1-.1c-2.58-1.15-1.69,1.09-2.06,2.1-1.69-.18-.3-3.68-3-2.79-2.44.79-1.93,2.72-1.86,4.5,0,.33,0,.66.06,1a2.61,2.61,0,0,0-.11.92l-1.95.71c-.69-.15-1,.13-1,.83l-1-1.92.46-1.33Z" transform="translate(-191 -159)" style="fill:#161616"/><path d="M346,318.07l1.89-.32c.51,1.39-1.79,3,.34,4.27q-1.07,2.46-2.14,4.92c.22,2.65-3.23,3.46-3,6.1-2.31,3-5.61,3.75-9.1,4.15L332.84,336c3.44-4.89,3.13-6.17-3.1-7.87,3.71,0,5.92-.6,5.25-3.89,2.8-1.08,6.49,1.43,8.68-2.14,1.32-.62,1.29-1.83,1.32-3Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M351.53,298.13l1.11,4,1.44,3.86c-.67.72-1.16,2.51-2.32.43-.63-1.12-1.19-2.28-1.78-3.42l-.22-1c-.64-2.54-1.37-5.05-1.87-7.61-.18-.93-1.05-2.52.78-2.76,1.39-.18,1.08,1.31,1.39,2.16s.66,1.48,1,2.22C351.22,296.7,351.38,297.42,351.53,298.13Z" transform="translate(-191 -159)" style="fill:#202020"/><path d="M346.1,326.94q1.08-2.46,2.14-4.92c1.52-1.11,1.69-3.61,4.16-3.8,1.56-.13,1.44.83,1.59,1.75-2.66,2.45-3.37,5.56-3.14,9l-.4,0-.41,0C348.85,328.06,348,326.43,346.1,326.94Z" transform="translate(-191 -159)" style="fill:#84abca"/><path d="M349.76,302l.22,1a3.73,3.73,0,0,0-2.16,2.44A10.08,10.08,0,0,0,341,303l.15-3.21C343.78,301.35,346.55,302.53,349.76,302Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M354.08,306l-1.44-3.86L355,302C354.16,303.2,359.48,305.81,354.08,306Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M342.25,256.92c.83.82,1.67,1.65,3,1.2h1.51c.76,1.34,2.19.55,3.23,1l1,2.9c.63,2.71-.87,4.11-3.1,5.07-3-1.28-2.95-1.26-1.27-3.95a1.76,1.76,0,0,0-.43-2.61c-1.35-.64-3-.86-3.59,1.09-.24.86.28,1.94-.7,2.65-1.8-.88-2-2.49-1.93-4.24,1-.67,2-1.4,1.65-2.88A.6.6,0,0,1,342.25,256.92Z" transform="translate(-191 -159)" style="fill:#dbdbdb"/><path d="M357.07,258.17a3.47,3.47,0,0,0-1.61-2.37c-.89-.59-2.19-1.1-1.89-2.56.07-.31.86-.8,1.11-.69,1.19.48,2.75.67,3.06,2.21a19.43,19.43,0,0,1,.12,3.42C357.59,258.19,357.33,258.18,357.07,258.17Z" transform="translate(-191 -159)" style="fill:#645c5d"/><path d="M360.73,262.7c.53,1.83.13,3.07-2,3.18C358.64,264.35,359,263.09,360.73,262.7Z" transform="translate(-191 -159)" style="fill:#84abca"/><path d="M365,264l.16-1,1.13.57Z" transform="translate(-191 -159)" style="fill:#fbfbfb"/><path d="M357.12,296.93c-2.43-2-3.55-9.34-2-13C357,288.08,356.92,292.53,357.12,296.93Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M353.05,270.85a7.19,7.19,0,0,1,.1-.92,2.18,2.18,0,0,1,2.61,0l.48,4c-2.14,1.07-.42,3.76-2.12,5l-.32.1C353.71,276.26,354.69,273.44,353.05,270.85Z" transform="translate(-191 -159)" style="fill:#8396a2"/><path d="M354.78,282l-.7-1.23Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M289.16,248.37l-.39-2.1a8,8,0,0,0,2.4-.32c6.87-3.36,12,1.12,17.51,3.81l-2.93.45c-1.65-.5-1.48,1.74-2.74,1.83-1.49-3.7-4.26-4.82-8-4C293.1,248.82,291,246.55,289.16,248.37Z" transform="translate(-191 -159)" style="fill:#161616"/><path d="M305.75,250.21l2.93-.45c1.76.31,3.22,1.81,5.18,1.32.1.65.21,1.3.31,1.95-.27,1.25-3,.89-2,3a5.1,5.1,0,0,0-.39.9.91.91,0,0,0-.88.19,6,6,0,0,1-.83-.22C312.77,252,307.44,252.28,305.75,250.21Z" transform="translate(-191 -159)" style="fill:#252525"/><path d="M314.17,253c-.1-.65-.21-1.3-.31-1.95a3.55,3.55,0,0,0,2.13-2Q318.83,252.75,314.17,253Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M317,243l0,2a2.28,2.28,0,0,1-2.13-1.36l1.06-.7Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M311,341.86a8.81,8.81,0,0,0,1.11-4.41l1.92.48c1.76,1.19,2.21,2.51.38,4.05C313.25,343.71,312.17,342.06,311,341.86Z" transform="translate(-191 -159)" style="fill:#fbfbfb"/><path d="M298.07,270c-3.12-.07-2.29,2.73-3,4.3-.74,1.74-.89,3.72-2,5.54a60.15,60.15,0,0,0-.07-8.06c-.66-4.92,1.3-6.67,6-5.73l1,1.32,0,1.08Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M300,268.48c0-.36,0-.72,0-1.09.87-.53,2-.77,2.09-2.11.31-.12.62-.24.94-.33h2c.44,1.3-1,2-1.05,3.1-2.38.93-.84,1.94-.06,2.93l-1.68,2.08c-.91,1.1-1.13,2.89-3,3L300,273C300,271.49,300,270,300,268.48Z" transform="translate(-191 -159)" style="fill:#dbdbdb"/><path d="M302.08,265.28c-.05,1.34-1.22,1.58-2.09,2.11l-1-1.31.72-2.78A2.77,2.77,0,0,1,302.08,265.28Z" transform="translate(-191 -159)" style="fill:#645c5d"/><path d="M299.2,276.05c1.89-.11,2.11-1.9,3-3,1.32,3.06.64,4.63-3,4C299.23,276.7,299.22,276.38,299.2,276.05Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M300,268.48c0,1.5,0,3,0,4.51-2-.08-2.08-1.46-2-3C298.72,269.51,299.37,269,300,268.48Z" transform="translate(-191 -159)" style="fill:#7f8488"/><path d="M329,336.09c.11-1.18-.41-2.85,1.53-2.87,1.59,0,1.3,1.48,1.42,2.53Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M305.75,250.21c1.69,2.07,7,1.77,4.35,6.68-2.23.22-4.39-2.66-6.5-.56-1.72,1.71.35,3.67.53,5.54l-1.1.23-2.26-.38c.5-2.52-1.1-4.43-1.92-6.56a2.08,2.08,0,0,0,1.19-1.81l3-1.31C304.27,252,304.1,249.71,305.75,250.21Z" transform="translate(-191 -159)" style="fill:#7f8488"/><path d="M289.16,248.37c1.86-1.82,3.94.45,5.85-.33v3.21l-1.18,3.08a2.53,2.53,0,0,1-.72-.12c-2.48-.29-4.64-1-4.71-4.05A1.62,1.62,0,0,0,289.16,248.37Z" transform="translate(-191 -159)" style="fill:#c28187"/><path d="M293.83,254.33c.39-1,.78-2.05,1.18-3.08,2.74-1.86,4-.18,5,2.1a2.08,2.08,0,0,1-1.19,1.81C297.18,254.83,295.28,256,293.83,254.33Z" transform="translate(-191 -159)" style="fill:#645c5d"/><path d="M341.93,264.26c1-.71.46-1.79.7-2.65.55-1.95,2.24-1.73,3.59-1.09a1.76,1.76,0,0,1,.43,2.61c-1.68,2.69-1.72,2.67,1.27,3.95l1,1.18c-1.75,2.31-3.45,4.71-7,3.75A19.09,19.09,0,0,1,341.93,264.26Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M346.1,326.94c1.94-.51,2.75,1.12,3.94,2-1.79,2.26-4.36,3.19-7,4.06C342.87,330.4,346.32,329.59,346.1,326.94Z" transform="translate(-191 -159)" style="fill:#8396a2"/><path d="M303,262.1l1.1-.23,4.81-.09.3,1.58a1.56,1.56,0,0,1-.57.57,2,2,0,0,0-.79.19c-1,.2-2.25-.65-2.87.82h-2C303,264,303,263.05,303,262.1Z" transform="translate(-191 -159)" style="fill:#161616"/><path d="M346,318.07l-1,1c-2.4-.2-4.85-.75-7,.91-4.34.66-8.59,1.94-13,1.9l.11.07a6.28,6.28,0,0,0-5.06-.81c-3.14,0-6.28.15-9.41.08-1.49,0-3.21-.28-2.52-2.51a2.37,2.37,0,0,1,3.54-1.55c4.39,2,8.41,1,12.36-1.17.12,1.94,1,3.12,3.07,2.7,3-.59,6.54.66,8.57-2.78l.31-2.95,1.37.12c-.58,2.79,0,4.32,3.38,3.63,1.68-.34,3.5.05,5.26.1Z" transform="translate(-191 -159)" style="fill:#202020"/><path d="M335.61,316c-2,3.44-5.61,2.19-8.57,2.78-2.07.42-3-.76-3.07-2.7Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M343.67,322.12c-2.19,3.57-5.88,1.06-8.68,2.14l-9.91-.15-3.35.32c-.78-.24-1.23-.65-.75-1.52l4.08-.92-.11-.07c4.24,2.3,8.72.46,13.08.75C340,323.62,341.74,321.77,343.67,322.12Z" transform="translate(-191 -159)" style="fill:#302b2c"/><path d="M308.1,310.79c0-.33-.05-.66-.06-1-.07-1.78-.58-3.71,1.86-4.5,2.74-.89,1.35,2.61,3,2.79.14.65.28,1.3.41,2a.58.58,0,0,1-.27.44C311.39,310.08,309.82,311.65,308.1,310.79Z" transform="translate(-191 -159)" style="fill:#84abca"/><path d="M321.73,324.43l3.35-.32a.92.92,0,0,0-.23.79c-1,1.4-.31,2.72.16,4.06.1,1,.21,2.05.31,3.08l-2.29-.17Q322.37,328.15,321.73,324.43Z" transform="translate(-191 -159)" style="fill:#8396a2"/><path d="M308.1,310.79c1.72.86,3.29-.71,5-.3l.9.23,3.6.53c-3.75,1.35-6.62,2.14-9.59.46A2.61,2.61,0,0,1,308.1,310.79Z" transform="translate(-191 -159)" style="fill:#252525"/><path d="M323,331.87l2.29.17c1.25.18,2,1.12.89,1.82C324.28,335.1,323.34,333.76,323,331.87Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M325,329c-.47-1.34-1.16-2.66-.16-4.06C326.85,326.18,328.39,327.47,325,329Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M304,318l0-2.08,2.09-.89C307.45,317.43,305.73,317.7,304,318Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M325.06,322l-4.08.92c-.33-.58-.65-1.16-1-1.73A6.28,6.28,0,0,1,325.06,322Z" transform="translate(-191 -159)" style="fill:#dbdbdb"/><path d="M337,310l-.42.09h-.43c-.18-1.58-.35-3.15-.53-4.73l2.57-.14C337.78,306.78,337.39,308.38,337,310Z" transform="translate(-191 -159)" style="fill:#645c5d"/><path d="M306.14,315l-2.09.89-.11-2.94,0-.09a.65.65,0,0,1,1.06.34l1.07-.68Z" transform="translate(-191 -159)" style="fill:#252525"/><path d="M324,307a1.27,1.27,0,0,1,2-.59C325.67,307.71,325.14,308.36,324,307Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M315,306l1,.1c-.14.67,0,1.53-1.12,1.48Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M314,310.72l-.9-.23a.62.62,0,0,0,.27-.45A1.35,1.35,0,0,1,314,310.72Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M306.09,312.52c-.35.23-.71.45-1.07.67l0,.06c0-.7.3-1,1-.83Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M305.39,307.18l-.86,2.82c-3.17-.1-4.71-2.68-6.75-4.48.06-1.29,0-2.62,1.12-3.57C301.29,303.41,304.6,303.73,305.39,307.18Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M305,294c-2.26.83-.85,5.54-4.82,4.56a24.81,24.81,0,0,1,4.53-9.3c.09,1.58.19,3.16.29,4.74Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M298,291l2.58.2c-1.47,1.85-1.13,4.72-3.44,6.09C295.93,295,297.18,293,298,291Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M305,285c1,.13,1.89.36,1.83,1.63,0,1-.81,1.21-1.6,1.38C305.16,287,305.08,286,305,285Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M305.05,313.25l0-.06a.66.66,0,0,0-1.06-.33l.11-1.53C304.4,312,304.73,312.61,305.05,313.25Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M344.87,277l-.08,3.56c-1.57,2.34-3.48,4.5-3.94,7.43l-1.73,0,.21-3c4.92-7.42,5-5.74-1.5-11.41-.07-1.47-1.14-2.13-2.24-2.77-.76-2.74-2.12-5.31-1.77-8.34.3-2.57,1.15-1,1.94-.4a9.44,9.44,0,0,0,2.32,7.87,7.43,7.43,0,0,0,2.91,3.1c.74,1.25,1.48,2.53,3,3Z" transform="translate(-191 -159)" style="fill:#191919"/><path d="M329,302.93l-2.19-.18c-.39-1.94.82-4-.52-5.86a3.92,3.92,0,0,0-2.22-3.14l-5.18-3.84,0-2.36,1.12-.5,2-.13,1-.12a3.3,3.3,0,0,1,3,2.19c-2.35.28-2.73,1.68-.91,2.79C329.57,294.53,329.15,298.72,329,302.93Z" transform="translate(-191 -159)" style="fill:#8396a2"/><path d="M329,302.93c.12-4.21.54-8.4-3.93-11.15-1.82-1.11-1.44-2.51.91-2.79,4.16.84,5.35,4.1,5.91,7.64a41.34,41.34,0,0,1,.07,6.3Z" transform="translate(-191 -159)" style="fill:#f6f6f6"/><path d="M305,264.94c.62-1.47,1.89-.62,2.87-.82.34.25.68.51.79-.19a1.51,1.51,0,0,0,.57-.58c1.61-.4,2.27-1.09.69-2.41l1-3.83a.91.91,0,0,1,.88-.19A1.72,1.72,0,0,0,314,258c0,2.35,0,4.69,0,7l-3,1.22c-1.11-.21-2.3-.7-3,.77l-4,1C304,266.91,305.45,266.24,305,264.94Z" transform="translate(-191 -159)" style="fill:#7f8488"/><path d="M318.88,287.55l0,2.36-3.15.26.05,0L314,289.09l-2-1.19c.24-.91-.45-1.46-.8-2.17-2.62-5.2-2.07-6,3.81-5.73a2.64,2.64,0,0,1,0,.93l-1.94.31c-1.66.92-1,1.87-.05,2.84.5,2.9,2.51,3.54,5.06,3.34l.38.29Z" transform="translate(-191 -159)" style="fill:#161616"/><path d="M312,287.9l2,1.19c.22,1,.53,1.83,1.81,1.12l-.05,0a5.24,5.24,0,0,1,.12,1.46c-.59,2.73-2.47,5.76-4.76,5.3-2.87-.58.23-3.42-.09-5.32A4.56,4.56,0,0,1,312,287.9Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M338,303l-3-.08,0-12.83a8.69,8.69,0,0,1,.88-.07l1.49.7C337,294.82,339,298.82,338,303Z" transform="translate(-191 -159)" style="fill:#f6f6f6"/><path d="M338.08,270a9.44,9.44,0,0,1-2.32-7.87C340.19,263.65,339.42,266.73,338.08,270Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M304,268l4-1c.65,3.4-.48,5-4.1,4C303.12,270,301.58,269,304,268Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M337.32,290.7l-1.49-.7c-.29-.89,1.48-1.79,0-2.67l.83.42c.56,2.43,1.59.74,2.48.28l1.73,0-.1,1.51L339,291Z" transform="translate(-191 -159)" style="fill:#202020"/><path d="M315,280.93a2.64,2.64,0,0,0,0-.93c.12-1.24-.3-2.89,1.84-2.71a1.09,1.09,0,0,1,1,1.43C317.31,279.9,317.69,282.5,315,280.93Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M311,266.23l3-1.22c1.59,1.81.35,3.19-1.11,3.67C311,269.29,311.12,267.46,311,266.23Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M326.32,296.89c1.34,1.85.13,3.92.52,5.86l-1.79.36q0-3.06,0-6.1Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M335.59,270.85c1.1.64,2.17,1.3,2.24,2.77-1.63-.06-3.08,2.06-4.84.39h0c.92-.62,1-1.26,0-1.93l-.09-.12A3.27,3.27,0,0,1,335.59,270.85Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M327.94,272.1c-.32.06-.65.11-1,.19-1,.24-1.46,2.11-2.88,1a1.32,1.32,0,0,1-.29-1.24c.7-1.19,1.92-1.15,3.07-.94a4.21,4.21,0,0,1,1.25.73Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M328.12,271.85a4.69,4.69,0,0,1,4.82.11l.09.12c0,.64,0,1.29,0,1.93h0l-5.05-1.91Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M335.81,287.33c1.5.88-.27,1.78,0,2.67a8.69,8.69,0,0,0-.88.07c-.86-.92-1.92-1.8-1.32-3.23A11.23,11.23,0,0,1,335.81,287.33Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M339.12,288c-.89.46-1.92,2.15-2.48-.28.29-1.51.88-2.71,2.69-2.72Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M341.65,257.14c.35,1.48-.61,2.21-1.65,2.88C337.68,257.42,341.26,258.19,341.65,257.14Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M315.09,302.83l-3.09-.08C313.09,300.31,314.12,300.56,315.09,302.83Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M305,294l2.4,3.94c-3-.41-2.19-2.48-2.4-3.94Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M326.32,296.89,325,297c-1.23-.82-1-2.06-.94-3.26A3.92,3.92,0,0,1,326.32,296.89Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M313,284.08c-1-1-1.61-1.92.05-2.84A2.39,2.39,0,0,1,313,284.08Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M314,258a1.72,1.72,0,0,1-2.21-1.05,5.1,5.1,0,0,1,.39-.9,2,2,0,0,1,1.95,1.37.64.64,0,0,1-.2.68Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M307.61,283.27c-.27.11-.61.36-.8.27s-.23-.5-.33-.77c.27-.1.6-.36.8-.27S307.51,283,307.61,283.27Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M318.88,287.55l-.45.16-.38-.29c.09-.78-.12-1.83,1-1.85.3,0,.61,1,.92,1.48Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M310,302.79l-2,.21c.13-.71.11-1.65,1.12-1.53C309.47,301.51,309.72,302.33,310,302.79Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M329.39,268.2a4.66,4.66,0,0,1-.23-.93c0-.07.4-.15.62-.22,0,.15.15.34.1.46A3.53,3.53,0,0,1,329.39,268.2Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M323,286.8l-1,.12c.15-.41.29-.82.43-1.23Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M320.12,246.94c.23.34.47.67.67,1a3.6,3.6,0,0,1-.49.36l-.42-1.19Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M310.27,299.38l-.12.35a1.23,1.23,0,0,1-.39-.16s.07-.22.11-.33Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M316.61,269.28l-.35-.12a1.14,1.14,0,0,1,.16-.39s.22.07.33.11Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M314,258.07a.64.64,0,0,0,.2-.68,2,2,0,0,1,.11.51C314.26,258,314.06,258,314,258.07Z" transform="translate(-191 -159)" style="fill:#7f8488"/><path d="M346.77,258.11h-1.51c.36-2.07-1.25-4.89,2.06-5.84,1.22-.35,2.63-.87,3.77.16,1,.85.83,2.15.78,3.26-.11,2.18-1.91,1.21-3,1.4C348,257.24,347.21,257.26,346.77,258.11Z" transform="translate(-191 -159)" style="fill:#c28187"/><path d="M337.32,290.7,339,291c.7,2.93,1.41,5.87,2.11,8.8L341,303l-3,0C339,298.82,337,294.82,337.32,290.7Z" transform="translate(-191 -159)" style="fill:#8396a2"/><path d="M340.75,289.5l.1-1.51c.46-2.93,2.37-5.09,3.94-7.43,2.27,3.4,0,6.38-1.12,9.3C342.94,291.69,341.6,290.82,340.75,289.5Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M353.05,270.85c1.64,2.59.66,5.41.75,8.14A9.37,9.37,0,0,1,353.05,270.85Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M344.87,277l-.89-.9c.13-1,.35-1.93,1.6-1.91a1.19,1.19,0,0,1,1.2,1.21C346.8,276.65,345.86,276.88,344.87,277Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M351.53,298.13l-.47-2.14C352.73,296.37,353.38,297,351.53,298.13Z" transform="translate(-191 -159)" style="fill:#f3f4f4"/><path d="M337,310c.4-1.59.79-3.19,1.19-4.79.67,0,1.34,0,2,0,2.71-.27,4.92.38,5.76,3.29.42,1.48-.13,2.92-1.66,3.07C341.76,311.75,338.75,313.56,337,310Z" transform="translate(-191 -159)" style="fill:#dbdbdb"/><path d="M345.93,316.85c-1.76-.05-3.58-.44-5.26-.1-3.4.69-4-.84-3.38-3.63a37.79,37.79,0,0,0,5.33-.18C346.15,312.33,346.31,314.3,345.93,316.85Z" transform="translate(-191 -159)" style="fill:#dbdbdb"/><path d="M343.67,322.12c-1.93-.35-3.65,1.5-5.64.55,0-.88,0-1.76,0-2.65,2.16-1.66,4.61-1.11,7-.91C345,320.29,345,321.5,343.67,322.12Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M300,253.35c-1-2.28-2.29-4-5-2.1V248c3.74-.82,6.51.3,8,4Z" transform="translate(-191 -159)" style="fill:#302b2c"/><path d="M310.93,257.11c-.33,1.28-.66,2.55-1,3.83l-1,.84-4.81.09c-.18-1.87-2.25-3.83-.53-5.54,2.11-2.1,4.27.78,6.5.56A6,6,0,0,0,310.93,257.11Z" transform="translate(-191 -159)" style="fill:#e9ebec"/><path d="M308.94,261.78l1-.84c1.58,1.32.92,2-.69,2.41Z" transform="translate(-191 -159)" style="fill:#302b2c"/><path d="M308.67,263.93c-.11.7-.45.44-.79.19A2,2,0,0,1,308.67,263.93Z" transform="translate(-191 -159)" style="fill:#302b2c"/><path d="M338,320c0,.89,0,1.77,0,2.65-4.36-.29-8.84,1.55-13.08-.75C329.39,322,333.64,320.68,338,320Z" transform="translate(-191 -159)" style="fill:#84abca"/><path d="M315.82,290.21c-1.28.71-1.59-.13-1.81-1.12Z" transform="translate(-191 -159)" style="fill:#fbfbfb"/><path d="M333,274c0-.64,0-1.29,0-1.93C334,272.75,333.91,273.39,333,274Z" transform="translate(-191 -159)" style="fill:#fbfbfb"/></svg>';  
  string public name;
  string public symbol;

  mapping(uint => string) public tokenURI;

  constructor() ERC1155("") {
    name = "FWOJAK";
    symbol = "WJK";
  }

  function mint(address _to, uint _id, uint _amount) external onlyOwner {
    _mint(_to, _id, _amount, "");
  }

  function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external onlyOwner {
    _mintBatch(_to, _ids, _amounts, "");
  }

  function burn(uint _id, uint _amount) external {
    _burn(msg.sender, _id, _amount);
  }

  function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
    _burnBatch(msg.sender, _ids, _amounts);
  }

  function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external onlyOwner {
    _burnBatch(_from, _burnIds, _burnAmounts);
    _mintBatch(_from, _mintIds, _mintAmounts, "");
  }

  function uri(uint256 typeId) public view override returns (string memory) {
        require(typeId>0 && typeId<4, "type err");
        bytes memory svg;
        string memory num;
        if (typeId == 1) {
            svg = bytes(svg1);
            num = '1 FatWojak","attributes":[{"trait_type": "Wojak", "value": "FAT';
        } 
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
            '{"name": "D', num, '"}],"image": "data:image/svg+xml;base64,',
            Base64.encode(svg),'"}'))));
    }
}