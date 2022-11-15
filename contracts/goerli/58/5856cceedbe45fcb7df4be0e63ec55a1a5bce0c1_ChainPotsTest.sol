/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

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

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155URIStorage.sol)

pragma solidity ^0.8.0;



/**
 * @dev ERC1155 token with storage based token URI management.
 * Inspired by the ERC721URIStorage extension
 *
 * _Available since v4.6._
 */
abstract contract ERC1155URIStorage is ERC1155 {
    using Strings for uint256;

    // Optional base URI
    string private _baseURI = "";

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the concatenation of the `_baseURI`
     * and the token-specific uri if the latter is set
     *
     * This enables the following behaviors:
     *
     * - if `_tokenURIs[tokenId]` is set, then the result is the concatenation
     *   of `_baseURI` and `_tokenURIs[tokenId]` (keep in mind that `_baseURI`
     *   is empty per default);
     *
     * - if `_tokenURIs[tokenId]` is NOT set then we fallback to `super.uri()`
     *   which in most cases will contain `ERC1155._uri`;
     *
     * - if `_tokenURIs[tokenId]` is NOT set, and if the parents do not have a
     *   uri value set, then the result is empty.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(tokenURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenURI)) : super.uri(tokenId);
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    /**
     * @dev Sets `baseURI` as the `_baseURI` for all tokens
     */
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseURI = baseURI;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }
}

// File: contracts/CPTest.sol

pragma solidity ^0.8.17;







contract ChainPotsTest is ERC1155, ERC1155Burnable, ERC1155Supply, ERC1155URIStorage, Ownable {
    constructor(string memory baseURI, uint256 initialTokenCount) ERC1155("") {
        _setBaseURI(baseURI);
        for (uint256 i = 0; i < initialTokenCount; i++) {
            _setURI(i, Strings.toString(i));
        }
        Admin = msg.sender;
    }

    function name() external pure returns (string memory) {
        return "chainpots";
    }

    function symbol() external pure returns (string memory) {
        return "CP";
    }

    address public Admin;
    address private houseAddressOne =
        0xC9Ead2d74ebD92A56f1a14267b5b87eD66885Cee;
    address private houseAddressTwo =
        0xC9Ead2d74ebD92A56f1a14267b5b87eD66885Cee;
    uint256 houseCutOne = 2;
    uint256 houseCutTwo = 2;
    uint256 winnerCut = 96;

    // daily pot

    uint256 public lastDailyPot;
    uint256 public drawTime = 5 minutes;
    address payable[] public playersDailyPot;
    uint256 public dailyPotEntryPrice = 0.001 ether;

    event EntryDailyPot(address indexed _from, uint256 _value);
    event WinnerDailyPot(
        address indexed _from,
        uint256 _value,
        uint256 indexed _timestap
    );
    event WinnerDailyPotEmpty(uint256 indexed _timestap);

    // lotteries

    address payable[] public playersSilverLottery;
    uint256 public silverLotteryEntryPrice = 0.0001 ether;
    uint256 public silverLotteryPotMaxAmount = 0.001 ether;
    uint256 public silverLotteryMaxEntries = 10;
    bool public silverLotteryMintIsLive = true;

    address payable[] public playersGoldLottery;
    uint256 public goldLotteryEntryPrice = 0.0002 ether;
    uint256 public goldLotteryPotMaxAmount = 0.002 ether;
    uint256 public goldLotteryMaxEntries = 10;
    bool public goldLotteryMintIsLive = true;

    address payable[] public playersDiamondLottery;
    uint256 public diamondLotteryEntryPrice = 0.0003 ether;
    uint256 public diamondLotteryPotMaxAmount = 0.003 ether;
    uint256 public diamondLotteryMaxEntries = 10;
    bool public diamondLotteryMintIsLive = true;

    event EntrySilverLottery(address indexed _from, uint256 _value);
    event WinnerSilverLottery(address indexed _from, uint256 _value);
    event FinalPlayersSilverLottery(address payable[] playersSilverLottery);

    event EntryGoldLottery(address indexed _from, uint256 _value);
    event WinnerGoldLottery(address indexed _from, uint256 _value);
    event FinalPlayersGoldLottery(address payable[] playersGoldLottery);

    event EntryDiamondLottery(address indexed _from, uint256 _value);
    event WinnerDiamondLottery(address indexed _from, uint256 _value);
    event FinalPlayersDiamondLottery(address payable[] playersDiamondLottery);

    // battles

    address payable[] public playersSilverBattle;
    uint256 public silverBattleEntryPrice = 0.0001 ether;
    uint256 public silverBattlePotMaxAmount = 0.0002 ether;
    uint256 public silverBattleMaxEntries = 2;

    address payable[] public playersGoldBattle;
    uint256 public goldBattleEntryPrice = 0.0002 ether;
    uint256 public goldBattlePotMaxAmount = 0.0004 ether;
    uint256 public goldBattleMaxEntries = 2;

    address payable[] public playersDiamondBattle;
    uint256 public diamondBattleEntryPrice = 0.0003 ether;
    uint256 public diamondBattlePotMaxAmount = 0.0006 ether;
    uint256 public diamondBattleMaxEntries = 2;

    event EntrySilverBattle(address indexed _from, uint256 _value);
    event WinnerSilverBattle(address indexed _from, uint256 _value);

    event EntryGoldBattle(address indexed _from, uint256 _value);
    event WinnerGoldBattle(address indexed _from, uint256 _value);

    event EntryDiamondBattle(address indexed _from, uint256 _value);
    event WinnerDiamondBattle(address indexed _from, uint256 _value);

    // mega pots

    address payable[] public playersSilverMegaPot;
    uint256 public silverMetaPotMaxAmount = 0.0001 ether;
    uint256 public silverMegaPotMaxEntries = 10;

    event EntrySilverMegaPot(address indexed _from, uint256 _value);
    event WinnerSilverMegaPot(address indexed _from, uint256 _value);

    modifier restricted() {
        require(msg.sender == Admin, "You are not the owner");
        _;
    }

    modifier isSilverLotteryPotFull() {
        require(
            silverLotteryMaxEntries == playersSilverLottery.length,
            "silverLottery pot is not full"
        );
        _;
    }

    modifier isGoldLotteryPotFull() {
        require(
            goldLotteryMaxEntries == playersGoldLottery.length,
            "goldLottery pot is not full"
        );
        _;
    }

    modifier isDiamondLotteryPotFull() {
        require(
            diamondLotteryMaxEntries == playersDiamondLottery.length,
            "diamondLottery pot is not full"
        );
        _;
    }

    modifier isSilverBattlePotFull() {
        require(
            silverBattleMaxEntries == playersSilverBattle.length,
            "silverBattle pot is not full"
        );
        _;
    }

    modifier isGoldBattlePotFull() {
        require(
            goldBattleMaxEntries == playersGoldBattle.length,
            "goldBattle pot is not full"
        );
        _;
    }

    modifier isDiamondBattlePotFull() {
        require(
            diamondBattleMaxEntries == playersDiamondBattle.length,
            "diamondBattle pot is not full"
        );
        _;
    }

    modifier isSilverMegaPotFull() {
        require(
            silverMegaPotMaxEntries == playersSilverMegaPot.length,
            "silverMegaPot pot is not full"
        );
        _;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        _mint(account, id, amount, data);
    }

    /* dailyPot */

    function enterDailyPot(uint256 _count) public payable {
        require(
            msg.value == dailyPotEntryPrice * _count,
            "incorrent value sent to contract"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersDailyPot.push(payable(msg.sender));
        }
        emit EntryDailyPot(msg.sender, msg.value);
    }

    function pickDailyPotWinner() external {
        require(
            block.timestamp - lastDailyPot > drawTime,
            "daily pot timer is still running"
        );
        uint256 playersDailyPotLength = playersDailyPot.length;
        lastDailyPot = block.timestamp;
        if (playersDailyPotLength > 0) {
            uint256 index = randomDailyPot() % playersDailyPotLength;
            address payable winningAddress = playersDailyPot[index];
            uint256 winningAmount = (playersDailyPotLength *
                dailyPotEntryPrice *
                winnerCut) / 100;
            winningAddress.transfer(winningAmount);
            payable(houseAddressOne).transfer(
                (playersDailyPotLength * dailyPotEntryPrice * houseCutOne) / 100
            );
            payable(houseAddressTwo).transfer(
                (playersDailyPotLength * dailyPotEntryPrice * houseCutTwo) / 100
            );
            delete playersDailyPot;
            emit WinnerDailyPot(winningAddress, winningAmount, lastDailyPot);
        }
        emit WinnerDailyPotEmpty(lastDailyPot);
    }

    function randomDailyPot() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersDailyPot
                    )
                )
            );
    }

    function getPlayersDailyPot()
        public
        view
        returns (address payable[] memory)
    {
        return playersDailyPot;
    }

    function setDailyEntryPrice(uint256 _newEntryPrice) external restricted {
        dailyPotEntryPrice = _newEntryPrice;
    }

    /* silverLottery */

    function enterSilverLottery(uint256 _count) public payable {
        require(
            msg.value == silverLotteryEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersSilverLottery.length + _count <= silverLotteryMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersSilverLottery.push(payable(msg.sender));
        }
        if (silverLotteryMaxEntries == playersSilverLottery.length) {
            pickSilverLotteryWinner();
        }
        emit EntrySilverLottery(msg.sender, msg.value);
    }

    function pickSilverLotteryWinner() public isSilverLotteryPotFull {
        uint256 index = randomSilverLottery() % playersSilverLottery.length;
        address payable winningAddress = playersSilverLottery[index];
        uint256 winningAmount = (silverLotteryPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (silverLotteryPotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (silverLotteryPotMaxAmount * houseCutTwo) / 100
        );
        if (silverLotteryMintIsLive) {
            mint(winningAddress, 0, 1, "");
        }
        emit FinalPlayersSilverLottery(playersSilverLottery);
        emit WinnerSilverLottery(winningAddress, winningAmount);
        delete playersSilverLottery;
    }

    function setSilverLotteryMintIsLive(bool _state) public onlyOwner {
        silverLotteryMintIsLive = _state;
    }

    function setSilverLotteryEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        silverLotteryEntryPrice = _newEntryPrice;
    }

    function setSilverLotteryMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        silverLotteryMaxEntries = _newMaxEntries;
    }

    function randomSilverLottery() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersSilverLottery
                    )
                )
            );
    }

    function getPlayersSilverLottery()
        public
        view
        returns (address payable[] memory)
    {
        return playersSilverLottery;
    }

    /* goldLottery */

    function enterGoldLottery(uint256 _count) public payable {
        require(
            msg.value == goldLotteryEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersGoldLottery.length + _count <= goldLotteryMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersGoldLottery.push(payable(msg.sender));
        }
        if (goldLotteryMaxEntries == playersGoldLottery.length) {
            pickGoldLotteryWinner();
        }
        emit EntryGoldLottery(msg.sender, msg.value);
    }

    function pickGoldLotteryWinner() public isGoldLotteryPotFull {
        uint256 index = randomGoldLottery() % playersGoldLottery.length;
        address payable winningAddress = playersGoldLottery[index];
        uint256 winningAmount = (goldLotteryPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (goldLotteryPotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (goldLotteryPotMaxAmount * houseCutTwo) / 100
        );
        if (goldLotteryMintIsLive) {
            mint(winningAddress, 1, 1, "");
        }
        emit FinalPlayersGoldLottery(playersGoldLottery);
        emit WinnerGoldLottery(winningAddress, winningAmount);
        delete playersGoldLottery;
    }

    function setGoldLotteryMintIsLive(bool _state) public onlyOwner {
        goldLotteryMintIsLive = _state;
    }

    function setGoldLotteryEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        goldLotteryEntryPrice = _newEntryPrice;
    }

    function setGoldLotteryMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        goldLotteryMaxEntries = _newMaxEntries;
    }

    function randomGoldLottery() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersGoldLottery
                    )
                )
            );
    }

    function getPlayersGoldLottery()
        public
        view
        returns (address payable[] memory)
    {
        return playersGoldLottery;
    }

    /* diamondLottery */

    function enterDiamondLottery(uint256 _count) public payable {
        require(
            msg.value == diamondLotteryEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersDiamondLottery.length + _count <= diamondLotteryMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersDiamondLottery.push(payable(msg.sender));
        }
        if (diamondLotteryMaxEntries == playersDiamondLottery.length) {
            pickDiamondLotteryWinner();
        }
        emit EntryDiamondLottery(msg.sender, msg.value);
    }

    function pickDiamondLotteryWinner() public isDiamondLotteryPotFull {
        uint256 index = randomDiamondLottery() % playersDiamondLottery.length;
        address payable winningAddress = playersDiamondLottery[index];
        uint256 winningAmount = (diamondLotteryPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (diamondLotteryPotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (diamondLotteryPotMaxAmount * houseCutTwo) / 100
        );
        if (diamondLotteryMintIsLive) {
            mint(winningAddress, 2, 1, "");
        }
        emit FinalPlayersDiamondLottery(playersDiamondLottery);
        emit WinnerDiamondLottery(winningAddress, winningAmount);
        delete playersDiamondLottery;
    }

    function setDiamondLotteryMintIsLive(bool _state) public onlyOwner {
        diamondLotteryMintIsLive = _state;
    }

    function setDiamondLotteryEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        diamondLotteryEntryPrice = _newEntryPrice;
    }

    function setDiamondLotteryMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        diamondLotteryMaxEntries = _newMaxEntries;
    }

    function randomDiamondLottery() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersDiamondLottery
                    )
                )
            );
    }

    function getPlayersDiamondLottery()
        public
        view
        returns (address payable[] memory)
    {
        return playersDiamondLottery;
    }

    /* silverBattle */

    function enterSilverBattle(uint256 _count) public payable {
        require(
            msg.value == silverBattleEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersSilverBattle.length + _count <= silverBattleMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersSilverBattle.push(payable(msg.sender));
        }
        if (silverBattleMaxEntries == playersSilverBattle.length) {
            pickSilverBattleWinner();
        }

        emit EntrySilverBattle(msg.sender, msg.value);
    }

    function pickSilverBattleWinner() public isSilverBattlePotFull {
        uint256 index = randomSilverBattle() % playersSilverBattle.length;
        address payable winningAddress = playersSilverBattle[index];
        uint256 winningAmount = (silverBattlePotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (silverBattlePotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (silverBattlePotMaxAmount * houseCutTwo) / 100
        );
        delete playersSilverBattle;

        emit WinnerSilverBattle(winningAddress, winningAmount);
    }

    function setSilverBattleEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        silverBattleEntryPrice = _newEntryPrice;
    }

    function setSilverBattleMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        silverBattleMaxEntries = _newMaxEntries;
    }

    function randomSilverBattle() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersSilverBattle
                    )
                )
            );
    }

    function getPlayersSilverBattle()
        public
        view
        returns (address payable[] memory)
    {
        return playersSilverBattle;
    }

    /* goldBattle */

    function enterGoldBattle(uint256 _count) public payable {
        require(
            msg.value == goldBattleEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersGoldBattle.length + _count <= goldBattleMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersGoldBattle.push(payable(msg.sender));
        }
        if (goldBattleMaxEntries == playersGoldBattle.length) {
            pickGoldBattleWinner();
        }

        emit EntryGoldBattle(msg.sender, msg.value);
    }

    function pickGoldBattleWinner() public isGoldBattlePotFull {
        uint256 index = randomGoldBattle() % playersGoldBattle.length;
        address payable winningAddress = playersGoldBattle[index];
        uint256 winningAmount = (goldBattlePotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (goldBattlePotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (goldBattlePotMaxAmount * houseCutTwo) / 100
        );
        delete playersGoldBattle;

        emit WinnerGoldBattle(winningAddress, winningAmount);
    }

    function setGoldBattleEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        goldBattleEntryPrice = _newEntryPrice;
    }

    function setGoldBattleMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        goldBattleMaxEntries = _newMaxEntries;
    }

    function randomGoldBattle() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersGoldBattle
                    )
                )
            );
    }

    function getPlayersGoldBattle()
        public
        view
        returns (address payable[] memory)
    {
        return playersGoldBattle;
    }

    /* diamondBattle */

    function enterDiamondBattle(uint256 _count) public payable {
        require(
            msg.value == diamondBattleEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersDiamondBattle.length + _count <= diamondBattleMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersDiamondBattle.push(payable(msg.sender));
        }
        if (diamondBattleMaxEntries == playersDiamondBattle.length) {
            pickDiamondBattleWinner();
        }

        emit EntryDiamondBattle(msg.sender, msg.value);
    }

    function pickDiamondBattleWinner() public isDiamondBattlePotFull {
        uint256 index = randomDiamondBattle() % playersDiamondBattle.length;
        address payable winningAddress = playersDiamondBattle[index];
        uint256 winningAmount = (diamondBattlePotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (diamondBattlePotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (diamondBattlePotMaxAmount * houseCutTwo) / 100
        );
        delete playersDiamondBattle;

        emit WinnerDiamondBattle(winningAddress, winningAmount);
    }

    function setDiamondBattleEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        diamondBattleEntryPrice = _newEntryPrice;
    }

    function setDiamondBattleMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        diamondBattleMaxEntries = _newMaxEntries;
    }

    function randomDiamondBattle() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersDiamondBattle
                    )
                )
            );
    }

    function getPlayersDiamondBattle()
        public
        view
        returns (address payable[] memory)
    {
        return playersDiamondBattle;
    }

    /* silverMegaPot */

    function enterSilverMegaPot(uint256 _count) public {
        require(
            ERC1155(address(this)).balanceOf(msg.sender, 0) >= 1,
            "not enough WinnerSilverLottery tokens in wallet"
        );
        require(
            playersSilverMegaPot.length + _count <= silverMegaPotMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersSilverMegaPot.push(payable(msg.sender));
        }
        if (silverMegaPotMaxEntries == playersSilverMegaPot.length) {
            pickSilverMegaPotWinner();
        }
        burn(msg.sender, 0, _count);

        emit EntrySilverMegaPot(msg.sender, _count);
    }

    function pickSilverMegaPotWinner() public isSilverMegaPotFull {
        uint256 index = randomSilverMegaPot() % playersSilverMegaPot.length;
        address payable winningAddress = playersSilverMegaPot[index];
        winningAddress.transfer(silverMetaPotMaxAmount);
        mint(winningAddress, 3, 1, "");

        delete playersSilverMegaPot;
        emit WinnerSilverMegaPot(winningAddress, silverMetaPotMaxAmount);
    }

    function setSilverMegaPotMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        silverMegaPotMaxEntries = _newMaxEntries;
    }

    function randomSilverMegaPot() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersSilverMegaPot
                    )
                )
            );
    }

    function getPlayersSilverMegaPot()
        public
        view
        returns (address payable[] memory)
    {
        return playersSilverMegaPot;
    }

    /* admin */

    function setWinnerCut(uint256 _newWinnerCut) external restricted {
        winnerCut = _newWinnerCut;
    }

    function setHouseOneCut(uint256 _newHouseCut) external restricted {
        houseCutOne = _newHouseCut;
    }

    function setHouseTwoCut(uint256 _newHouseCut) external restricted {
        houseCutTwo = _newHouseCut;
    }

    function setHouseAddressOne(address _newAddress) external restricted {
        houseAddressOne = _newAddress;
    }

    function setHouseAddressTwo(address _newAddress) external restricted {
        houseAddressTwo = _newAddress;
    }

    function setDrawTime(uint256 _newDrawTime) external restricted {
        drawTime = _newDrawTime;
    }

    function withdrawFallback() external payable restricted {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155, ERC1155URIStorage)
        returns (string memory)
    {
        return ERC1155URIStorage.uri(tokenId);
    }

    function setURI(uint256 tokenId, string memory tokenURI)
        external
        onlyOwner
    {
        _setURI(tokenId, tokenURI);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }
}