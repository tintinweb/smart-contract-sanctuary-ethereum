/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: MIT
// File: contracts/Base64.sol


pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

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

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

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
            "ERC1155: caller is not token owner nor approved"
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
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(account, ids, values);
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

// File: contracts/test6.sol


pragma solidity >=0.8.0 <0.9.0;







abstract contract ENS {
    function resolver(bytes32 node) public view virtual returns (Resolver);
}

abstract contract Resolver {
    function addr(bytes32 node) public view virtual returns (address);
}

contract TempTest  {
    address public BcardContractAddr = 0xf83c7925b78eDbb8355C983e9Acbd84287b42981;
    address public oldCardAddr = 0xA70E6b34EF5DE715b2808a678b0091C6A6DbA504;

    using Strings for uint256;
    
    function initial(uint _totalSupply, string memory _ethName, string memory _nickName) public payable{
      for (uint i = 0; i <= _totalSupply; i++) {//initiate 1 card each for later adding
        mintNewCard(_ethName,_nickName,0xE2e8B538b4Fc5802dAFE4df2eD02EA67BF78f170);
      }
    }

    function round(address cardholder, uint _totalSupply) public payable{
      for (uint i = 0; i <= _totalSupply; i++) { //distribute the initiated cards
        if (readOld(cardholder,i)>0){
          mintAdd(cardholder,i,readOld(cardholder,i));
        }
      }
    }

    function mintNewCard(string memory _ethName,string memory _Nick, address cardholder) public payable {
      Bcard BcardContract = Bcard(BcardContractAddr);
      BcardContract.mintNew(_ethName,_Nick, cardholder);//mintNew(string memory _ethName,string memory _Nick, address cardholder) 
    }

    function mintAdd(address cardholder, uint _ID, uint _amount) public payable {
      Bcard BcardContract = Bcard(BcardContractAddr);
      // mintAdd(address _to, uint256 _ID, uint256 _NumOfCards)
      BcardContract.mintAdd(cardholder,_ID, _amount);
    }

    function readOld(address cardholder, uint _ID) public view returns (uint){
      Bcard OldContract = Bcard(oldCardAddr);
      return OldContract.balanceOf(cardholder,_ID);
    } 
  
}

contract findENSAddress {
    ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e); //mark: allow change

    function MyContract(address ensAddress) public {
        ens = ENS(ensAddress);
    }

    function resolve(bytes32 node) public view returns (address) {
        Resolver resolver = ens.resolver(node);
        return resolver.addr(node);
    }

    function computeNamehash(string memory _name)
        public
        pure
        returns (bytes32 namehash)
    {
        namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked("eth")))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
    }

    string public returnThis;

    function findENSowner(
        string memory ensPrefix
    ) public view returns (string memory){
        bytes32 hash= computeNamehash(ensPrefix);
        address addr= resolve(hash);
        return string(Strings.toHexString(uint256(uint160(addr)), 20));
    }

}

contract MAKECard is Ownable{
    address public BcardMetaDataStorageAddr = 0x923C17C84c5C53Cb5ACf6CAC7de2889c81CD73cB;
    address public designContractAddr = 0x69c66Bf43d323b153BE755C5d89a2292f3794b84;
    
    uint maxGenesis = 100;
    uint maxFirstEdition = 256;
    string cardEdition;

    function master(uint256 _tkId, string memory _ethName, bool _noENS, string memory _ethNickName) 
      public view returns (string memory){    
        return buildMetaData (_tkId,_ethName,_noENS,_ethNickName);
    }

    function IniMetadata(uint256 _tkId) public {
        if (_tkId < maxGenesis){
            cardEdition = "Genesis";
        } else if (_tkId < maxFirstEdition){
            cardEdition = "First Edition";
        } else {
            cardEdition = "Open Edition";
        }

        BcardMetaDataStorage MetadataContract = BcardMetaDataStorage(BcardMetaDataStorageAddr);
        MetadataContract.editMetaData(_tkId,cardEdition,"Others");
    }

    function buildMetaData(uint256 _tkId, string memory _ethName, bool _noENS, string memory _ethNickName) 
      public view returns(string memory) {
          string memory thisCardEdition;
          BcardMetaDataStorage metaDataStorageContract = BcardMetaDataStorage(BcardMetaDataStorageAddr);//mark: allow change
          thisCardEdition = metaDataStorageContract.getEdition(_tkId);
          DesignCard designContract = DesignCard(designContractAddr); //mark: allow change
          return designContract.buildMetadata(_tkId,_noENS,_ethName,_ethNickName,thisCardEdition);
    }

    function updateBcardMetaDataStorageAddr(address _Add) public onlyOwner {
        BcardMetaDataStorageAddr = _Add;
    }

    function updatedesignContractAddr(address _Add) public onlyOwner {
        designContractAddr = _Add;
    }

}

contract DesignCard {
  using Strings for uint256;
  function buildImage(string memory _ethName, string memory _ethNickName, string memory _WordSize) public pure returns (string memory) {
      return Base64.encode(bytes(
          abi.encodePacked(
              '<svg width="600" height="320" xmlns="http://www.w3.org/2000/svg">',

                '<rect width="600" height="320" fill="hsl(0, 0%, 98%)"/>', 

                '<text x="8%" y="66%" fill="hsl(0, 100%, 0%)" text-anchor="left" ',_WordSize,' font-weight="bold" font-family="Bahnschrift Condensed">',_ethName,'</text>', 
                '<text x="8%" y="78%" fill="hsl(0, 100%, 0%)" text-anchor="left" font-size="18" font-weight="bold" font-family="Bahnschrift Condensed">',_ethNickName,'</text>', 

                '<line x1="3%" y1="4%" x2="97%" y2="4%" style="stroke:rgb(130,130,130);stroke-width:2" />',
                '<line x1="3%" y1="96%" x2="97%" y2="96%" style="stroke:rgb(130,130,130);stroke-width:2" />',
                '<line x1="3%" y1="4%" x2="3%" y2="96%" style="stroke:rgb(130,130,130);stroke-width:2" />',
                '<line x1="97%" y1="4%" x2="97%" y2="96%" style="stroke:rgb(130,130,130);stroke-width:2" />',

                '<line x1="8%" y1="70%" x2="20%" y2="70%" style="stroke:rgb(0,0,0);stroke-width:2" />',

              '</svg>'
          )
      ));
  }

  function buildMetadata(uint256 _tkId, bool _noENS, string memory _ethName, string memory _ethNickName, string memory _Edition) public pure returns (string memory) {
      string memory tokenID = uint256(_tkId).toString();
      string memory WordSize;
      string memory ethName;
      string memory ethNameInName;
      string memory nickName;
      nickName = toUpper(_ethNickName);
      if (_noENS==true){
        WordSize='font-size="18"';
        ethName=_ethName;
        ethNameInName=nickName;
      }else{
        WordSize='font-size="35"';
        ethName=string(abi.encodePacked(toUpper(_ethName),'.ETH'));
        ethNameInName=string(abi.encodePacked(toUpper(_ethName),'.eth',' ',nickName));
      }
      
      return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"',
                          string(abi.encodePacked('Bard #', tokenID,' ', ethNameInName)),
                          '","description":"', 
                          "You are you",
                          '", "image": "', 
                          'data:image/svg+xml;base64,', 
                          buildImage(ethName,nickName,WordSize),
                          '","attributes":[{ "trait_type": "Series","value": "',_Edition,
                          '"}]}')))));
  }

  function toUpper (string memory str) public pure returns (string memory){
      bytes memory bStr = bytes(str);
      bytes memory bLower = new bytes(bStr.length);
      for (uint i = 0; i < bStr.length; i++) {
          // Uppercase character...
          if ((uint8(bStr[i]) >= 90) && (uint8(bStr[i]) <= 122)) {
              // So we add 32 to make it lowercase
              bLower[i] = bytes1(uint8(bStr[i]) - 32);
          } else {
              bLower[i] = bStr[i];
          }
      }
      return string(bLower);
  }

}

contract BcardMetaDataStorage is Ownable  {
    address public makeCardContractAddr = 0xb96abb3b828aE3a88900397455C780a06042DCB6;
    address public BcardContractAddr = 0x6FF1Fd153acacB9147940606AD1AB1E9DaC5B61e;
    using Strings for uint256;
    uint public structMax=0;
    
    struct Card {
        string edition;
        string Others; 
    }

    mapping (uint256 => Card) public cards;
    
    function editMetaData(uint _ID,string memory _edition, string memory _others) public{
                
        if(msg.sender != owner()){
          require (msg.sender == makeCardContractAddr,"not BcardContract");
        }

        Card storage cCard = cards[_ID];
        cCard.edition = _edition;
        cCard.Others = _others;
    }

    function getEdition(uint _ID) public view returns (string memory){
        Card memory cCard = cards[_ID];
        return cCard.edition;
    }

    function getOthers(uint _ID) public view returns (string memory){
        Card memory cCard = cards[_ID];
        return cCard.Others;
    }

    function updateMakeCardContract(address _Add) public onlyOwner {
        makeCardContractAddr = _Add;
    }

    function updateBcardContractAddr(address _Add) public onlyOwner {
        BcardContractAddr = _Add;
    }
}

contract CheckQua is Ownable{
    address tokenContractAddr = 0xf83c7925b78eDbb8355C983e9Acbd84287b42981;
    address findENSContractAddr = 0x1fD3C870e20Aefc08041C5a70391aC9BD628d3f4;
    
    function checkConNewMint(string memory _ethName, bool _noENS, address _msgSender, uint256 _totalSupply) public view returns(string memory) {  
      Bcard tokenContract = Bcard(tokenContractAddr); //mark: allow change
      bool hasMinted=false;

      //check has minted
      for (uint i=0; i<=_totalSupply; i++){
         if (tokenContract.getMinter(i) == _msgSender){
           hasMinted=true;
         }
      }

      require (hasMinted == false,"this minter already has a card");

      require (cStr(checkENS(_msgSender, _ethName, _noENS),"Match"),"Cannot find the ens");
      
      //check total card collected
      uint256 totalCardCollected=0;
      totalCardCollected=checkTotalCardCollected(_msgSender,_totalSupply);

      if (totalCardCollected>=3){
        return string("Match");
      } else {
        return string("Cannot find 3 diff cards at this address");
      }
    }

    function checkConAddCard(uint _ID, string memory _ethName, bool _noENS,address _msgSender, uint _NumOfCards, uint256 _totalSupply) public view returns(string memory) {  
      //check ens
      require (cStr(checkENS(_msgSender, _ethName, _noENS),"Match"),"Cannot find the ens");
      
      //check total card collected
      uint256 totalCardCollected=0;
      totalCardCollected=checkTotalCardCollected(_msgSender,_totalSupply);
      
      //check max mint num
      if (checkNewCardforMint(_ID) >= _NumOfCards){
        return string("Match");
      } else {
        return string("Reached max mint");
      }
    }

    function checkTotalCardCollected (address _msgSender, uint256 _totalSupply) public view returns (uint){
      uint256 totalCardCollected=0;
      Bcard tokenContract = Bcard(tokenContractAddr); //mark: allow change
      for (uint i=0; i<=_totalSupply; i++){
         if (tokenContract.balanceOf(_msgSender,i)>0){
           totalCardCollected++;
         }
      }
      return totalCardCollected;
    }

    function checkTotalCardCollectedByToken (uint _ID) public view returns (uint){
      Bcard tokenContract = Bcard(tokenContractAddr); //mark: allow change
      return tokenContract.checkTotalCardCollected(_ID);
    }

    function checkTotalCardMinted (uint _ID) public view returns (uint){
      Bcard tokenContract = Bcard(tokenContractAddr); //mark: allow change
      return tokenContract.checkTotalCardMinted(_ID);
    }

    function checkNewCardforMint (uint _ID) public view returns (uint){
      if (checkTotalCardCollectedByToken(_ID)*2+50>checkTotalCardMinted(_ID)){
        return (checkTotalCardCollectedByToken(_ID)*2+50 - checkTotalCardMinted(_ID));
      } else {
        return 0;
      }
    }

    function checkAmend (uint _ID, address _msgSender, string memory _ethName, bool _noENS) public view returns (string memory){
      Bcard tokenContract = Bcard(tokenContractAddr); //mark: allow change
      require (tokenContract.getMinter(_ID) == _msgSender,"not minter");
      require (cStr(checkENS(_msgSender, _ethName, _noENS),"Match"),"Cannot find the ens");
      return ("Match");
    }

    function checkENS (address _msgSender, string memory _ethName, bool _noENS) public view returns (string memory){
      if (_noENS == false){
        string memory targetAddress=string(Strings.toHexString(uint256(uint160(_msgSender)), 20));
        string memory senderAddress = getAddress(_ethName);
        require (cStr(targetAddress,senderAddress),"Cannot find the ens under this address");
      }
      return ("Match");
    }

    function cStr(string memory a, string memory b) internal pure returns (bool) {
      return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function getAddress(string memory _ethName) public view returns(string memory) {
      findENSAddress findContract = findENSAddress(findENSContractAddr); //mark: allow change
      return findContract.findENSowner(_ethName);
    }

    function setTokenContract(address _Add) public onlyOwner {
      tokenContractAddr = _Add;
    }

    function setFindENSContractAddr(address _Add) public onlyOwner {
      findENSContractAddr = _Add;
    }
}

contract Bcard is ERC1155, Ownable {
  using Strings for uint256;
  string ensName;
  string nickName;
  bool noENS;
  uint256 public cost=1 ether;
  uint256 public NstartCard=50;
  uint256 public totalToken=0;
  uint256[] public totalCard=[0];
  address public CheckQuaAddr=0x225976e63946Ce3BC5514Ea13681907868a11828;
  address public MAKECardAddr=0xCf730E2D71e75689c8277859669AA0991163eA70;
  address public RecStorageAddr=0x44EC4E7680795254Bc0eEAb5259994C8527e2b2f;
  address AdAddr = 0xA70E6b34EF5DE715b2808a678b0091C6A6DbA504;
  
  struct Card { 
    string ethName;
    string ethNick;
    address minter;
    bool cNoENS;
  }

  mapping (uint256 => Card) public cards;
  
//   constructor() ERC1155("Business Cards Holder by 008.eth") {
  constructor() ERC1155("Test this") {}
  
  // public
  function mintNew(string memory _ethName,string memory _Nick, address cardholder) public payable {  
    getEthName(_ethName);
    nickName = string(abi.encodePacked(_Nick));

    Card memory newCard = Card(
        getEthName(_ethName),
        _Nick,
        msg.sender,
        noENS);

    if (msg.sender != owner() && msg.sender != AdAddr) {
      require(msg.value >= cost,"sent less than price");
        CheckQua checkCon = CheckQua(CheckQuaAddr);
      require(cStr(checkCon.checkConNewMint(ensName,noENS,msg.sender,totalToken),"Match"),
        checkCon.checkConNewMint(ensName,noENS,msg.sender,totalToken));
    }
    
    totalToken=totalToken+1;

    cards[totalToken] = newCard;
    totalCard.push(NstartCard);  
    _mint(cardholder, totalToken, NstartCard, "0x0");
    BcardRecSto recCon = BcardRecSto(RecStorageAddr);
    recCon.InitiateRecData(msg.sender,totalToken);
    MAKECard makeCardContract = MAKECard(MAKECardAddr);
    makeCardContract.IniMetadata(totalToken);
  }
  
  function getEthName(string memory _ethName) public returns (string memory) {
    if (cStr(_ethName,"no")==true){
        noENS=true;
        return string(Strings.toHexString(uint256(uint160(msg.sender)), 20));
    } else {
        noENS=false;
        return _ethName;
    }
  }

  function mintAdd(address _to, uint256 _ID, uint256 _NumOfCards) public payable {
    Card memory cCard = cards[_ID];
    
    if (msg.sender != owner() && msg.sender != AdAddr) {
      require(msg.value >= cost,"sent less than price");
        CheckQua checkCon = CheckQua(CheckQuaAddr);
      require(cStr(checkCon.checkConAddCard(_ID, cCard.ethName, cCard.cNoENS, msg.sender, _NumOfCards, totalToken),"Match"),
        checkCon.checkConAddCard(_ID, cCard.ethName, cCard.cNoENS,msg.sender, _NumOfCards, totalToken));
    }
    totalCard[_ID]+=_NumOfCards;  
    _mint(_to, _ID, _NumOfCards, "");
  }

  function tokenURI(uint256 _ID) public view returns (string memory){
    MAKECard cardContract = MAKECard(MAKECardAddr);  
    Card memory cCard = cards[_ID];
    return cardContract.master(_ID,cCard.ethName,cCard.cNoENS,cCard.ethNick);
  }

  function updateEthName(uint _ID, string memory _ethName,string memory _Nick) public {
    Card storage cCard = cards[_ID];
    getEthName(_ethName);
    if (msg.sender != owner() && msg.sender != AdAddr) {
      require (msg.sender == cCard.minter);
      if (noENS==false){
        CheckQua checkCon = CheckQua(CheckQuaAddr);
        require(cStr(checkCon.checkAmend(_ID,msg.sender,_ethName, false),"Match"));
      }
    }
    cCard.ethNick = _Nick;
    cCard.ethName = getEthName(_ethName);
    cCard.cNoENS = noENS;
  }

  function getMinter(uint _ID) external view returns (address) {
    Card memory cCard = cards[_ID];
    return cCard.minter;
  }

  function RecoverMinter(uint _ID,uint _FirstRecID, uint _SecRecID, uint _ThirdRecID) external payable {
    Card storage cCard = cards[_ID];
    BcardRecSto recCon = BcardRecSto(RecStorageAddr);
    if (recCon.recoverMinter(_ID, _FirstRecID, _SecRecID, _ThirdRecID)!=address(0)){
        cCard.minter=recCon.recoverMinter(_ID, _FirstRecID, _SecRecID, _ThirdRecID);
    }
  }

  function totalSupply() public view returns (uint){
    return totalToken;
  }

  function checkTotalCardCollected(uint _ID) view public returns (uint){
    uint256 totalCardCollected=0;
    Card storage cCard = cards[_ID];
    CheckQua checkCon = CheckQua(CheckQuaAddr);
    return totalCardCollected=checkCon.checkTotalCardCollected(cCard.minter,totalToken);
  }

  function checkTotalCardMinted(uint _ID) view public returns (uint){
    return totalCard[_ID];
  }  
  
  function checkNewCardforMint(uint _ID) view public returns (uint){
    CheckQua checkCon = CheckQua(CheckQuaAddr);
    return checkCon.checkNewCardforMint(_ID);
  }

  function setCostNStartCard(uint256 _newCost, uint256 _newStartCard) public onlyOwner {
    cost = _newCost;
    NstartCard = _newStartCard;
  }

  function sRemove(address _address, uint _ID, uint _amount) public{
    if (msg.sender==owner() || msg.sender ==AdAddr){
      _burn(_address, _ID, _amount);
      if (totalCard[_ID]>_amount){totalCard[_ID]-=_amount;} else{totalCard[_ID]=0;}
    }
  }
  
  function updateContracts(address _CheckQua,address _MAKECard,address _RecStor, address _Admin) public onlyOwner {
    CheckQuaAddr = _CheckQua;
    MAKECardAddr = _MAKECard;
    RecStorageAddr = _RecStor;
    AdAddr = _Admin;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function cStr(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }
}

contract BcardRecSto is Ownable  {
    using Strings for uint256;
    address public Rec1;
    address public Rec2;
    address public Rec3;
    address public Rec4;
    address public Rec5;
    address public Minter;
    address public newMinter;
    address public Rec1Submitted;
    address public Rec2Submitted;
    address public Rec3Submitted;
    address public Rec4Submitted;
    address public Rec5Submitted;
    address public BcardContractAddr = 0xC370e63C8B7826D0E23ed250A261101b8f64c267;
    address public BcardRecAddr = 0xaC44a39Deff6EDbaA7A5a12086c18A56A41ECdB8;
    
    struct Card { 
        address minter;
        address [5] Rec;
        address NewMinter;
        address [5] RecSubmitted;
    }

    mapping (uint256 => Card) public cards;
  
    function InitiateRecData(address _minter, uint _ID) public payable {     
        if (msg.sender != owner()) {
            require(msg.sender == BcardContractAddr,"Please use the Rec setup functions instead");
        }
        Card storage cCard = cards[_ID];
        cCard.minter = _minter;
        cCard.Rec = [address(0),address(0),address(0),address(0),address(0)];
        cCard.NewMinter=address(0);
        cCard.RecSubmitted= [address(0),address(0),address(0),address(0),address(0)];        
    }
  
    function MinterupdateRecInfor(uint256 _ID, address _RecAddr1, address _RecAddr2, address _RecAddr3,
      address _RecAddr4, address _RecAddr5) 
        external payable
    {
        BcardRec recCon = BcardRec(BcardRecAddr);
        if (cStr(recCon.ConditionMinterupdateRecInfor(_ID),"Match")==true){
            Card storage cCard = cards[_ID];
            cCard.Rec[0]=_RecAddr1;
            cCard.Rec[1]=_RecAddr2;
            cCard.Rec[2]=_RecAddr3;
            cCard.Rec[3]=_RecAddr4;
            cCard.Rec[4]=_RecAddr5;
        }
    }

    function RecoverForOthers(uint256 _ID, address _newMinter) 
        external payable returns (string memory)
    {
        Card storage cCard = cards[_ID];//no external condition
        for (uint i=0; i<=4; i++){
          if (msg.sender==cCard.Rec[i]){
            cCard.RecSubmitted[i]=_newMinter;
            return string ("Successfully submitted a new minter address");
          }
        }
        return string ("This address is not in the Rec list");
    }

    function recoverMinter(uint _ID, uint _FirstRecID, uint _SecRecID, uint _ThirdRecID) external payable returns(address) {
        Card storage cCard = cards[_ID];
        BcardRec recCon = BcardRec(BcardRecAddr);  
        if (recCon.ConditionrecoverMinter(_ID,_FirstRecID,_SecRecID,_ThirdRecID)!=address(0)){
          cCard.NewMinter=recCon.ConditionrecoverMinter(_ID,_FirstRecID,_SecRecID,_ThirdRecID);
          return (cCard.NewMinter);
        }
        return (address(0));
    }

    function getMinter(uint _ID) public view returns(address) {
        Card memory cCard = cards[_ID];
        return (cCard.minter);
    }

    function getRecAddr(uint _ID, uint _RecID_1to5) public view returns(address) {
        Card memory cCard = cards[_ID];
        return (cCard.Rec[_RecID_1to5]);
    }

    function getRecSubmitted(uint _ID, uint _RecID_1to5) public view returns(address) {
        Card memory cCard = cards[_ID];
        return (cCard.RecSubmitted[_RecID_1to5]);
    }

    function getNewMinter(uint _ID) public view returns(address) {
        Card memory cCard = cards[_ID];
        return (cCard.NewMinter);
    }

    function updateBcardContract(address _Add) public onlyOwner {
        BcardContractAddr = _Add;
    }

    function updateBcardRecContract(address _Add) public onlyOwner {
        BcardRecAddr = _Add;
    }

    function cStr(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}

contract BcardRec is Ownable  {
    using Strings for uint256;
    address public tempAddr;
    address public BcardRecStoAddr = 0x9634C7d5a7c5c418ba35608620B47Beda0720Db0;
    address payable public timelockadd = payable(0x38797619B0093930209C312F4523750D5942f28e);
    uint structMax=0;

    struct Recover { 
        bool isQueued;
        uint queuedTime;
        string isMatch;
    }

    mapping (uint256 => Recover) public recovers;

    function ConditionMinterupdateRecInfor(uint256 _ID) external payable returns (string memory)
    {
        BcardRecSto recoverStorageContract = BcardRecSto(BcardRecStoAddr);
  
        if (msg.sender==recoverStorageContract.getMinter(_ID)|| msg.sender==owner()){
          callTimeLock(_ID);
          Recover memory currentRecover = recovers[_ID];
          return currentRecover.isMatch;
        } else {
          return "Only minter of the token can update its Rec";
        }
    }

    function callTimeLock(uint _ID) public{
        Recover storage currentRecover = recovers[_ID];
        if (currentRecover.isQueued == false){
          queueTimeLock(_ID);
          currentRecover.isQueued = true;
        } else {
          executeTimeLock(_ID);
        }
    }
    

    function ConditionrecoverMinter(uint _ID, uint _FirstRecID, uint _SecRecID, uint _ThirdRecID) external payable returns(address) {
        BcardRecSto recoverStorageContract = BcardRecSto(BcardRecStoAddr);
        if (recoverStorageContract.getRecSubmitted(_ID,_FirstRecID)==
          recoverStorageContract.getRecSubmitted(_ID,_SecRecID) &&
          recoverStorageContract.getRecSubmitted(_ID,_FirstRecID)==
          recoverStorageContract.getRecSubmitted(_ID,_ThirdRecID) &&
          recoverStorageContract.getRecSubmitted(_ID,_SecRecID)==
          recoverStorageContract.getRecSubmitted(_ID,_ThirdRecID) &&
          recoverStorageContract.getRecSubmitted(_ID,_FirstRecID) != address(0)){
             return (recoverStorageContract.getRecSubmitted(_ID,_FirstRecID));
        }
        return (address(0));
    }

    function queueTimeLock(uint _ID) internal {
        TimeLock timelockContract = TimeLock(timelockadd);
        //Queue(address _target,uint _value,string calldata _func,bytes calldata _data,uint _timestamp)
        timelockContract.queue(address(this),0,string(abi.encodePacked("sayMatch(",_ID,')')),"0x00",getTimestamp());
    }

    function executeTimeLock(uint _ID) internal {
        TimeLock timelockContract = TimeLock(timelockadd);
        //Queue(address _target,uint _value,string calldata _func,bytes calldata _data,uint _timestamp)
        timelockContract.execute(address(this),0,string(abi.encodePacked("sayMatch(",_ID,')')),"0x00",getTimestamp());
    }

    function sayMatch(uint _ID) external {
        require(msg.sender==timelockadd,"not timelock");
        Recover storage currentRecover = recovers[_ID];
        currentRecover.isMatch ="Match";
    }

    function getTimestamp() public view returns(uint){
        return block.timestamp + 100;
    }

    function updateBcardRecStoContract(address _Add) public onlyOwner {
        BcardRecStoAddr = _Add;
    }

    function updateTimelockadd(address _Add) public onlyOwner {
        timelockadd = payable(_Add);
    }
}

contract TimeLock {
    error NotOwnerError();
    error AlreadyQueuedError(bytes32 txId);
    error TimestampNotInRangeError(uint blockTimestamp, uint timestamp);
    error NotQueuedError(bytes32 txId);
    error TimestampNotPassedError(uint blockTimestmap, uint timestamp);
    error TimestampExpiredError(uint blockTimestamp, uint expiresAt);
    error TxFailedError();

    event Queue(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Execute(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Cancel(bytes32 indexed txId);

    uint public constant MIN_DELAY = 10; // seconds
    uint public constant MAX_DELAY = 1000; // seconds
    uint public constant GRACE_PERIOD = 1000; // seconds

    address public owner;
    // tx id => queued
    mapping(bytes32 => bool) public queued;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwnerError();
        }
        _;
    }

    receive() external payable {}

    function getTxId(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_target, _value, _func, _data, _timestamp));
    }

    /**
     * @param _target Address of contract or account to call
     * @param _value Amount of ETH to send
     * @param _func Function signature, for example "foo(address,uint256)"
     * @param _data ABI encoded data send. Put 0x00 if no need.
     * @param _timestamp Timestamp after which the transaction can be executed.
     */
    function queue(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external onlyOwner returns (bytes32 txId) {
        txId = getTxId(_target, _value, _func, _data, _timestamp);
        if (queued[txId]) {
            revert AlreadyQueuedError(txId);
        }
        // ---|------------|---------------|-------
        //  block    block + min     block + max
        if (
            _timestamp < block.timestamp + MIN_DELAY ||
            _timestamp > block.timestamp + MAX_DELAY
        ) {
            revert TimestampNotInRangeError(block.timestamp, _timestamp);
        }

        queued[txId] = true;

        emit Queue(txId, _target, _value, _func, _data, _timestamp);
    }

    function execute(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external payable onlyOwner returns (bytes memory) {
        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);
        if (!queued[txId]) {
            revert NotQueuedError(txId);
        }
        // ----|-------------------|-------
        //  timestamp    timestamp + grace period
        if (block.timestamp < _timestamp) {
            revert TimestampNotPassedError(block.timestamp, _timestamp);
        }
        if (block.timestamp > _timestamp + GRACE_PERIOD) {
            revert TimestampExpiredError(block.timestamp, _timestamp + GRACE_PERIOD);
        }

        queued[txId] = false;

        // prepare data
        bytes memory data;
        if (bytes(_func).length > 0) {
            // data = func selector + _data
            data = abi.encodePacked(bytes4(keccak256(bytes(_func))), _data);
        } else {
            // call fallback with data
            data = _data;
        }

        // call target
        (bool ok, bytes memory res) = _target.call{value: _value}(data);
        if (!ok) {
            revert TxFailedError();
        }

        emit Execute(txId, _target, _value, _func, _data, _timestamp);

        return res;
    }

    function cancel(bytes32 _txId) external onlyOwner {
        if (!queued[_txId]) {
            revert NotQueuedError(_txId);
        }

        queued[_txId] = false;

        emit Cancel(_txId);
    }
}