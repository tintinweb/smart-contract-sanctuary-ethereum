/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol


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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

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
            "ERC1155: caller is not token owner nor approved"
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
            "ERC1155: caller is not token owner nor approved"
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

// File: contracts/CryptoCloudPunks.sol



pragma solidity ^ 0.8.7;




// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#########################################################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&####################################################################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#################################################################################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&########################################################################################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#############################################################################################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###############################################################################################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##BBBBBBB#####&&#############&&&####BBBBBBBB#####&#######BGGGGGBBBBBBBBBBBB####&&#########################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##BPY?7!~~~!7?JJJYPGGP55B###########GPY?7!~~~!7??JJYPGGP55B####G~^~~~!!7?JJYPGPPYJ??7777J5B#######################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BB5JJJJJYY55PPGGGGGGBBGGY~P#######BG5JJJJJYY55PPGGGGGGBBGBY~G###GJ^Y5PGGGGBBBBBBBBBGGGP5Y?7~~75#####################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&GYPBBGGBBBB#BBBBBBBBBBBBG55~?55&&#GYPBBGGBBBBBBBBBBBGBGBBBG55~7P5&G5!JGPGBBBBGGGGGGGGGBBBBBBBBG5Y??G###################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&P?JPBBBBBBBGGGPPPPPPP5PPPP55!.5JP&P?JPBBBBBBBGGGPPPPPPPPPPPP557.5J5#PPJGGGGGGGGPPG5YYYY55PPPPPGGBBGGG5B##################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&B7~JGGB#BBGGGPPP55Y55555YYYYYJ.~PYG7~JGGBBBBGGGPP555Y55555YYYYYJ.~PJ#BBPBBGGPPPPPGGP??J?!^755555PPGBGGBY55B################
// &&&&&&&&&&&&&&&&&&&&&&&&&&P:^YPGBBBGGGP5J7!?Y5GBBBGP5Y?7!~PGY:^YPGBBBGGGP5Y7!7Y5PBBBGP5Y?7!~5GG##Y5BGGGPPPPGGBGYG##B!.J5PP5PPPGPPG??YG################
// &&&&&&&&&&&&&&&&&&&&&&&&&G^^YPBBBGGGP5J~:7PBG5JJ?JY5PB#BBG#P^^YPGBBGGGP5J~:?5GG5YJJJ5PPB#BGG####P!5BGGGGGGGGBPJ5GGGJ:~Y5GPPPPPGP5Y^JPG################
// &&&&&&&&&&&&&&&&&&&&&&&&#?~5PGBBGGGG5J:^PB5JJY5PPGGGPG#####?~5PGBBGGGG5Y^~PB5YJY55PGGGPG######BB!!PGBBGGGGGGG5???777JPGBGGPPPPPYJ:^P5B################
// &&&&&&&&&&&&&&&&&&&&&&&&G7YGGBBGGGGP5!~G#5G#&&&&&######B##G7YGGBBGGGGP57!G#PYG###B########BB##G?.?PPGGGGGGBGGGGGPPBBB##BGGGPP5J7:!PY5#################
// &&&&&&&&&&&&&&&&&&&&&&&&Y!PGGBBGGGGP5~7B##############BB##5!PGGBBGGGGPP?YB##PB###PB#######BB#BP^^5PGGGGGGBBBB#B#PGBBBBGGGGPPY?775P?J##################
// &&&&&&&&&&&&&&&&&&&&&&&&Y!PGGBBBBBBPP77B&#############BB##Y!PGGBBBBBBGG55BBBGBBBB5BBBB####BB#BY~JPGBBBBBGGG5YJ????JJJJYY5PGGPPGPJ?P###################
// &&&&&&&&&&&&&&&&&&&&&&#&G75GGBBBBB#BGGPPGBBBBBGGGPPP5PPG##G75GGBBBBBBBBBGGGGPGPPPY5PPPGBBBBGBBYYGGBBBBBGGGJ!!~~~~~!7?J5PB#BBP5YYP#####################
// &&&&&&&&&&&&&&&&&&&&#####?!PPGBBBB##BBBBPJJ?7!!~~~~!!~?G###JJGGBBBBBGGGP55YYYYYJJ7??JJY5PGGPBBPBBBBBBBBGBGYYGBBBBB######BGP5PGB#######################
// &&&&&&&&&&&&&&&&&&#######P:~Y5GBBB######BBGGGGGGGGGG57YYB##GJYGGGPP5555Y????7??7777777?J5P5YBBBBBBBBBBBB#GBB#BBBBBB#B#################################
// &&&&&&&&&&&&&&&&&########BP^:?5GBB###############BBBPP5JBBBBPJYYJJ?7?JJJJ?7?7777??????JJ5P5JGGBBBBBBBBB#BJG#####BB####################################
// &&&&&&&&&&&&&&&&#########GGBY77YGGBBBBBB##BB##BBBB#BG#P5BBG5J7!!777!!7????777?7?????JJJYYPY?GGGBBBGGPPPGJ?B#####BB####################################
// &&&&&&&&&&&&&&&###########P5B#G5GGP555555YYJJJJJJYYJPBPPBPJ!~!!!!!7!!!!7???7?JJJJ?????JY55YJGGPPPGG5YJJJJP######BB####################################
// &&&&&&&&&&&&&&&############B5Y5GB#BPYJJ7!!~^~~!7?Y5GBBPPP!^^~~~~^^~!7!~!7?J??JJJJJJJYY55PP5YGPPP5PGGGGBBBB######BB####################################
// &&&&&&&&&&&&&&&##############B5J??JYPPGPPPPGBB#####BBBGY~::^^^^^^^^!!~!7?JY?JJ55YYY55PPPPPP5GGP55PGGGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&&&&&################&&#BP5YYYYYY5G###BBBBBBB5~:::^^^:^^^~~~!7?JJYJ5Y555JY555555555P55YYPGBBBBBBB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&&&&####################################BBBBG7^::::^^^^~~!~!!?JJJYJY5YYY5GGGGGPP55YYJJYY5GBBBB#BG#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&&&&####################################BBBBG?~^::^^^^^~~~~~7YYYYYYYYY?J5GGGGGGGGGP555YYPPGBBB#BP#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&&&#####################################BBBBB5~~^^~^^:^~^~!!?55PPGGGGP5PGGGGGGBBBGGGGP5YPGBBBB#BP##BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&&&####################################BBBBBB5~^^^~^^:^~~~~!!?YGBBBBBBBBBBBBBBBBBBGBBGPPGBBBBB#BG#B##########################################
// &&&&&&&&&&&######################################BBBBBJ:::^^~7!77!~~!!7J5PGBBBBBBBBBBBBBBBGGBBBBBBBBBBB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&&#######################################BBBBPJJ7~?YPJ5P5YY55PGGGPPGBBBBBBBBBBGP5PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&########################################BBBBGPGGG5JPY5GBBBBGGBBGGGGGBBBBBBBGPY5GBBBBBBBBBBB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&########################################BBBBBBBP5PJJYYGBGGBPPGGPYGGGPPPPGGGGGGBBBBBBBBBBBGB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&######################################B####BBBBBBY7!7J?JY55GP555J5GPPGGBBBBBBBBBBBBBBBBB#BGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&#######################################BB####BBBBB57?JYJJ777JJJYJPGPGGBBBBBBBBBBBGBBBBBBB#BPBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&#######################################BB######BBBGPGGPY5YY55YYPGGGGBBBBBBBBBBBBGGGBBBBBB#BPB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&#######################################BB######BBBBBBBGGPGGPP55BBBBBBBBBBBBBBBBBBBGBBBBBB#B5B#BB#BBBBBBBB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&######################################BB######BB#BBBBPPBGPPY5PGGGBBBBBBBBBBBBBBBBGGGB#BB#BJB#BB#BBBBBBBB#BB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&###############################BB#####BB######BB##BBBGJ5Y5YJYP5GGGBBBBBBBBBBBBBBBGGPB#BB#B?G#BB#BBBBBBBB#GG#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&##############################BB#####GB######BB###BBBP5YYJYYGGPBBBBBBGBBGGBBBBBGGBGBBBB#BJB#BB#BBBBB#BB#PP#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&##############################BB#####GG######B#####BBB5YY5PPGBBBBBBBGPGGGBGBBBBBBBBBBBB#B5B#GG#BBBBBBBB#GG#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&&#############################BB#####PPB#####BB#####BBBGBBBGGBBBBBGGPYGBBBGBBB###BGG#BBBBPB#PP#B#BGB#BB#BB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&&#########################B###GG#####55B#####BB######B##BGGGGGGBGGPPPPBBBBGB#####BGG#BBBBGB#GG#B#BGB#BB#BB#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&&&########################G###GP#####YJB#####BB#########BBBGGGGPPGGGPPBB#BGB######PG#BBBBGB#BB#B#GPB#B##BB#BBBB#BBB#BBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&&&&#######################B###P5####BJ?GBBBB#GB#BBB####BBGG5Y55Y5PGGP5BBBGPBBBBBBBJYBBBBBBB#BB###G5BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&&&&################BBBBBBBBBBBYJBBBGGJJGBGGPP?JYYJ???JYYYYJ?JYYYYJJ57~?Y5Y75P5YJYY~7P5PPPPGBGPPPGY7GBBBGGGGGGGGGGGBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&&&&&&&##############BBBBBBBGGGGP7!55YY?:.~~!??7^~!!77?7!::~!~^~7Y5PJ!7~:~YPY~YYJ??J7:.^^^~~~~~^!?JJ!^?JJJYYY5YPPPGGGBBBBBBBBBBBBBBBBBBBBBBBBBB
// &&&&&&&&#####################BBBGGP5YJ??!!?7!77~~7!:^7J~?555YYYJJJ?JJJJJJJJJJJJJJJJ7:?JJJJJJ^~777!~!??7!~^:..^^:^~7JYJPGGBBBBBB#########BBBBBBBBBBBBBB
// &&&&&&&#########BBBBBBBBGGGGPPP555YJ7!~^..^:^!7?YP5YYYJ^~7?JJJJYYY55555PPPPPPPPPPPPJ~Y55YYYJ~~J?JJJ?JJJJ??J7~JYJ?777!^~7??JYY55PPPGGGBBBBBBBBBBBBBB###
// &&&&&&&&&&&&&######BBBBGGGPP555Y?!?J5PPPJ?Y5PP5??JJ??J?^7J5PGGGBBBBBBB#############GYBBBBBBGY5P55YJ????JYYY7!YYJ!~^^:.....:~!7??JY55PPGGGGBBBBBBBBB###
// ###############BBBBBGGGP55YJJ7~^~7J??7?PPPGP55Y????JY5P?55GBB######################BPB#####BGGBBGGGP5YJ???J7~?5PPY!:~!??7^.~??JYY55PPPGGGGGBBBBBBBBBBB
// #########BBBBBBBBBGGGGGPPP55J!:?5YJ7~:?GP55?JYJ?7!J5PPG5P5G########################BGB######BBBBBBGGP5Y?7????YY5PGGY~!!7?7^.^7?JYY55PPPGGGGGGGGGBBBBBB
// &&&&&############BBBGGP55YJ?~..^7!~:. ~PGPPYJYYJJ77JY5PYP5GBBBB####################BB######BBBBBGGPP5J???JJ?!?YPGGP5PGGGBGJ:!YPPPGGGBBBBBBB###########
// &&&&&&&&&&#####BBGGP5YYJ7!~^^: .!YPP5Y~7YPGBGP5YY7?JJJ?7??YPPPPGBBBBBBB#BB#######BBBGBBBBGGGP555YJJ???JJYJJJYPGPY7^^~!??7!^^!?JJYY55PPGGGGBBBBB#######
// &&&&&&&######BBBBGGPPP55YJJ???7!^^7YPGJ5J7!!7J5PGJ5P55Y???JJJ?!JYYYYY5555?555555555YJYYYYJJJ??JJJJJY555PPP5Y5P5J7!!~:.:. .:^~!77?JYY55PPPGGGGBBBBBB###
// &&&##########BBBBBBBBGGGP55YJ?77!!^:^^::!7JJJY5YJ~!?JY5Y55PPPY755YYYYYYYY7YYYJJYYYYYJY55Y55555PPPPPGGGGP5?!::^7??77!~!7??77!!!!!7?JY55PPGGGGGBBBBBBBBB
// &###############BBBBGGGGGGPPPPPPP5555YJJYJ?7!!^:..:~~^^:!?Y5PY7PPPGGGGGPYJYYYYPGGGP5J??J??7!!?YPPPPPPPP55Y?7~. ::^^!7JJYY55PPPPPPPPPPPPGGGGGBBBBBBBBBB
// &&&&&&&&&&################BBBBBGGGGGP5?7~^:^~!!!~:::~!77?JYYYJ?PPGBBBBPJ. ^~J~JGGGPY!: ::^~^..^~!7!~^:.^JYYY555YJ??JYY5PPGGGGPPGGGGGBBBBBBBBBBBBBBBB##
// &&&&&&&&&&&&&&&&&############BBBGGP5YJJYY555YJJ?JJY55YYYYYJJJJJPGBBBGPY!.:!JYY~75P5Y?!^. :^~~~~^::^!77!7JYPGGBBBBBBGGPPPPPGGBBBBBBBBBGGGGBBBBBBBBBBBBB
// &&&&&&&&&&&&&&&&&&&#########BBBBGGBBBBBGGPPPPGGGGPPPGGGGGGGGBBB#####BGPY?JPPPG7!5GGGPPYJ!!?JJY555J??JY5PGGGGGBBB########BBBBGGBBBB########BBBBBBBBBBBB
// &&&&&&&&&&&&&&&&&&&&&&###########BBBGGGBBBB#BBBBBBBB##BB############BBGPPPGBGB5J5BBBBBBGP5555PGGBBGGPP5PGBB#######################BBBBB#############BB
// &&&&&&&&&&&&&&&&&&&&&&&&&####BBBBBBB#################################BBGGBBBB#G5PB######BBGGGGBBBBBBBBBBGGGBB#########################################
// &&&&&&&&&&&&&&&&&&&&&&####BBBB#######################################BBGBB####BGGB#########BBBBB##########BBBBBB######################################
// &&&&&&&&&&&&&&&&&&&############&&&&&&&&&&&###########################BBBB#####BGGB############################BBBB####################################
// &&&&&&&&&&&&&&&&&&&#&&&&&&&&&&&&&&&&&&&&&&&&&########################BBB######BBBB####################################################################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&################################BBB####################################################################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###################################################################################################
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&################################################################################################

contract CryptoCloudPunks is ERC1155, Ownable {
    // editing section starts below here
    string public name = "Crypto Cloud Punks"; //name your NFT collection
    string public symbol = "CCPS"; //few letters to represent the symbol of your collection
    string private ipfsCID = "QmWAE7eWhf1Mq8jeRGuE7brP3186Vpv28QLTDhhrYJVgCU"; // ipfs metadata folder CID as the starting or hidden NFT
    uint256 public collectionTotal = 8888; // total number of NFTs to start your collection
    uint256 public cost = 0.01 ether;  // Phase 1 price per mint
    uint256 public maxMintAmount = 20; // max amount a user other than owner can mint at in one session
    uint256 public maxBatchMintAmount = 20;  // max batch amount a user other than owner can mint at in one session
    uint256 public whitelisterLimit = 88; // max amount a whitelisted user can mint during presale 
    // editing section end

    bool public paused = false;
    bool public revealed = false;
    bool public mintInOrder = true;

    uint256 public ogCollectionTotal; // the original collection total
    uint256 public tokenNextToMint; //next token index to mint
    mapping(uint => string) private tokenURI;
    mapping(uint256 => uint256) private currentSupply;
    mapping(uint256 => bool) private hasMaxSupply;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => bool) private createdToken; // if true token has been minted at least one time or was updated into the collection total

    bool public onlyWhitelisted = true;
    address[] public whitelistedAddresses;
    mapping(address => uint256) public whitelisterMintedBalance;

    address payable public payments; //0xCc4e40f98C507501F5DF1BCc8BAE21b4637d6f7b the payout address for the withdraw function
    address public admin_1 = 0x522ee4130B819355e10218E40d6Ab0c495219690;

    constructor() ERC1155(""){
        ogCollectionTotal = collectionTotal;
        maxSupply[1] = 1;
        hasMaxSupply[1] = true;
        createdToken[1] = true;
        currentSupply[1] = 1; //sets current supply to the amount minted on deploy
        tokenNextToMint = 2; //sets the next token index to mint on deploy
        _mint(msg.sender, 1, 1, ""); //sends Owner, NFT id 1, amount 1
    }

    /**
     * @dev The contract developer's website.
     */
    function contractDev() public pure returns(string memory){
        string memory dev = unicode"🐸 HalfSuperShop.com 🐸";
        return dev;
    }

    /**
     * @dev Admin can set the PAUSE state.
     * true = closed to Admin Only
     * false = open for Presale or Public
     */
    function pause(bool _state) public onlyAdmins {
        paused = _state;
    }

    /**
     * @dev Allows Admins, Whitelisters, and Public to Mint NFTs in Order from 1-ogCollectionTotal.
     * Can only be called by the Public when onlyWhitelisted is false.
     */
    function _mintInOrder(uint _numberOfTokensToMint) public payable {
        require(mintInOrder, "This Can Only Be Used When mintInOrder is True");
        require(!paused, "Contract Paused");
        require(!exists(8888), "Collection Minted Out");
        require(_numberOfTokensToMint + tokenNextToMint <= ogCollectionTotal + 1, "Exceeds Collection Total, Please Lower Amount");

        if (!checkIfAdmin()) {
            if (onlyWhitelisted) {
                require(isWhitelisted(msg.sender), "Not Whitelisted");
                uint256 whitelisterMintedCount = whitelisterMintedBalance[msg.sender];
                require(whitelisterMintedCount + _numberOfTokensToMint <= whitelisterLimit, "Exceeded Max Whitelist Mint Limit");
            }
            require(msg.value >= (_numberOfTokensToMint * costPhase()), "Insufficient Funds");
        }

        whitelisterMintedBalance[msg.sender] += _numberOfTokensToMint;

        uint256[] memory _ids = new uint256[](_numberOfTokensToMint);
        uint256[] memory _amounts = new uint256[](_numberOfTokensToMint);
        for (uint256 i = 0; i < _numberOfTokensToMint; i++) {
            uint256 _id = tokenNextToMint;
            if (!exists(_id)) {
                createdToken[_id] = true;
                maxSupply[_id] = 1;
                hasMaxSupply[_id] = true;
                currentSupply[_id] = 1;
            }

            _ids[i] = tokenNextToMint;
            _amounts[i] = 1;
            tokenNextToMint++;
        }

        _mintBatch(msg.sender, _ids, _amounts, "");
    }

    function costPhase() public view returns(uint256){
        if (tokenNextToMint <= 100){
            return 10000000000000000;
        }
        if (tokenNextToMint >= 101 && tokenNextToMint <= 300){
            return 30000000000000000;
        }
        if (tokenNextToMint >= 301 && tokenNextToMint <= 8888){
            return 60000000000000000;
        }
        return cost;
    }

    /**
     * @dev Allows Owner, Whitelisters, and Public to Mint a single NFT.
     * Can only be called by the Public when onlyWhitelisted is false.
     */
    function mint(address _to, uint _id, uint _amount) public payable {
        require(!mintInOrder, "Only Can Use the Mint In Order Function At This Time");
        require(!paused, "Contract Paused");
        require(canMintChecker(_id, _amount), "CANNOT MINT");
        if (_id <= ogCollectionTotal){
            require(oneOfOneOnly(_id, _amount), "Amount must be 1 for this NFT");
            require(!createdToken[_id], "Token Already Minted");
            maxSupply[_id] = 1;
            hasMaxSupply[_id] = true;
        }

        if (!checkIfAdmin()) {
            if (onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "Not Whitelisted");
                uint256 whitelisterMintedCount = whitelisterMintedBalance[msg.sender];
                require(whitelisterMintedCount + _amount <= whitelisterLimit, "Exceeded Max Whitelist Mint Limit");
            }
            require(msg.value >= (_amount * cost), "Insufficient Funds");
        }

        whitelisterMintedBalance[msg.sender] += _amount;
        currentSupply[_id] += _amount;
        if (!exists(_id)) {
            createdToken[_id] = true;            
        }
        _mint(_to, _id, _amount, "");
    }

    function canMintChecker(uint _id, uint _amount) private view returns(bool){
        if (hasMaxSupply[_id]) {
            if (_amount > 0 && _amount <= maxMintAmount && _id > 0 && _id <= collectionTotal && currentSupply[_id] + _amount <= maxSupply[_id]) {
                // CAN MINT
            }
            else {
                // CANNOT MINT 
                return false;
            }
        }
        else {
            if (_amount > 0 && _amount <= maxMintAmount && _id > 0 && _id <= collectionTotal) {
                // CAN MINT
            }
            else {
                // CANNOT MINT 
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Allows Owner, Whitelisters, and Public to Mint multiple NFTs.
     * Can only be called by the Public when onlyWhitelisted is false.
     * Note: Only mint a max of {mintMaxAmount} or less NFT IDs with a totaling amount of {maxBatchMintAmount} at a time.
     * Example to Mint 3 of each Token IDs 1, 2, 3, 4:
     * _ids = [1,2,3,4]
     * _amounts = [3,3,3,3]
     * 4 seperate NFTs with a quantity of 3 each has a totaling amount of 12.
     */
    function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) public payable {
        require(!mintInOrder, "Only Can Use the Mint In Order Function At This Time");
        require(!paused, "Contract Paused");
        require(_ids.length <= maxMintAmount, "Batch Token IDs Limit Exceeded");
        require(_ids.length == _amounts.length, "IDs Array Not Equal To Amounts Array");
        require(canMintBatchChecker(_ids, _amounts), "CANNOT MINT BATCH");

        uint256 _totalBatchAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];
            if (_id <= ogCollectionTotal){
                require(oneOfOneOnly(_id, _amount), "Amount must be 1 for this NFT");
                require(!createdToken[_id], "Token Already Minted");
                maxSupply[_id] = 1;
                hasMaxSupply[_id] = true;
            }
            _totalBatchAmount += _amounts[i];
        }
        require(_totalBatchAmount <= maxBatchMintAmount, "Batch Amount Limit Exceeded");

        if (!checkIfAdmin()) {
            if (onlyWhitelisted) {
                require(isWhitelisted(msg.sender), "Not Whitelisted");
                uint256 whitelisterMintedCount = whitelisterMintedBalance[msg.sender];
                require(whitelisterMintedCount + _totalBatchAmount <= whitelisterLimit, "Exceeded Max Whitelist Mint Limit");
            }
            require(msg.value >= (_totalBatchAmount * cost), "Insufficient Funds");
        }

        whitelisterMintedBalance[msg.sender] += _totalBatchAmount;

        for (uint256 k = 0; k < _ids.length; k++) {
            currentSupply[_ids[k]] += _amounts[k];
            uint256 _id = _ids[k];
            if (!exists(_id)) {
                createdToken[_id] = true;
            }
        }

        _mintBatch(_to, _ids, _amounts, "");
    }

    function canMintBatchChecker(uint[] memory _ids, uint[] memory _amounts)private view returns(bool){
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];
            if (hasMaxSupply[_id]) {
                if (_amount > 0 && _amount <= maxMintAmount && _id > 0 && _id <= collectionTotal && currentSupply[_id] + _amount <= maxSupply[_id]) {
                    // CAN MINT
                }
                else {
                    // CANNOT MINT
                    return false;
                }
            }
            else {
                if (_amount > 0 && _amount <= maxMintAmount && _id > 0 && _id <= collectionTotal) {
                    // CAN MINT
                }
                else {
                    // CANNOT MINT
                    return false;
                }
            }
        }

        return true;
    }

    /**
     * @dev Allows Admin to Mint a single NEW NFT.
     * Can only be called by the current owner.
     * Note: NEW NFT means above and beyond the original collection total.
     */
    function adminMint(address _to, uint _id, uint _amount) external onlyAdmins {
        require(_id > ogCollectionTotal, "ID Must Not Be From Original Collection");
        if (!exists(_id)) {
            createdToken[_id] = true;
            collectionTotal++;
        }
        currentSupply[_id] += _amount;
        _mint(_to, _id, _amount, "");
    }

    /**
     * @dev Allows Admin to Mint multiple NEW NFTs.
     * Can only be called by the current owner.
     * Note: NEW NFT means above and beyond the original collection total.
     * Ideally it's best to only mint a max of 70 or less NFT IDs at a time.
     * Example to Mint 3 of each Token IDs 1, 2, 3, 4:
     * _ids = [1,2,3,4]
     * _amounts = [3,3,3,3]
     */
    function adminMintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external onlyAdmins {
        require(!checkIfOriginal(_ids), "ID Must Not Be From Original Collection");
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            if (!exists(_id)) {
                createdToken[_id] = true;
                collectionTotal++;
            }
            currentSupply[_id] += _amounts[i];
        }
        _mintBatch(_to, _ids, _amounts, "");
    }

    /**
    * @dev Allows User to DESTROY a single token they own.
    */
    function burn(uint _id, uint _amount) external {
        currentSupply[_id] -= _amount;
        _burn(msg.sender, _id, _amount);
    }

    /**
    * @dev Allows User to DESTROY multiple tokens they own.
    */
    function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            currentSupply[_id] -= _amounts[i];
        }
        _burnBatch(msg.sender, _ids, _amounts);
    }

    /**
    * @dev Allows Admin to REVEAL the original collection.
    * Can only be called by the current owner once.
    * WARNING: Please ensure the CID is 100% correct before execution.
    */
    function reveal(string memory _uri) external onlyAdmins {
        require(!revealed, "Already set to Revealed");
        ipfsCID = _uri;
        revealed = true;
    }

    /**
    * @dev Allows Admin to set the URI of a single token.
    * Note: Original Token URIs cannot be changed.
    *       Set _isIpfsCID to true if using only IPFS CID for the _uri.
    */
    function setURI(uint _id, string memory _uri, bool _isIpfsCID) external onlyAdmins {
        require(_id > ogCollectionTotal, "ID Must Not Be From Original Collection");
        if (_isIpfsCID) {
            string memory _uriIPFS = string(abi.encodePacked(
                "ipfs://",
                _uri,
                "/",
                Strings.toString(_id),
                ".json"
            ));

            tokenURI[_id] = _uriIPFS;
            emit URI(_uriIPFS, _id);
        }
        else {
            tokenURI[_id] = _uri;
            emit URI(_uri, _id);
        }
    }

    /**
    * @dev Allows Admin to set the URI of multiple tokens.
    * Note: Original Token URIs cannot be changed.
    *       Set _isIpfsCID to true if using only IPFS CID for the _uri.
    */
    function setBatchURI(uint[] memory _ids, string memory _uri, bool _isIpfsCID) external onlyAdmins {
        require(_ids.length > 1, "Must have at least 2 ids");
        require(!checkIfOriginal(_ids), "ID Must Not Be From Original Collection");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            if (_isIpfsCID) {
                string memory _uriIPFS = string(abi.encodePacked(
                    "ipfs://",
                    _uri,
                    "/",
                    Strings.toString(_id),
                    ".json"
                ));

                tokenURI[_id] = _uriIPFS;
                emit URI(_uriIPFS, _id);
            }
            else {
                tokenURI[_id] = _uri;
                emit URI(_uri, _id);
            }
        }
    }

    function uri(uint256 _id) override public view returns(string memory){
        if (_id > 0 && _id <= ogCollectionTotal) {
            if(!revealed){
                return (
                string(abi.encodePacked(
                    "ipfs://",
                    ipfsCID,
                    "/",
                    "hidden",
                    ".json"
                )));
            }
            else{
                return (
                string(abi.encodePacked(
                    "ipfs://",
                    ipfsCID,
                    "/",
                    Strings.toString(_id),
                    ".json"
                )));
            }
                
        }
        else {
            return tokenURI[_id];
        }
    }

    function checkIfOriginal(uint[] memory _ids) private view returns(bool){
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            if (_id <= ogCollectionTotal) {
                // original
            }
            else {
                // new
                return false;
            }
        }
        return true;
    }

    function oneOfOneOnly (uint _id, uint _amount) private view returns (bool){
        if (_id <= ogCollectionTotal && _amount == 1){
            return true;
        }
        else{
            return false;
        }
    }

    /**
    * @dev Total amount of tokens in with a given id.
    */
    function totalSupply(uint256 _id) public view returns(uint256) {
        return currentSupply[_id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 _id) public view returns(bool) {
        return createdToken[_id];
    }

    /**
    * @dev Checks max supply of token with the given id.
    */
    function checkMaxSupply(uint256 _id) public view returns(uint256) {
        if(_id <= ogCollectionTotal){
            return 1;
        }
        else{
            return maxSupply[_id];
        }
    }

    /**
     * @dev Admin can set a supply limit.
     * Note: If supply amount is set to 0 that will make the supply limitless.
     */
    function setMaxSupplies(uint[] memory _ids, uint[] memory _supplies) external onlyAdmins {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            maxSupply[_id] += _supplies[i];
            if (_supplies[i] > 0) {
                // has a max limit
                hasMaxSupply[i] = true;
            }
            else {
                // infinite supply, because you wouldn't create a token max supply with an amount of zero 
                hasMaxSupply[i] = false;
            }
        }
    }

    /**
     * @dev Admin can update the collection total to allow minting the newly added NFTs.
     */
    function updateCollectionTotal(uint _amountToAdd) external onlyAdmins {
        collectionTotal += _amountToAdd;
    }

    /**
     * @dev Check if address is whitelisted.
     */
    function isWhitelisted(address _user) public view returns(bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Admin can set the amount of NFTs a user can mint in one session.
     */
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyAdmins {
        maxMintAmount = _newmaxMintAmount;
    }

    /**
     * @dev Admin can set the max amount of NFTs a whitelister can mint during presale.
     */
    function setNftPerWhitelisterLimit(uint256 _limit) public onlyAdmins {
        whitelisterLimit = _limit;
    }

    /**
     * @dev Admin can set the PRESALE state.
     * true = presale ongoing for whitelisters only
     * false = sale open to public
     */
    function setOnlyWhitelisted(bool _state) public onlyAdmins {
        onlyWhitelisted = _state;
    }

    /**
     * @dev Admin can set the addresses as whitelisters.
     * Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
     */
    function whitelistUsers(address[] calldata _users) public onlyAdmins {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    /**
     * @dev Admin can set the new cost in WEI.
     * 1 ETH = 10^18 WEI
     * Use https://coinguides.org/ethereum-unit-converter-gwei-ether/ for conversions.
     */
    function setCost(uint256 _newCost) public onlyAdmins {
        cost = _newCost;
    }

    /**
     * @dev Admin can set the payout address.
     */
    function setPayoutAddress(address _address) external onlyOwner{
        payments = payable(_address);
    }

    /**
     * @dev Admin can pull funds to the payout address.
     */
    function withdraw() public payable onlyAdmins {
        require(payments != 0x0000000000000000000000000000000000000000, "Payout Address Must Be Set First");
        (bool success, ) = payable(payments).call{ value: address(this).balance } ("");
        require(success);
    }

    /**
     * @dev Auto send funds to the payout address.
        Triggers only if funds were sent directly to this address.
     */
    receive() payable external {
        require(payments != 0x0000000000000000000000000000000000000000, "Payout Address Must Be Set First");
        uint256 payout = msg.value;
        payments.transfer(payout);
    }

     /**
     * @dev Throws if called by any account other than the owner or admin.
     */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner or admin.
     */
    function _checkAdmins() internal view virtual {
        require(msg.sender == owner() || msg.sender == admin_1, "Admin Only: caller is not an admin");
    }

    function checkIfAdmin() public view returns(bool) {
        if (msg.sender == owner() || msg.sender == admin_1){
            return true;
        }
        else{
            return false;
        }
    }

}