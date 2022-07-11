/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


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

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


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

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


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
        require(account != address(0), "ERC1155: balance query for the zero address");
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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

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

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
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


// File: DDomDiBion.sol

pragma solidity ^0.8.15;

// define a smart contract that generates and manages fungible and non-fungible tokens (ERC1155)
contract DDomDiBion is ERC1155, Ownable, Pausable
{
    // token ID zero and index zero are reserved
    uint256 private constant _zeroTokenIndex = 0;
    // the default price for a token in Wei
    uint256 private _defaultPrice = 100000000000000; // 0.0001 ETH or MATIC (0.0001 * 10 ** 18)

    // various info about a token
    struct TokenInfo
    {
        // the token's total supply
        uint256 totalSupply;

        // the index pointing to the token's first owner in the owner list
        uint256 tokenIndex;
    } // TokenInfo

    // various info about a token's owner, a fungible token can have multiple owners
    struct TokenOwnerInfo
    {
        // the owner's address
        address tokenOwner;

        // the token's balance for this owner
        uint256 tokenBalance;
        
        // number of tokens put for sale by the owner
        uint256 tokenForSale;
        // the token's price in Wei as set by the owner, initially it will be set to the default price
        uint256 tokenPrice;

        // the index pointing to the token's next owner in the owner list
        uint256 tokenIndex;
    } // TokenOwnerInfo

    // map token IDs to their info
    mapping(uint256 => TokenInfo) public tokenInfoMap;
    // list all minted token IDs (we need this list because the above map is not iterable)
    uint256[] public tokenIDList;

    // list all token owners
    TokenOwnerInfo[] public tokenOwnerList;

    // map owner addresses to the number of token IDs held
    mapping(address => uint256) private _tokenBalanceMap;


    // create the contract, define the base URI
    constructor()
        ERC1155("ipfs://bafybeigcdk56hvgawqekab2joaohowwrejd3mo3kypsik7pfixdlbqmnke/DDomDiBion_")
    {
        // created a fake token slot that will store the original 
        // owner of the contract and the sum of all token supplies
        TokenInfo storage zeroTokenInfo = tokenInfoMap[_zeroTokenIndex];    // token ID zero is reserved
        zeroTokenInfo.tokenIndex = _storeTokenOwner(msg.sender);            // index zero is reserved (this is the first entry in the owner list, so the index is 0)
        zeroTokenInfo.totalSupply = 0;                                      // initialize the sum of all token supplies
    } // constructor

    // store a new token's owner in the owner list
    function _storeTokenOwner(address account) internal returns (uint256)
    {
        // create a new owner info
        TokenOwnerInfo memory tokenOwnerInfo = TokenOwnerInfo({
            tokenOwner: account,        // store the token's owner
            tokenBalance: 0,            // initialize the token's balance
            tokenForSale: 0,            // initialize the number of tokens for sale
            tokenPrice: _defaultPrice,  // initialize the token's price in Wei, set it to the default price
            tokenIndex: _zeroTokenIndex // initialize the next owner's index
        });

        // store the token's new owner
        tokenOwnerList.push(tokenOwnerInfo);

        // return the index where the new owner was stored
        return (tokenOwnerList.length - 1);
    } // _storeTokenOwner

    // retrieve the index for the input token's owner in the owner list,
    //?? this should be done using "ERC1155._balances" map
    function _findTokenOwner(address account, uint256 tokenID) internal view returns (uint256)
    {
        // retrieve the index for the input token's first owner
        uint256 tokenIndex = tokenInfoMap[tokenID].tokenIndex;
        while (true)
        {
            // check if the curent owner matches the input account
            TokenOwnerInfo storage tokenOwnerInfo = tokenOwnerList[tokenIndex];
            if (tokenOwnerInfo.tokenOwner == account)
                // return the index for the input token owner
                return tokenIndex;
            
            // check if we reached the last owner for the input token
            if (tokenOwnerInfo.tokenIndex == _zeroTokenIndex)
                // the input account doesn't own this token
                return _zeroTokenIndex;

            // go to the next token owner
            tokenIndex = tokenOwnerInfo.tokenIndex;
        }

        // the input account doesn't own this token
        return _zeroTokenIndex;
    } // _findTokenOwner

    // update token's balance for the input account,
    //?? this should be done using "ERC1155._balances" map
    function _updateTokenBalance(address account, uint256 tokenID, uint256 amount) internal
    {
        // retrieve the index for the input token's owner in the owner list
        uint256 tokenIndex = _findTokenOwner(account, tokenID);
        require(tokenIndex != _zeroTokenIndex, "ERC1155: the input account doesn't own the token");

        // retrieve and store the balance for the input account
        TokenOwnerInfo storage tokenOwnerInfo = tokenOwnerList[tokenIndex];
        tokenOwnerInfo.tokenBalance = balanceOf(account, tokenID);

        // update the number of tokens for sale
        if (amount == 0)
        {
            if (tokenOwnerInfo.tokenForSale > tokenOwnerInfo.tokenBalance)
                tokenOwnerInfo.tokenForSale = tokenOwnerInfo.tokenBalance;
        }
        else if(amount >= tokenOwnerInfo.tokenForSale)
            tokenOwnerInfo.tokenForSale = 0;
        else
            tokenOwnerInfo.tokenForSale -= amount;
    } // _updateTokenBalance

    // create an association between the input account and token in the owner list
    function _newTokenOwner(address account, uint256 tokenID) internal
    {
        // increase the number of token IDs held by the input account
        _tokenBalanceMap[account] += 1;

        // retrieve the index of the first owner for the input token
        uint256 tokenIndex = tokenInfoMap[tokenID].tokenIndex;
        while (true)
        {
            // check if the curent owner slot is free
            TokenOwnerInfo storage tokenOwnerInfo = tokenOwnerList[tokenIndex];
            if (tokenOwnerInfo.tokenOwner == address(0))
            {
                // store the new owner in the free slot
                tokenOwnerInfo.tokenOwner = account;
                tokenOwnerInfo.tokenPrice = _defaultPrice;
                break;
            }
            
            // check if we reached the last owner for the input token
            if (tokenOwnerInfo.tokenIndex == _zeroTokenIndex)
            {
                // store the new owner in the owner list
                tokenOwnerInfo.tokenIndex = _storeTokenOwner(account);
                break;
            }

            // go to the next owner for the input token
            tokenIndex = tokenOwnerInfo.tokenIndex;
        }
    } // _newTokenOwner

    // remove the association between the input account and token from the owner list
    function _deleteTokenOwner(address account, uint256 tokenID) internal
    {
        // decrease the number of token IDs held by the input account
        _tokenBalanceMap[account] -= 1;

        // retrieve the index for the input token's owner in the owner list
        uint256 tokenIndex = _findTokenOwner(account, tokenID);
        require(tokenIndex != _zeroTokenIndex, "ERC1155: the input account doesn't own the token");

        // free the slot for the input token's owner
        TokenOwnerInfo storage tokenOwnerInfo = tokenOwnerList[tokenIndex];
        tokenOwnerInfo.tokenOwner = address(0);
        tokenOwnerInfo.tokenBalance = 0;
        tokenOwnerInfo.tokenForSale = 0;
        tokenOwnerInfo.tokenPrice = 0;
    } // _deleteTokenOwner

    // update token's info for the input account during a minting operation
    function _mintUpdateTokenInfo(address account, bool accountNewToken, uint256 tokenID, uint256 amount) internal
    {
        // check the supply for the input token
        TokenInfo storage tokenInfo = tokenInfoMap[tokenID];
        if (tokenInfo.totalSupply == 0)
        {
            // check if this is a newly minted token
            if (tokenInfo.tokenIndex == 0)
            {
                // store the new token ID
                tokenIDList.push(tokenID);

                // this is the first and only owner for the input token right now, store it in the owner list
                tokenInfo.tokenIndex = _storeTokenOwner(account);
            }
            else // this token was minted before, but then is was completely burnt
            {
                // the token's first index should point to a free slot
                TokenOwnerInfo storage tokenOwnerInfo = tokenOwnerList[tokenInfo.tokenIndex];
                require(tokenOwnerInfo.tokenOwner == address(0), "ERC1155: the input token should point to a free slot");

                // fill the slot for the input token's owner
                tokenOwnerInfo.tokenOwner = account;
                tokenOwnerInfo.tokenPrice = _defaultPrice;
            }

            // increase the number of token IDs held by the input account
            _tokenBalanceMap[account] += 1;
        }
        // check if this is a newly minted token for the input account
        else if (accountNewToken)
            // create an association between the input input account and the input token
            _newTokenOwner(account, tokenID);

        // update the total supply for the input token
        tokenInfo.totalSupply += amount;
        // update the sum of all token supplies
        tokenInfoMap[_zeroTokenIndex].totalSupply += amount;

        // update token's balance for the input account
        _updateTokenBalance(account, tokenID, 0);
    } // _mintUpdateTokenInfo

    // update token's info for the input account during a burning operation
    function _burnUpdateTokenInfo(address account, uint256 tokenID, uint256 amount) internal
    {
        // update the total supply for the input token
        TokenInfo storage tokenInfo = tokenInfoMap[tokenID];
        tokenInfo.totalSupply -= amount;
        // update the sum of all token supplies
        tokenInfoMap[_zeroTokenIndex].totalSupply -= amount;

        // check if this is a completely burnt token
        if (tokenInfo.totalSupply == 0)
            // remove the association between the input account and the input token,
            // do not delete the token completely (keep all its slots) because it might be minted again in the future
            _deleteTokenOwner(account, tokenID);
        // check if this is a completely burnt token for the input account
        else if (balanceOf(account, tokenID) == 0)
            // remove the association between the input account and the input token
            _deleteTokenOwner(account, tokenID);
        else
            // update the input token's balance for the input account
            _updateTokenBalance(account, tokenID, 0);
    } // _burnUpdateTokenInfo

    // update token's info for the input accounts during a transfer operation
    function _transferUpdateTokenInfo(address accountFrom, address accountTo, bool accountToNewToken, uint256 tokenID, uint256 amount) internal
    {
        // check if this is an old token for the 'accountFrom' account
        if (balanceOf(accountFrom, tokenID) == 0)
            // remove the association between the 'accountFrom' account and the input token
            _deleteTokenOwner(accountFrom, tokenID);
        else
            // update the input token's balance for the 'accountFrom' account
            _updateTokenBalance(accountFrom, tokenID, amount);

        // check if this is an new token for the 'accountTo' account
        if (accountToNewToken)
            // create an association between the 'accountTo' input account and the input token
            _newTokenOwner(accountTo, tokenID);

        // update the input token's balance for the 'accountTo' account
        _updateTokenBalance(accountTo, tokenID, 0);
    } // _transferUpdateTokenInfo

    // create new non fungible tokens ('amount'=1) or fungible tokens ('amount'>1) identified
    // by the input 'tokenID' and assign them to the input 'account', only the owner can do this,
    // the name of this function cannot be changed since is is a standard ERC1155 function name
    function mint(address account, uint256 tokenID, uint256 amount, bytes memory data) public onlyOwner
    {
        // check if the input data is valid
        require(tokenID > _zeroTokenIndex, "ERC1155: the minted token IDs must be greater than 0");
        require(amount > 0, "ERC1155: the amount of tokens minted must be greater than 0");

        // check if this is a new token for the input account
        bool accountNewToken = (balanceOf(account, tokenID) == 0);

        // mint the token
        _mint(account, tokenID, amount, data);

        // update input token's info for the input account
        _mintUpdateTokenInfo(account, accountNewToken, tokenID, amount);
    } // mint

    // create new batches of non fungible tokens ('amount'=1) or fungible tokens ('amount'>1) identified
    // by the input 'tokenIDs' and assign them to the input 'account', only the owner can do this,
    // the name of this function cannot be changed since is is a standard ERC1155 function name
    function mintBatch(address account, uint256[] memory tokenIDs, uint256[] memory amounts, bytes memory data) public onlyOwner
    {
        // check if the input data is valid
        for (uint i = 0; i < tokenIDs.length; ++i)
        {
            require(tokenIDs[i] > _zeroTokenIndex, "ERC1155: the minted token IDs must be greater than 0");
            require(amounts[i] > 0, "ERC1155: the amount of tokens minted must be greater than 0");
        }

        // check if these are new tokens for the input account
        bool[] memory accountNewTokens = new bool[](tokenIDs.length);
        for (uint i = 0; i < tokenIDs.length; ++i)
            accountNewTokens[i] = (balanceOf(account, tokenIDs[i]) == 0);

        // mint the batch of tokens
        _mintBatch(account, tokenIDs, amounts, data);

        // loop over the batch of tokens
        for (uint i = 0; i < tokenIDs.length; ++i)
             // update the current token's info for the input account
            _mintUpdateTokenInfo(account, accountNewTokens[i], tokenIDs[i], amounts[i]);
    } // mintBatch

    // burn a token value irreversibly,
    // the caller must own these tokens or be an approved operator,
    // the name of this function cannot be changed since is is a standard ERC1155 function name
    function burn(address account, uint256 tokenID, uint256 amount) public virtual
    {
        // check if the input data is valid
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "ERC1155: caller is not owner nor approved");
        require(tokenID > _zeroTokenIndex, "ERC1155: the burnt token IDs must be greater than 0");
        require(amount > 0, "ERC1155: the amount of tokens burnt must be greater than 0");

        // burn the token
        _burn(account, tokenID, amount);

        // update input token's info for the input account
        _burnUpdateTokenInfo(account, tokenID, amount);
    } //burn

    // burn a batch of token values irreversibly,
    // the caller must own these tokens or be an approved operator,
    // the name of this function cannot be changed since is is a standard ERC1155 function name
    function burnBatch(address account, uint256[] memory tokenIDs, uint256[] memory amounts) public virtual
    {
        // check if the input data is valid
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "ERC1155: caller is not owner nor approved");
        for (uint i = 0; i < tokenIDs.length; ++i)
        {
            require(tokenIDs[i] > _zeroTokenIndex, "ERC1155: the burnt token IDs must be greater than 0");
            require(amounts[i] > 0, "ERC1155: the amount of tokens burnt must be greater than 0");
        }
        
         // burn the batch of tokens
        _burnBatch(account, tokenIDs, amounts);

        // loop over the batch of tokens
        for (uint i = 0; i < tokenIDs.length; ++i)
             // update the current token's info for the input account
            _burnUpdateTokenInfo(account, tokenIDs[i], amounts[i]);
    } //burnBatch

    // transfer some tokens, assumes that the payment was already provided by other means,
    // the caller must own these tokens or be an approved operator,
    // the name of this function cannot be changed since is is a standard ERC1155 function name
    function safeTransferFrom(address accountFrom, address accountTo, uint256 tokenID, uint256 amount, bytes memory data) public virtual override
    {
        // check if the input data is valid
        require(accountFrom == msg.sender || isApprovedForAll(accountFrom, msg.sender), "ERC1155: caller is not owner nor approved");
        require(accountFrom != accountTo, "ERC1155: buyer cannot be the same as seller");
        require(tokenID > _zeroTokenIndex, "ERC1155: the transfered token IDs must be greater than 0");
        require(amount > 0, "ERC1155: the amount of tokens transfered must be greater than 0");

        // check if this is a new token for 'accountTo' account
        bool accountToNewToken = (balanceOf(accountTo, tokenID) == 0);

        // perform the transfer
        _safeTransferFrom(accountFrom, accountTo, tokenID, amount, data);

        //  update input token's info for the input accounts
        _transferUpdateTokenInfo(accountFrom, accountTo, accountToNewToken, tokenID, 0);
    } // safeTransferFrom

    // transfer a batch of tokens, assumes that the payment was already provided by other means,
    // the caller must own these tokens or be an approved operator,
    // the name of this function cannot be changed since is is a standard ERC1155 function name
    function safeBatchTransferFrom(address accountFrom, address accountTo, uint256[] memory tokenIDs, uint256[] memory amounts, bytes memory data) public virtual override
    {
        // check if the input data is valid
        require(accountFrom == msg.sender || isApprovedForAll(accountFrom, msg.sender), "ERC1155: transfer caller is not owner nor approved");
        require(accountFrom != accountTo, "ERC1155: buyer cannot be the same as seller");
        for (uint i = 0; i < tokenIDs.length; ++i)
        {
            require(tokenIDs[i] > _zeroTokenIndex, "ERC1155: the transfered token IDs must be greater than 0");
            require(amounts[i] > 0, "ERC1155: the amount of tokens transfered must be greater than 0");
        }

        // check if these are new tokens for 'accountTo' account
        bool[] memory accountToNewTokens = new bool[](tokenIDs.length);
        for (uint i = 0; i < tokenIDs.length; ++i)
            accountToNewTokens[i] = (balanceOf(accountTo, tokenIDs[i]) == 0);

        // perform the transfer
        _safeBatchTransferFrom(accountFrom, accountTo, tokenIDs, amounts, data);

        // loop over the batch of tokens
        for (uint i = 0; i < tokenIDs.length; ++i)
            // update the current token's info for the input accounts
            _transferUpdateTokenInfo(accountFrom, accountTo, accountToNewTokens[i],  tokenIDs[i], 0);
    } // safeBatchTransferFrom

    // buy some tokens by providing payment,
    // the caller can be anybody and doesn't require owner's approval to buy these tokens
    function safeBuyFrom(address payable accountFrom, uint256 tokenID, uint256 amount, bytes memory data) payable public
    {
        // retrieve the caller, which is the buyer in this case
        address accountTo = msg.sender;
        require(accountFrom != accountTo, "ERC1155: buyer cannot be the same as seller");
        require(tokenID > _zeroTokenIndex, "ERC1155: the bought token IDs must be greater than 0");
        require(amount > 0, "ERC1155: the amount of tokens bought must be greater than 0");
        //require(amount <= tokenOwnerList[x].tokenForSale, "ERC1155: not enough tokens for sale"); //??

        // check if the required payment was provided
        uint256 price = getPrice(accountFrom, tokenID);
        require(msg.value == price*amount);

        // check if this is a new token for 'accountTo' account
        bool accountToNewToken = (balanceOf(accountTo, tokenID) == 0);

        // transfer the tokens from the seller to the buyer
        _safeTransferFrom(accountFrom, accountTo, tokenID, amount, data);
        // pay the seller for the tranferred tokens
        accountFrom.transfer(msg.value);

        // update input token's info for the input accounts
        _transferUpdateTokenInfo(accountFrom, accountTo, accountToNewToken, tokenID, amount);
    } // safeBuyFrom
    
    // buy a batch of tokens by providing payment,
    // the caller can be anybody and doesn't require owner's approval to buy these tokens
    function safeBatchBuyFrom(address payable accountFrom, uint256[] memory tokenIDs, uint256[] memory amounts, bytes memory data) payable public
    {
        // retrieve the caller, which is the buyer in this case
        address accountTo = msg.sender;
        require(accountFrom != accountTo, "ERC1155: buyer cannot be the same as seller");
        for (uint i = 0; i < tokenIDs.length; ++i)
        {
            require(tokenIDs[i] > _zeroTokenIndex, "ERC1155: the bought token IDs must be greater than 0");
            require(amounts[i] > 0, "ERC1155: the amount of tokens bought must be greater than 0");
            //require(amounts[i] <= tokenOwnerList[x].tokenForSale, "ERC1155: not enough tokens for sale"); //??
        }
        
        // check if the required payment was provided
        uint256 paymentValue = 0;
        for (uint i = 0; i < tokenIDs.length; ++i)
        {
            uint256 price = getPrice(accountFrom, tokenIDs[i]);
            paymentValue += price*amounts[i];
        }
        
        // check if the required payment was provided
        require(msg.value == paymentValue);

        // check if these are new tokens for 'accountTo' account
        bool[] memory accountToNewTokens = new bool[](tokenIDs.length);
        for (uint i = 0; i < tokenIDs.length; ++i)
            accountToNewTokens[i] = (balanceOf(accountTo, tokenIDs[i]) == 0);

        // transfer the tokens from the seller to the buyer
        safeBatchTransferFrom(accountFrom, accountTo, tokenIDs, amounts, data);
        // pay the seller for the tranferred tokens
        accountFrom.transfer(msg.value);

        // loop over the batch of tokens
        for (uint i = 0; i < tokenIDs.length; ++i)
            //update the current token's info for the input accounts
            _transferUpdateTokenInfo(accountFrom, accountTo, accountToNewTokens[i],  tokenIDs[i], amounts[i]);
    } // safeBatchBuyFrom

     // check whether a token exists or not,
     // the name of this function cannot be changed since is is a standard ERC1155 function name
    function exists(uint256 tokenID) public view returns (bool)
    {
        // ignore zero token ID
        if (tokenID == _zeroTokenIndex)
            return false;
        
        // a token exists if its total supply is greater than 0
        return (tokenInfoMap[tokenID].totalSupply > 0);
    } // exists

    // return the total amount of tokens for a given ID,
    // the name of this function cannot be changed since is is a standard ERC1155 function name
    function totalSupply(uint256 tokenID) public view returns (uint256)
    {
        // ignore zero token ID
        if (tokenID == _zeroTokenIndex)
            return 0;

        // return the total supply for the input token
        return tokenInfoMap[tokenID].totalSupply;
    } // totalSupply

    // return the sum of all token supplies
    function totalSupply() public view returns (uint256)
    {
        return tokenInfoMap[_zeroTokenIndex].totalSupply;
    } // totalSupply

    // return the total number of token IDs minted
    function getNumberTokenIDs() public view returns (uint256)
    {
        // note that this number includes the IDs of completely burnt tokens
        return tokenIDList.length;
    } // getNumberTokenIDs
    
    // return the total number of token owners,
    // if an account owns multiple tokens it will be counted multiple times
    function getNumberTokenOwners() public view returns (uint256)
    {
        // note that this number includes accounts that no longer own some of the tokens,
        // also includes the owners of the contract in the first slot
        return tokenOwnerList.length;
    } // getNumberTokenOwners

    // return the number of token IDs held by the input 'account',
    // the name of this function cannot be changed since is expected by MetaMask
    function balanceOf(address account) public view returns (uint256)
    {
        return _tokenBalanceMap[account];
    } // balanceOf

    // change the default price of a new token in Wei, only the owner can do this
    function setDefaultPrice(uint256 price) public onlyOwner
    {
        _defaultPrice = price;
    } // setDefaultPrice
    
    // return the default price of a new token in Wei
    function getDefaultPrice() public view returns (uint256)
    {
        return _defaultPrice;
    } // getDefaultPrice

    // change the price of tokens for the input account (in Wei),
    // the caller must own these tokens or be an approved operator
    function setPrice(address account, uint256 tokenID, uint256 tokenForSale, uint256 tokenPrice) public
    {
        // check if the input data is valid
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "ERC1155: caller is not owner nor approved");
        require(tokenPrice > 0, "ERC1155: the price of a token must be greater than 0");

        // retrieve the index for the input token's owner in the owner list
        uint256 tokenIndex = _findTokenOwner(account, tokenID);
        require(tokenIndex != _zeroTokenIndex, "ERC1155: the input account doesn't own the token");

        // retrieve the token from the owner list
        TokenOwnerInfo storage tokenOwnerInfo = tokenOwnerList[tokenIndex];
        require(tokenForSale <= tokenOwnerInfo.tokenBalance, "ERC1155: not enough tokens are available for sale");

        // set the number of tokens for sale and their price
        tokenOwnerList[tokenIndex].tokenForSale = tokenForSale;
        tokenOwnerList[tokenIndex].tokenPrice = tokenPrice;
    } // setPrice
    
    // return the price of a token for the input account (in Wei)
    function getPrice(address account, uint256 tokenID) public view returns (uint256)
    {
        // retrieve the index for the input token's owner in the owner list
        uint256 tokenIndex = _findTokenOwner(account, tokenID);
        if (tokenIndex == _zeroTokenIndex)
            // the input account doesn't own this token
            return 0;
        
        // return the token's price from the owner list
        return tokenOwnerList[tokenIndex].tokenPrice;
    } // getPrice

    // change the base URI, only the owner can do this
    function setURI(string memory newuri) public onlyOwner
    {
        _setURI(newuri);
    } // setURI

    // return the URI associated with the contract,
    // the name of this function cannot be changed since is expected by OpenSea
    function contractURI() public view returns (string memory)
    {
        return string(abi.encodePacked(super.uri(0), "Contract.json"));
    } // contractURI

    // return the URI associated with the input token ID,
    // the name of this function cannot be changed since is is a standard ERC1155 function name
    function uri(uint256 tokenID) public override view returns (string memory)
    {
        // add leading zeros
        bytes memory tokenIDStr = bytes(Strings.toString(tokenID));
        while (tokenIDStr.length < 4)
        { tokenIDStr = bytes.concat(bytes("0"), tokenIDStr); }

        // compose and return the full URI
        return string(abi.encodePacked(super.uri(tokenID), "Token", string(tokenIDStr), ".json"));
    } // uri

    // trigger a stopped state for the contract, only the owner can do this,
    // the name of this function cannot be changed since is is a standard ERC1155 function name
    function pause() public onlyOwner
    {
        _pause();
    } // pause

    // return to the normal state of the contract, only the owner can do this,
    // the name of this function cannot be changed since is is a standard ERC1155 function name
    function unpause() public onlyOwner
    {
        _unpause();
    } // unpause

    // hook that is called before any transfer of tokens,
    // this includes minting and burning
    function _beforeTokenTransfer(address operator, address accountFrom, address accountTo, uint256[] memory tokenIDs, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155)
    {
        // call the base class
        super._beforeTokenTransfer(operator, accountFrom, accountTo, tokenIDs, amounts, data);
    } // _beforeTokenTransfer
} // DDomDiBion