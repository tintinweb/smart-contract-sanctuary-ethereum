/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/Test.sol



pragma solidity >=0.8.0 <0.9.0;


/*
 $$$$$$\                      $$\                 $$\           $$$$$$$$\                  $$\           
$$  __$$\                     $$ |                \__|          $$  _____|                 $$ |          
$$ /  $$ |$$$$$$$\   $$$$$$$\ $$$$$$$\   $$$$$$\  $$\ $$$$$$$\  $$ |    $$$$$$\   $$$$$$\  $$ | $$$$$$$\ 
$$ |  $$ |$$  __$$\ $$  _____|$$  __$$\  \____$$\ $$ |$$  __$$\ $$$$$\ $$  __$$\ $$  __$$\ $$ |$$  _____|
$$ |  $$ |$$ |  $$ |$$ /      $$ |  $$ | $$$$$$$ |$$ |$$ |  $$ |$$  __|$$$$$$$$ |$$$$$$$$ |$$ |\$$$$$$\  
$$ |  $$ |$$ |  $$ |$$ |      $$ |  $$ |$$  __$$ |$$ |$$ |  $$ |$$ |   $$   ____|$$   ____|$$ | \____$$\ 
 $$$$$$  |$$ |  $$ |\$$$$$$$\ $$ |  $$ |\$$$$$$$ |$$ |$$ |  $$ |$$ |   \$$$$$$$\ \$$$$$$$\ $$ |$$$$$$$  |
 \______/ \__|  \__| \_______|\__|  \__| \_______|\__|\__|  \__|\__|    \_______| \_______|\__|\_______/ 
                                                                                                        
*/








contract Dyno is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;
    uint256 public maxFeels = 10000;
    uint256 public maxFeelPerAddr = 1; // maximum mint allowed per address
    bytes32 public merkleRoot;
    
    uint96 private royaltyFeesInBips = 750; // 7.5%
    address private royaltyAddress;

    struct Feel {
        uint256 bg;
        uint256 faceClr; // same for ear
        uint256 shirtClr;
        uint256 hairclr;
        uint256 prop;
        uint256 earring;
        uint256 hairtype;
        uint256 lipsclr;
        uint256 eyesd; // eyes direction
        uint256 feel_up;
        uint256 feel_down;
    }

    mapping(address => uint256) private feelsMinted; // feels minted per address
    AggregatorV3Interface internal priceFeed;

    string public contractURI = "";
    string private md1='data:application/json;base64,';
    string private md2='data:image/svg+xml;base64,';

    string private ear1 = '" /> <ellipse rx="69.0731" ry="65.7308" transform="matrix(.188577 0 0 0.484658 128.565251 218.143006)" fill="';
    string private ear2 = '" /> <ellipse rx="69.0731" ry="65.7308" transform="matrix(.188577 0 0 0.484658 362.523 218.143)" fill="';

    string[] private pn = [ // prop names
        "",
        "",
        "crown",
        "necklace",
        "hoodie",
        "holy",
        "hoodie",
        "pirate eye patch",
        "glasses",
        "stoned",
        "",
        "taped mouth",
        "sewed mouth",
        "always angry mouth",
        "star",
        "triangle",
        "circle",
        "",
        ""
    ];
    
    string[] private feelsDownTraitNames = [ // _feels bad
    "rekt", "lost", "down", "fooled", "bad", "emotional", "poor", "sad", "the dip", "dead", "broken", "bearish", "down", "down", "bad", "bad", "poor", "sad", "dead", "sad", "down"
    ];

    string[] private feelsUpTraitNames = [ //_feels good
        "excited", "good", "amazing", "excellent", "the pump", "happy", "awesome", "pumped", "bullish", "happy", "good", "good", "excited", "good", "amazing", "excellent", "the pump", "happy", "amazing", "happy"
    ];

    string[] private props = [ // props
    "",
    "",
    '" /> <polygon points="0,-34.31523 32.635724,-10.603989 20.169986,27.761605 -20.169986,27.761605 -32.635724,-10.603989 0,-34.31523" transform="translate(245.544 83.18344)" fill="', // crown [ONLY GIRLS]
    '" /> <ellipse rx="46.0897" ry="40.0938" transform="matrix(1 0 0 0.780343 245.544 414.531188)" stroke-width="7" fill ="none" stroke="', // necklace [BOTH]
    "",
    '" /> <ellipse rx="65.7083" ry="25.4094" transform="matrix(1 0 0 0.788944 244.826 38.375338)" stroke-width="7" fill="none" stroke="', // holy angel [BOTH]
    '" /> <ellipse rx="115.865" ry="220.031" transform="matrix(1.163093 0 0 0.3728 245.544 355.83783)" stroke-width="0" fill="', // hoodie should be body color
    '" /> <ellipse rx="47.366783" ry="29.377679" transform="matrix(.770232 0 0 0.391179 295.395892 191.270846)" fill="#525253"/><rect width="137.013902" height="5.577273" transform="matrix(.906317 0.091975-.100964 0.99489 148.45946 162.241458)" fill="#525253" /><rect width="137.013902" height="5.577273" transform="matrix(.327791-.120547 0.345155 0.938546 300.271209 185.216185)" fill="#525253" /><rect width="94.733566" height="27.606767" transform="matrix(.776042 0 0 0.626797 258.637 174.004902)" fill="#525253', // pirate
    '" /> <rect width="86.0899" height="42.1178" transform="translate(156.859 170.593)" fill="#452e18" fill-opacity="0.3" stroke="#484949" stroke-width="5" /><rect width="86.0899" height="42.1178" transform="translate(251.127609 171.0325)" fill="#452e18" fill-opacity="0.3" stroke="#484949" stroke-width="5" /><rect width="182.026" height="10.4645" transform="matrix(1.00726 0 0 1 153.87 160.568)" fill="#484949" /><rect width="23.6375" height="10.9892" transform="matrix(.412904-.18894 0.416095 0.909321 330.05123 163.036932)" fill="#484949" /><rect width="23.6375" height="10.9892" transform="matrix(.416574 0.198179-.430216 0.904322 151.739964 157.998826)" fill="#484949', //Glasses
    '', // tears
    '" /> <rect width="118.868229" height="14.483066" transform="matrix(.974507-.224357 0.224357 0.974507 193.851667 318.777537)" fill="#a3a2a2" /><rect width="117.462612" height="10.245869" transform="matrix(.955885 0.293741-.293741 0.955885 200.110677 290.35127)" fill="#cdc4b4', // mouth taped
    '" /> <rect width="137.013902" height="5.577273" transform="matrix(.583797 0.087276-.12938 0.865433 210.366623 332.400971)" fill="#525253" /> <rect width="137.013902" height="5.577273" transform="matrix(.089035-.427281 1.008728 0.210195 219.922568 367.065571)" fill="#525253"/> <rect width="137.013902" height="5.577273" transform="matrix(.069066-.331449 1.008728 0.210195 263.767487 366.479401)" fill="#525253" /><rect width="137.013902" height="5.577273" transform="matrix(.028809-.273678 1.626582 0.171224 245.893436 359.06473)" fill="#525253" />', // mouth sewed
    '" /> <rect width="118.868229" height="14.483066" transform="matrix(.53759-.123767-.198798-.863489 222.88375 326.108981)" fill="#c5c3c3" stroke="#f3ad4f" stroke-width="2' // rentangle mouth tilt
    ];

    string[] private earrings = [
    '" /> <polygon points="0,-10.394835 9.886076,-3.212181 6.109931,8.409598 -6.109931,8.409598 -9.886076,-3.212181 0,-10.394835" transform="matrix(-.693691 0.720273-.720273-.693691 118.406456 245.125234)" fill="',// earring polygon
    '" /> <polygon points="-1.157867,-29.675225 23.383765,12.342942 -25.699499,12.342942 -1.157867,-29.675225" transform="matrix(-.183144-.392967 0.364127-.169703 121.557811 247.040589)" fill="',
    '" /> <ellipse rx="11.672326" ry="10.611205" transform="matrix(.7294 0 0 0.828913 124.053194 244.057768)" stroke-width="9" fill="',
    ""
    ];

    string[] private hairsTypePropNames = [
        "bald",
        "short",
        "medium",
        "punk",
        "long",
        "long",
        "long",
        "long"
    ];

    string[] private hairTypes = [
        '" /> <ellipse rx="81.328" ry="110.294" transform="matrix(1.438355 0 0 1.223166 245.543665 220.929693)" fill="', // hairtype boy #1
        '" /> <ellipse rx="81.328" ry="110.294" transform="matrix(1.560897 0 0 1.341702 245.544 235.262403)" fill="', // hairtype boy #2
        '" /> <rect width="16.708" height="55.411" transform="matrix(1.075701 0 0 0.893326 236.632 78.6137)" fill="', // hairtype punk
        '" /> <ellipse rx="81.328" ry="110.294" transform="matrix(.828681 0 0 0.126043 245.544 114.212)" fill="', // hairs on forehead
        '" /> <ellipse rx="81.328" ry="110.294" transform="matrix(1.671073 0 0 1.686593 245.543665 273.911051)" fill="' // hairtype girl
    ];

    string private mu = '" /> <ellipse rx="69.0731" ry="65.7308" transform="matrix(.801322 0 0 0.566101 245.544001 324.148094)" fill="'; // upper mouth 
    string private ml = '" /> <ellipse rx="69.0731" ry="65.7308" transform="matrix(.801322 0 0 0.566101 245.544001 334.201588)" fill="'; // lower mouth 
    string private mn = '" /> <line x1="-23.674" y1="0" x2="23.674" y2="0" transform="translate(244.826115 346.639901)" stroke-width="3" stroke="'; // neutral
    string private eyebrowLeft = '" />   <line x1="-35.093567" y1="3.342246" x2="35.093568" y2="-3.342246" transform="matrix(.836111-.093026 0.108321 0.973584 202.652 159.603823)" stroke-width="4" stroke="'; // eyebrow left
    string private eyebrowRight =  '" />   <line x1="-35.093567" y1="3.342246" x2="35.093568" y2="-3.342246" transform="matrix(.797604 0.267512-.311496 0.928746 290.973327 160.128534)" stroke-width="4" stroke="'; // eyebrow right


        // Background [0]
      string private p0= '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500"> <rect width="100%" height="100%" fill="';
        // Body [1]
       string private p1 = '" /><ellipse rx="115.865" ry="220.031" transform="matrix(.933 0 0 0.837977 245.544 567.625)" fill="';
        // Face [2]
       string private p2 = '" /><ellipse rx="69.0731" ry="65.7308" transform="matrix(1.69355 0 0 2.27118 245.544 250)" fill="';
        // Eye 1 [3]
       string private p3 = '" /> <ellipse rx="19.4964" ry="7.79857" transform="matrix(1.97143 0 0 1.71426 202.652 189.394)" fill="';
        // Eye 2 [4]
       string private p4 = '" /> <ellipse rx="19.4964" ry="7.79857" transform="matrix(1.8 0 0 1.71426 294.006 189.394)" fill="';
       // Eye pupil [5]
       string private p5 = '" /> <ellipse rx="12.254902" ry="9.469498" transform="translate(';
        // [6]
       string private p6 = ')" fill="';
        // Eye pupil 2 [7]
       string private p7 = '" />  <ellipse rx="12.254902" ry="9.469498" transform="matrix(-.999962-.008743 0.008743-.999962 ';
        // [8]
       string private p8 = ')" fill="';
        // Ending SVG [9]
       string private p9 = '" /> </svg>';

    string[] private eyeLeft = [ // eye left
        "219.451 187.801", "180.451 188.801", "179.451 188.801", "199.451 188.801", "198.451 188.801"
    ];

        string[] private eyeRight = [ // eye right
            "290.354 187.801", "300.354 192.901", "314.354 188.901", "274.354 188.901", "294.354 188.801"
    ];
  
    string[] private aparts = [ // properties metadata
                                '[{ "trait_type": "Accessory", "value": "', 
                                '" }, { "trait_type": "Hair/Eyebrow color", "value": "',
                                '" }, { "trait_type": "Shirt", "value": "',
                                '" }, { "trait_type": "Face", "value": "',
                                '" }, { "trait_type": "Feels up", "value": "',
                                '" }, { "trait_type": "Earring", "value": "',
                                '" }, { "trait_type": "Lips", "value": "',
                                '" }, { "trait_type": "Gender", "value": "',
                                '" }, { "trait_type": "Hairs", "value": "',
                                '" }, { "trait_type": "Feels down", "value": "',
                                '" }, { "trait_type": "Background", "value": "',
                                '" }]'];

    string[] private facePropNames = ["ivory", "porcelain", "pale ivory", "warm ivory", "sand", "rose beige", "livestone", "beige", "senna", "honey", "band", "almond", "peaches & cream", "alien", "zombie", "black"];

    string[] private background = ["skyblue", "palegreen", "turquoise", "aquamarine", "antiquewhite", "azure", "lavender", "lightsteelblue", "plum", "pink", "thistle", "aqua", "bisque", "darkseagreen", "royalblue", "yellowgreen", "lightseagreen", "black"]; // only trait that is uniform, no need for rarity weights
    
    string[] private eyesClr = ["#000", "#FF0000", "#32CD32", "#FFF", "#f5b3ab"];
        
    string[] private lipstickClr =["blue", "red", "hotpink", "gold", "indigo", "purple", "olivedrab", "coral", "fuchsia", "white", ""];

    // string[] private faceClr = ["#fdf5e2", "#D2B48C", "#fff5de", "#ECBE83", "#F1DCB7", "#ffd59a", "#f5e0d8", "#F7D6B3", "#ecebe6",  "#f9f5ec", "#d2691e", "#c1b094", "#EADDCA", "#6CC417", "#595a5c"];
    string[] private faceClr = ["#E9CBA9", "#EECEB7", "#F7DDC4", "#F6E1AD", "#F0C795", "#F0C18A", "#E7BC8F", "#EDBE84", "#CE9D7B", "#CB9863", "#AB8963", "#93613C", "#F5E0D8", "#6CC417", "#78866B", "#000"];

    string[] private shirtClr = ["darkblue", "cornflowerblue", "tomato", "orange", "white","teal", "tan", "lime", "olive", "cyan", "chocolate", "peachpuff", "lemonchiffon", "black", "darkcyan", "darksalmon", "darkslateblue", "firebrick", "greenyellow"];

    string[] private hairClr = [ "saddlebrown", "deepskyblue", "gold", "yellow", "white", "mediumpurple", "maroon", "black", "slategray", "brown"];

    constructor() ERC721(" Dynn", "DYYN") {
        royaltyAddress = owner();
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
    }
    // returns current supply of the collection
    function currentSupply() public view returns (uint256) {
        return supply.current();
    }
    // mint an NFT
    function mint(bytes32[] calldata proof)
        public
        payable
    {
        if (msg.sender != owner()) {
        require(feelsMinted[msg.sender] + 1 <= maxFeelPerAddr, "NFTs per address exceeded");
        require(
            supply.current() + 1 <= maxFeels,
            "Supply exceeded!"
        );
        require(
            MerkleProof.verify(
            proof,
            merkleRoot,
            keccak256(abi.encodePacked(msg.sender))
            ),
            "!whitelisted"
                );
        feelsMinted[msg.sender]++;
        _safeMint(msg.sender, supply.current() + 1);
        supply.increment();
        }
    }

    // returns historical price of ETH using Chainlink oracles
    function getHistoricalPrice(uint80 roundId) private view returns (int256) {
        (, int256 price, , , ) = priceFeed.getRoundData(roundId - 23);
        return price;
    }

    // Feel borns here
    function buildImage(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        Feel memory feel = randomOne(_tokenId);
        (uint80 roundId, int256 price, , , ) = priceFeed.latestRoundData();
        int256 histPrice = getHistoricalPrice(roundId);

        int256 percentageChange = (price - histPrice) / 1000000000;
        string memory senti = _tokenId.toString();
        uint256 eyes_clr = 3;

    // rariest black one 2 only
    if(feel.hairtype == 0 && feel.hairclr == 7 && feel.shirtClr == 13 && (feel.lipsclr != 5) && !(feel.prop == 6 || feel.prop == 4 || feel.prop == 2 || (feel.prop == 5 && feel.lipsclr > 4))){
                feel.bg = 18;
                feel.faceClr = 15;
            }
        // Background
        string memory makingFeel = string(abi.encodePacked(p0, background[feel.bg]));

        if(feel.eyesd == 3 && feel.prop == 10){
            feel.faceClr = 13; // alien
        }
        if(feel.eyesd == 4 && feel.prop == 11){
            feel.faceClr = 14; // zombie
        }

        if(feel.hairtype > 3){ // girl
        makingFeel = string(abi.encodePacked(makingFeel, hairTypes[4], hairClr[feel.hairclr]));
        } else {
            if(feel.lipsclr < 3 && feel.hairtype == 0){
                feel.hairtype = 1;
            }
            if(feel.lipsclr > 6 && feel.hairtype == 3){
                feel.hairtype = 2;
            }
                   if(feel.hairtype > 0){ // boys hairClr 1
        makingFeel = string(abi.encodePacked(makingFeel, hairTypes[feel.hairtype - 1], hairClr[feel.hairclr])); // single or bald style
                   }
        // ears
        makingFeel = string(abi.encodePacked(makingFeel, ear1, faceClr[feel.faceClr], ear2, faceClr[feel.faceClr]));
        }
        // prop crown - rarity fig
        if(feel.hairtype > 3 && (feel.prop == 11 || feel.prop ==10)){
                feel.prop = 2;
            }

        // body
        makingFeel = string(abi.encodePacked(makingFeel, p1, shirtClr[feel.shirtClr]));
        
        // props
        if(feel.prop > 1 && feel.prop < 7){
            if(feel.hairtype < 4){ // boy
            if(feel.prop == 2){
                feel.prop = 6;
            }
            }

            if(feel.prop == 6 || feel.prop == 4 || (feel.prop == 5 && feel.lipsclr > 4)) {
                feel.prop = 6;
                makingFeel = string(abi.encodePacked(makingFeel, props[6], shirtClr[feel.shirtClr])); // hoodie
                }else{
            makingFeel = string(abi.encodePacked(makingFeel, props[feel.prop], faceClr[feel.faceClr+1]));
            }
        }

         // stoned
        if(feel.prop == 0 && (feel.eyesd < 2)){
            eyes_clr = 4;
        }
        
        // face
        makingFeel = string(abi.encodePacked(makingFeel, p2, faceClr[feel.faceClr], p3, eyesClr[eyes_clr], p4, eyesClr[eyes_clr]));

        // prop earring
        if(feel.earring < 3){
            makingFeel = string(abi.encodePacked(makingFeel, earrings[feel.earring], lipstickClr[feel.lipsclr]));
            }else{
                feel.earring = 3;
            }

        // bald or forehead hairtype
        if(feel.hairtype != 3 && feel.hairtype != 0){
        makingFeel = string(abi.encodePacked(makingFeel, hairTypes[3], hairClr[feel.hairclr]));    
        }
        // *********** PRICE CHANGE LOGIC *********** //
        if (percentageChange < -1) {
            eyes_clr = 1;
            senti = feelsDownTraitNames[feel.feel_down];
            if( (feel.prop > 10) && feel.eyesd < 3){
        // fancy mouths
        makingFeel = string(abi.encodePacked(makingFeel, props[10 + feel.eyesd]));
            } else{
            if(feel.hairtype < 4){  
                     feel.lipsclr = 9;
            }
        makingFeel = string(abi.encodePacked(makingFeel, mu, lipstickClr[feel.lipsclr], ml, faceClr[feel.faceClr]));
            }

        } 
        else if (percentageChange > -2 && percentageChange < 2) {
            eyes_clr = 0;
            senti = "ok";
           if( (feel.prop > 10) && feel.eyesd < 2){
        makingFeel = string(abi.encodePacked(makingFeel, props[10 + feel.eyesd])); // fancy mouths
            } else{
                        if(feel.hairtype < 4){
                     feel.lipsclr = 9;
            }
        makingFeel = string(abi.encodePacked(makingFeel, mn, lipstickClr[feel.lipsclr]));
            }
        } else {
            eyes_clr = 2;
            senti = feelsUpTraitNames[feel.feel_up];
           if( (feel.prop > 10) && feel.eyesd < 2){
        makingFeel = string(abi.encodePacked(makingFeel, props[10 + feel.eyesd])); // fancy mouths
            } else{
                        if(feel.hairtype < 4){
                     feel.lipsclr = 9;
            }
        makingFeel = string(abi.encodePacked(makingFeel, ml, lipstickClr[feel.lipsclr], mu, faceClr[feel.faceClr]));        
            }
        }

        makingFeel = string(abi.encodePacked(makingFeel, p5, eyeLeft[feel.eyesd], p6, eyesClr[eyes_clr], p7));
        makingFeel = string(abi.encodePacked(makingFeel, eyeRight[feel.eyesd], p8, eyesClr[eyes_clr], eyebrowLeft, hairClr[feel.hairclr]));
        makingFeel = string(abi.encodePacked(makingFeel, eyebrowRight, hairClr[feel.hairclr]));
        if(feel.prop > 6 && feel.prop <9){
        makingFeel = string(abi.encodePacked(makingFeel, props[feel.prop], p9));
        }else{
            if(feel.prop < 2){
            if(feel.prop == 0 && (feel.eyesd < 2)){ //stoned
            feel.prop = 9;
        }
            } else if(feel.prop > 8){
                if((feel.prop > 10) && feel.eyesd < 2){
                feel.prop = feel.eyesd + 11;
                feel.lipsclr = 10;
            }else{
            feel.prop = 0;
            }
            }


        makingFeel = string(abi.encodePacked(makingFeel, p9));
        }
        return buildMetadata(Base64.encode(bytes(makingFeel)), feel, senti, _tokenId); 
    }

    // helper function
    function toString(uint256 _value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    // generate randomness
    function randomOne(uint256 _tokenId)
        internal
        pure
        returns (Feel memory)
    {
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    string(abi.encodePacked("Feels", _tokenId.toString()))
                )
            )
        );
        Feel memory newFeel = Feel(
            ((rand) % 17), // bg : type int
            ((rand) % 13), // faceclr
            ((rand) % 19), // shirtclr
            ((rand) % 10), // hairclr
            ((rand) % 16), // prop,
            ((rand) % 12), // earring,
            ((rand) % 7), // hairtype,
            ((rand) % 9), // lipsclr 
            ((rand) % 5), // eyesd
            ((rand) % 20), // Feel up
            ((rand) % 21) // Feel down
        ); 
        return newFeel;
    }

    function buildMetadata(string memory image, Feel memory _feel, string memory _feels, uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        string memory gend = "female";
        if(_feel.hairtype < 4){
            gend = "male";
        }

        string memory strparams = string(
            abi.encodePacked(
                aparts[0],
                pn[_feel.prop],
                aparts[1],
                hairClr[_feel.hairclr],
                aparts[2],
                shirtClr[_feel.shirtClr],
                aparts[3],
                facePropNames[_feel.faceClr],
                aparts[4],
                feelsUpTraitNames[_feel.feel_up], 
                aparts[5]
            )
        );
        strparams = string(abi.encodePacked(strparams, 
                 pn[_feel.earring + 14], aparts[6], lipstickClr[_feel.lipsclr], aparts[7], gend, aparts[8], hairsTypePropNames[_feel.hairtype], aparts[9], feelsDownTraitNames[_feel.feel_down]));
        strparams = string(abi.encodePacked(strparams, aparts[10], background[_feel.bg], aparts[11]));
        // strparams = string(abi.encodePacked(strparams, feelsDownTraitNames[_feel.bg]));
        return
            string(
                abi.encodePacked(
                    md1,
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"#',
                                _tokenId.toString(),
                                " feels ",
                                _feels,
                                '", "attributes":',
                                strparams,
                                ', "image": "',
                                md2,
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "URI query for nonexistent token"
        );
        return buildImage(_tokenId);
    }

    function setmaxFeelPerAddr(uint256 _maxperadd) public onlyOwner {
        maxFeelPerAddr = _maxperadd;
    }

    // set Merkle root hash later used for whitelisting validation
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
    
    // needs to be removed before deployment
    function teamReserve(uint256 _amount, address _to) public onlyOwner {
         for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_to, supply.current() + 1);
            supply.increment();
        }
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function royaltyInfo(uint256 _salePrice)
        external
        view
        virtual
        returns (address, uint256)
    {
        return (royaltyAddress, (_salePrice / 10000) * royaltyFeesInBips);
    }

    function supportsInterface(bytes4 interfaceId)
            public
            view
            override(ERC721)
            returns (bool)
    {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    // to withdraw contract balance
    function withdraw() public payable onlyOwner nonReentrant {
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}