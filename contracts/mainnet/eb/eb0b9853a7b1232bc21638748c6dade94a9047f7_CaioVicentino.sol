/**
 *Submitted for verification at Etherscan.io on 2022-07-13
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

// File: contracts/ERC721A.sol


// Creator: Chiru Labs

pragma solidity ^0.8.4;









error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
abstract contract ERC721A is Context, ERC165, IERC721 {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId, string memory baseExtension) public view virtual returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        if (_exists(tokenId)) return string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseExtension));
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseExtension)) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) public {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: CaioVicentino.sol



pragma solidity >=0.7.0 <0.9.0;

//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
//import "@openzeppelin/contracts/utils/Strings.sol";

//import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
//import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import "@openzeppelin/contracts/utils/Context.sol";

//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";




contract CaioVicentino is ERC721A, Ownable {
  using Address for address;
  using Strings for uint256;

  string private baseURI; //Deve ser a URL do json do pinata: 
  string private baseExtension = ".json";
  string private notRevealedUri = "";
  uint256 private maxSupply = 2000;
  uint256 private maxMintAmount = 5;
  uint256 private FreeMintPerAddressLimit = 1;
  bool private paused = true;
  bool private onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) private addressMintedBalance;
  mapping(uint256 => uint) private _availableTokens;
  uint256 private _numAvailableTokens;

  address _contractOwner;

  mapping (address => bool) private _affiliates;
  bool private _allowAffiliateProgram = true;
  uint private _affiliateProgramPercentage = 15;

  bool private _allowRecommendation = true;
  uint256 private _recommendationPercentage = 10;
  uint256 private _royalties = 10;
  uint256 royaltiesSpender;

  mapping(address => uint256) private _addressLastMintedTokenId;

  bool private _isFreeMint = false;
  uint256 private _nftEtherValue = 250000000000000000;

  event _transferSend(address _from, address _to, uint _amount);

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721A(_name, _symbol) {
    setBaseURI(_initBaseURI);

    whitelistedAddresses = [
        0x81F10a638289eF66cD784049d901Bb25eE36AFC6,
        0xA7337bd8E6dD5134f3Af68a97C1f73Ca29523C89,
        0x6450dA461D027A49C2b30F8cf41Bd72798699A6B,
        0x50BC324249624E152312E7465C435355a1fFBc8D,
        0xF52D03e7a9696f5e090A5b5Dc36Aa2E490aB4434,
        0xAd8E9e0e87b2E5c2c90ea413ce6600E8B2097eFf,
        0x903D52710222A4d0F622084ed51464e80C32E129,
        0x2637C82c3998648A3909B93C8E0baf84b152E5FF,
        0xFb591314B65eEF7bb1475d03b27ef230f411bfb5,
        0xb61642CDeF7F494c603ACdb94E2617fbF8A1c5F3,
        0xEe5F9319b41287C84059F79035aE1F4aBDd40887,
        0xFD7208b28F596211F64DF4c06e0b17E37bc690f0,
        0xE70E0a3A6abde3E20B3b2703Fa4aBDffc16634FE,
        0x4477E59250e6565b0DaD0f500bFD6a85238A30b4,
        0xcB1d177d7Cb3A4985CF783FBD6Cc42169f47B272,
        0xaDF6B80B4f6b2BD3a2438FC6d6F11526B02E0eaA,
        0x9a761Cc6331Fd28D0b04811135dfA233f6499C9C,
        0xA95a2e96a7aCc714677bCE90ddEFd257838C7DAE,
        0xf913d44F4D2000DCeb230f847d3711a7EBc4Ca68,
        0xa4C3C19334a52a451C1173d696F2739Fd8E2eC4F,
        0x02c61b0bC7AEC8fa40eF91311c3C923eE6b9E084,
        0x36A2A9B42C807d1b4bF60cD66AA0302677CE7AB1,
        0xDc7F990EC4D2F2470BdeAfcABb9aE2C17Cc11312,
        0xB224614C79cCc0b31dbBfACf4fBcDe178a0D8817,
        0x1a9fF5f9e1A1801474Fe33c1530c4bEcdE560397,
        0x125aD150043F25A8C0A09C8b82Ac2a26EaAC1400,
        0x5996c5e0EaE30D76878AdCa83554de2c2FF68987,
        0x30D4c032C6e7a1B85fbeA75C3F0b9f540aAC1067,
        0x660A7093C70e2857E404A5F6B4C774bd7E8d9942,
        0x0bADBdaa62809b75a3A6D19edd7c3cCeCf5cC530,
        0x2aE9E465277155c62782176E4Ffa9821335664D8,
        0x321392a37400E03083743648D98b9eB6D73A8e7F,
        0x9eD2D17E0c7777768B609a7B5862bb9CBe4De881,
        0x04a3d07F39b643948c39Ad3d3aa24EF03A6B7CFC,
        0x5D972A19197cDF398C9Ee0792C9B294Fe6Ec8CEA,
        0xdc800F118daCeb08cb06Abed3C0811bE7cAE9B14,
        0x3f7ebD27deCBDbf0178fD5a76Fda010EFAc14403,
        0x6EaF5692fF6Af4860604E3C22F76C4a2Baab2ea4,
        0xD8276041B083f8864B6e8953988C44e3921dE2C4,
        0xc307C0f599721092b9A53AeD9d737dB15d42CaA0,
        0xa380300BE85b84D15e92c1502CD085E4FD382196,
        0xf646d6Aab948baD288bce6924A7B88cAcBE7C5a5,
        0xcAA6F6c65527CD54b89E0D1793BD1E2F67b0e8Fd,
        0x0527fEF489AaaA7ab8550e48bd90b2afBa204A1a,
        0xCb80e7f2d8bEa4B3E4E891a7763ada8834ce7489,
        0x3ada65250978e00026f5D94CedB4c0892cB5AE06,
        0x3B330a2Aad9D2E69427044d632a696Dc2Ad7299A,
        0x46ac2a5881A9756A958E563E48385FE13367EdB6,
        0x848f7B971bEBcB660A4C2C071D0fD631E6c60Aca,
        0x9083FA9EdDaEAbAfeA9beB7af8E78585Ed4f098F,
        0x9277741535022c7f3488E1c4c9F17Fd6626189fb,
        0xE67BA543F2f5EAF639AeEc136417b892AAE77247,
        0xdA75B96a7b1799cf2691B89077bF4163Efef281B,
        0x2B0B03CcA9198A8ffe85F0EcA321E514bc15A518,
        0x71078b85099187FCa048b37753FFf208e49a4d20,
        0x0250cd163a13b41030bc20D96868d93aCdf51CF8,
        0xE3C84eA82874cE9E02954eEF2119E5298df4e0Ad,
        0x6f1E7C7165cdAD8146FeA8E838fAe6421F548eBa,
        0x6658C279A936Bf73C185864bC1e1Fac61f301DF0,
        0xBdC044C51C32DB9CfaAb1b6fb9F9B4C4A93Cd64e,
        0x982F43EbB971E6087fDB5b0E9f27d34288750b8F,
        0x1e8956830135f274fCC786b0c6F4D5D546810FA4,
        0x85194fFba51D0A3d9b7aBcAe802868F1e03f021C,
        0xdCD88f18ba1c11AE9CE86763cbf6FEB475544790,
        0xf8F818438A402B931e4202998a81b2630BfB43A3,
        0xCd90c627206D14416E0AD518fC80089cb206EaEF,
        0x63E0161Fc85BD2640894d17051399fE013362e1E,
        0x01911D3DC3E10fE13e1400e2E8516E8F1d19D51c,
        0x963C32D2e404d062a1305468A52F1c774a9D768E,
        0xC356E8fFEa6c866bE5F293d5FEe3A39c70e4075F,
        0xfc073e73C0677c1876368fE6Fd64DD98023f1a76,
        0xDE47a1bA1a4Ee603611DEe23539a4B8976ed713C,
        0x4547B89eAEd946e1cF22050522f48B67370728d6,
        0xA8EE3A92Bdf7437485696C13F24f7B6FE1d15cD9,
        0x6890C938B3a3d460396c257892A1e88021D271BD,
        0x2F419B26514ae7D132293327CFE1Ae12eb4E77C6,
        0xE3346750A5B59b6cbB9102Ff3C05a756C377BE9A,
        0xC536145940315B7c2D2e9380b59cAa6d311daEF4,
        0xA27Bfb24F0cA393d3F562fa0B07ef68A7a3e496e,
        0xd2f8d886C19D3bd783a5E311a5035a57b2F6Cf44,
        0x92360Bef03Bb7c6EE017C98eE1AEd5C859965Ff3,
        0x83a416Ad90A8FE242ed495897FD7cb8B5567A318,
        0x09e54215015c0ad924128E90CD625aF0cF3ad38b,
        0xA2e731DB15098a4aaCef51Cf8b7759094BF1564B,
        0x32D82825Fe32dDC5E98B85d523d4beab16e5e8f1,
        0xd87630778D564E2ebD3B3551B026dB1fa29CEcad,
        0xef1177c6d6A9e1FC0D360289323DB6DE1145A194,
        0xdccDD925271508d24137c084092CC21A5cd59749,
        0x17eb9d536300F1506585184019A391321Bd9c2C8,
        0xf42351cE647C79aA2d97082daf73D1cc9fE9bF2C,
        0x254C19b280A5A938186B7066B5d47464CBBC1C80,
        0x27ac31c7b573df4015827133C1fc414549EC8A64,
        0x581896bcEE77DE0028D3EF6dA37FDdC496b380eb,
        0xC9Ee3563face2B242a24A5326F1596b30875f77C,
        0x1C3f7eEE6De019E85F4dc09C4ca501141af6c13c,
        0xb6F33C2586b75B6F01eB0aF65349cd9ce5a4c482,
        0x8D0080e604FB1bA7A13c071F4BF5e1C0c60946a7,
        0x09Bf493f58C7B2d9E0CA0534d6941A8Fc728E3ac,
        0xE0086584d67Fc3eA73555f1D84C8ea8AD60Df6F2,
        0x3731584c211f23F9574D5b2107DF3C75268F3B67,
        0xfA308d2800259714CeB69bb12F6cCEEA12b5752A,
        0x84aae58431D783E7976D2a994a03d35c9a28C5cA,
        0x9537700CdcF6023b9175A1B185F1Ec6dfC8Cfc95,
        0x7325c2900d7620D173458241b8dE5444fe58Db50,
        0x46D95954dD98B03820c69a7e85E1631A2d3f0425,
        0xeB3688a6cF5f25Dbc6F3be4e8a38eF6cE5F8a64c,
        0x0619FC41C9990E95AFc140e459A3dD0dFA5f40D8,
        0x588f12F97f4E97D26d309309AE0Fe96412627C2c,
        0xBeb6efc0D779EfaE8735f6c7ABB79f01107FA4cf,
        0xC9a737b5389F157aA1251953D77fb16e9c2Cf0c6,
        0xF7Ce845FE195E892760388912403Df5039Efb75a,
        0x28d5Feffd8883079E615DF1e1E68DA73f9EeA8cB,
        0xC5470eb81b520b42fd026Fb481bF1FA996DCA006,
        0x7707a6dC67444927140A9e3d01779f58997f4ce3,
        0x608041a806688da55Fb6ff92c4418eD878788ff2,
        0xa878B20383eFC0ae170399e5e0ef28A27418cfe3,
        0x31c7491950c769C7E376Eb395d042D1d4FdC704E,
        0xe18Bcc7c71b898C587483c3D64F1729d997C2f8D,
        0x91688C607887AEA2C4EC46A832052936Fb4c1bEF,
        0x9E3e9706331CC0c0FEC1F185aFb0660c581c85e7,
        0x0D8a29852A4D4aC35E4cd4EE0FBcdEb947846252,
        0x1014380e4790951D41bed27478141c29fc31200d,
        0xD1f5067Ffb98BbD1ebb624E946D12Cfd42695F0b,
        0x2830F76F087Af61E54E0000018e1573823FEda6c,
        0x54Bf88e4CD31FA9872545f0d069cB47d4648dC9E,
        0x9700E9b9B1ae81A59c871BfE6A4d83F0E5056e1B,
        0x70736C99F6b315b5b1fc435738BdDC6A93752eE5,
        0xeA2Bf14dAA8b854718c47e4984637b4D7D3A9c86,
        0x5367Ff3529C8c7319C3d62D480741878E18367f4,
        0xDff6320b49b149B3619E2E285266E313cBAdCEb7,
        0x614A8244B356a4D94F88E39486C12ad1aC22E4C5,
        0x682434353e84C9A4dC03bab4c1a0dE25962BF3a7,
        0x8cD3e2f5835bac886b23A1ae074d7d597236181E,
        0xe4723d74171551De943bC26Ba637811c74b75075,
        0x3f8524f494CEC3d0d0F2Fdc8EB464D26921C784E,
        0xE9f716dfDa69F5808bD2f1b0e7b30c9a017627e8,
        0xEF1cc55D98dbe2a517dBe990C4ec9C6806186f90,
        0x5E9622b1957510769F59Fe45A2e9Db8965442279,
        0xC7f72b26a69F52a4A0c7455DcDE5E25291202831,
        0x3f5247Fd57BF5502142DC4941ea34FdD31D63A3c,
        0xB7f78DC6fE0cdcEcd2FcFEFE21A4fB39E70ec94B,
        0xbf1633db9da394d774c87479C0cd1c2c67F79532,
        0x639F6C7C9Cc6B7B80B2e063eB84c81FE136E3694,
        0x612aB532BEdebd21C56Fea036490402397Ad2981,
        0xbEc143e7dBA00d8CFd9bE25D89CA3020978d7AE9,
        0x34e116f1b2A72c34a51A9a0579C52DcE8d2A1403,
        0x818A984Cb26eD5686316048ACb03Be60a232E68A,
        0x598BE9c9dE342450B7f81a6Ea5cA6CB8db5Fa807,
        0x31F6F21a2Ced7ba4965f49e04ADc0Fa2C2fcfbAA,
        0x53449Be5bE745Ac9812eedAf91d91C9c4c60d17D,
        0x2fabB7aCD046Fa1a560586132B5A19A131d0AD3F,
        0xB9EeDb6F53A4f20309CbF465F49572f22536c158,
        0x31eF6d19b6D94B95C0e343bC154f9700407cFf6D,
        0x4F012643Bb7416D8cbA711D7153264e043ed30FA,
        0xFb762e280505c541e843753da648390376FD2E08,
        0xFb762e280505c541e843753da648390376FD2E08,
        0xD1dd101bB3429D0984FAEEe197E339D1c7318FF1,
        0x76c97c86Dd77a420e0e43BFE7fb55846aCEb403C,
        0xaA3115Affba967D35783a07E3952e39c27A88B2E,
        0x2e12466d66fBc2CF1dD718Dd1d6426D4889f33b3,
        0x409B6F4709E83C527748c4b931eb050FceE1EC55,
        0x8Ad95129FE55F7FB2d270081D6fE9C5e3e3aC03d,
        0x8585845383c370AF5d415f0680Fd80D81Ee27295,
        0x55769d0411006BD2e5ec13b0Fa4B25aBbFf1Cf79,
        0x2133759FEbA9f44971E3F87482c218A6d203ff53,
        0x52Af2C5C256Fd5c17186b27f16482179C5d4045C,
        0x6eF9eA526B6Bd64167E546A26467D7fA9894E77a,
        0xc9ce9AF79a771d69041a8ca49A7e84aB229eE165,
        0xd6F09D04c69e2390A5A955677e6d2f1B7cC47568,
        0x1A5bA50a154471b8CA1063cd46A3a2AEe60CFfB7,
        0x91c5039a92ae137D40CEAa901F364aD50027Caf7,
        0x42DDf6DDe56a5BcD90B670213D067989156aa477,
        0xA95a2e96a7aCc714677bCE90ddEFd257838C7DAE,
        0xE43ef627A3381D0F200fA64B7bB6014ed7df5645,
        0x4208ec246258bec356711FDd8CACCF9A5df63e7E,
        0x1D12Cb2f83Fc002C1331285bF08B3d11461B98A8,
        0xD5BcEf68325097D597a1fc879a074aC6a51bB007,
        0xDB19a4F51436835688849A1C6e93852627E109AA,
        0x2CEc17bD69Bb44463744dD8a732E954B478E9b10,
        0x50877B3F45413CB122AC973af1B01b9c927cb535,
        0x3142E5eA6300184576e82bB68C9d3Cb016E5022a,
        0xEbE0D5f66Df52A32aB8B2cCF8D2e275449693f70,
        0xB7E694fE4B89D51ec3ddE0E32aFCb96052CDFf68,
        0x1495dD855f2F4C3A62492742cffE74f8BFbD42fc,
        0xa4169B535607e347a6807D8Cf7276E03e2043d78,
        0xcB31A25c00aA6f683DA772Dc513412B2E6622728,
        0x41a21D07B6d44AA7A69936b263B15AB313430e88,
        0x40dba13952aEB3EC8cE78571838C9fbCe4519131,
        0xa511fe8801A6F9e13e02Fa9dE3263D3CBAafa05f,
        0x77a7283262C22f1F3Ea269FC0Fa78e239326d9E1,
        0xdF160bAb4c176ED3Bd58c73D3Aee084cf1b5c9eF,
        0x0b3DFe12Bbeb3c068249Ae9412aD3eBAC3590Fab,
        0xf9eBfE2B0c205c437214A714a28903859349ceDE,
        0x7763Aaed2D43427A2DB80cC7b71124E2b70692De,
        0xCFb9c7b7387661F8072F638F70Ba0CaD5cfAcEAB,
        0xeb135B84BDf44C6105606D78b7b63872F68E8044,
        0x9443087b8Fa04D79FA475BD1779cE4672fC69eEA,
        0xC46fc7492d4003f2837b2E82Cf5cF1E991084D0c,
        0x7928cd7022e389541FD2373337afa6c5b9F98B70,
        0x085F06c6f0ff53eFB1075f76C36BDca95C53C126,
        0x49093f0aA06749CDAA63aB3b22743b52c6Cb3271,
        0xEd43e366e28388b449370f171E27CAc2AcA50176,
        0x87A20b672833eA9AEF43B483955588aC168d2aBa,
        0xD632a4416F57e8b908F84A18D851CE111966b4E0,
        0x970AA9E47c5a4278f662e870739f18982b06E01A,
        0xf0B17CA657c326F7dEAC219149402254E944F5b7,
        0x4d9B61A89cfEeBB8a7c3886334F1Fe26E5709061,
        0xaF3dB3f25f69cb77414CE6B02E895C3a3698E62d,
        0x6dC1a89F5dfD65baCf2650E4F6C4Ab52EF8C6596,
        0xB6222D49Ce48c6E390362648b00fbd7A1aFe8013,
        0x699C3f33Da71d392afdB97767801d5E6A59c67D6,
        0x8394437f6D635A8DF63e574C826297A3424FF9F0,
        0x0634288c1b2F524667c26F273FEA56Be120Be740,
        0x35c9BfECB6a551e182e5Df9743E403Ef15A6E875,
        0x3d70208baE12a9821DAc002d38d3740C578F1463,
        0xec7929DCbB91793596FDDed022307F1627FC9017,
        0x055acb1b90797996b4Fa1f7605E74b84887E3821,
        0x76D0C82D6ebc00F994e16eD8EDdA8AE6E206E68E,
        0xFEF8283C8225987B8d2Df54423214F4Fe2bF7765,
        0x330cb911AdE49B84bB3a7D3cB04334d5c34a771C,
        0x550dba5A19206Da0b21eeca6F14f79c8c3c47a5d,
        0xc55eAC912227Ee228e6e63867EA3a2bc9BB3D3f1,
        0x02f748bF0Bd27c86B3078Edbb9d548A9A1E4E580,
        0xA34ac05C96036c8422E776F559ddCac195c62C38,
        0xdF160bAb4c176ED3Bd58c73D3Aee084cf1b5c9eF,
        0x83325e9C10A54CD04f90d76d53F0b4669eDBb9C1,
        0x4b77149D3f09191b5c303D74e2c032F72F8498c1,
        0xFd8F16F5f91508aF37b2311324a626DDb5DbABA1,
        0x8c1D0548b64a920b69Fc4a3bb1006E12DF82eD35,
        0x2e4F6d6B417408Bdac14Ae490A3642C6EcC093Ae,
        0x57bA848CD616241607764647CFF6732593c409df,
        0xc43e8f1f4E09E0F9958bb296EFB9930A5e74DAdE,
        0x85621548f95C3aB812CDc83c6B3d45bDE047b063,
        0x05edbCd3645f4844938A99756B1343d37F63947b,
        0xfc856852D070f45f7F88650423Bf375710b74D7b,
        0x14196EAbcbB4052D327756ECf85DA8F0dAd08f83,
        0x2443C2331603bc0dc139C58336e8684Ad46250F8,
        0x75e34C6A1964aa3eBfF2e9E6DAC12E44cDCAFE75,
        0xc9584B94078036ed16E14E872663f3a3827191f8,
        0xA88917860A99f54E357b077680158f0Fe8E12d26,
        0x7eDA755A7D4C25705f0B94E5efb755563e717Edc,
        0x155B9352D7Fd3C9D3D99ab6EC09C5E30dDB4c9eb,
        0x1dB74ab7CED000d3bc7d50eE5a3f7bfFEC7C9C27,
        0xf9fc19e7F3b429ba634FA6FF250EfdefD20AeF65,
        0x67AC06BA59551364992f2f72A6e55E6cCFA7E3DD,
        0x791143F885f2DcAEDa1c3a55272e8d33E54a4AC1,
        0x555323425ec69B204F01F8e30ad42438f614E547,
        0xb4cAc246Eb1064C5CC3DEEfcE89f1f173e261d02,
        0xe37413a944922E3897CbEDb678d4b3c62815ffe1,
        0xCc512fEd22E36619fAA8E100D8417934319D0EB4,
        0x4B4Fb8336eD5E31Ab7908A7D62c58a6596f0e547,
        0xF56592974e5e21De2aBD3FEB35b5E9adc1Fb0866,
        0xD4A890e1abB86568a9ce939b2a306D7d69eE4F91,
        0x9Ca054A9c71E1B9c4d9dd3823503ea72689cccAE,
        0x78016Ca4c8b82d6d035016c78fCBe357020BA00b,
        0xB9EeDb6F53A4f20309CbF465F49572f22536c158,
        0x7bEb392B5F4ed706906667100EF4c7718b3831Bd,
        0xC68b27bB01c5c35Bb5177cb66D83530198f25d27,
        0xF1d60ce578Fb23F0Cf5aedbC070b7a64E4AA1b2b,
        0x6B7cD0e3ED9715A2502494774046e1ED8ae25AE1,
        0xE3BE79144c8491549726Dd47eC2168e2fD7D7052,
        0x100465526b101A9428AA4422C6a6F108D9d2E86e,
        0xFb11833C5948f61759813EE0C60c3f17CBe4CEa7,
        0x30e0Ca1BFbCA2142E29526D06a04eA8Ec5482cB9,
        0x55283d90c9DAE76571a7B5a4B3a78c03EDd6D9B9,
        0x746ab24092123E6d6cBF01f37b7577aFF3358748,
        0xe6649bA13d2195430625fb5c75f7A8338653B899,
        0xC5368dbe4A8CD373c0eaFBF9E29ad577599Ac86A,
        0x7310B9A6bAcFc3b26752FA952c09943F7A9688Ab,
        0x1106e81DD949E62A0A33929dAeE8401CCe1e5AeD,
        0xFc9EEC12C7c2584E4F9c88780122380157E3361a,
        0x5eab5358C616B1c99F9DAa5D0Af8A744276a5929,
        0x30feD75FF31591f89Ea5d8AC6Ca404A3e522b7f6,
        0x06e0AB8EB9cA8cF9D362E9fA090624aAf46291A9,
        0xB279B279fc88d53390eC63B8c9c29c642d568491,
        0xa7AD0bC581f23df709c6A598AfAb7145900E4494,
        0xbf3d8a32C14DF3b6aE9d0444b4D8DD7d1d7a9cB6,
        0x51876b77A58B6afcbD699d95143B51c949Ff9EBA,
        0x49F0441c19432A8D513758EbA37C2dB03995D9c2,
        0x48116616E768cb2ccf933BcE172dbCE9F6d9a4ed,
        0xaF2CAE5b41b522FE4aDba98aaD79b8bF3dF7e787,
        0x390B045a02123aE53Ec7d48Ff4a335Ba56a71Ab7,
        0x83B9E3A3e7C1F7B2738ACeC07529D91ecD55B05D,
        0x2641601e8230F6F4ffbF04577C081d16050E19BC,
        0x1fe88bD2690eA31eFb91AFB09E93c0963fbeBFD8,
        0xe7387b044E872CD1B08D7f02C4CC052747211236,
        0xE3C84eA82874cE9E02954eEF2119E5298df4e0Ad,
        0x1E3a809fB7FC19Fa6826Ad3d59aE9119c10605A3,
        0x88DfE1AAF3656309899d8DaC4056c1c32e46E597,
        0xDEF5c15Cfe72f99Bf06a8A6269614E89b77EF072,
        0xDD3Fdd44626698b0B1179Edd6930d2790CEE64B3,
        0x3fE9457922D2e8E1c7C0c379F667C668C6E2189e,
        0x95151fa406Ba9A5cC9f463Cc211F135cB01124f8,
        0xbF6B0E830d770Bad5e20F7f0Df82Cf90BEE51ACf,
        0x7b7B52ff3A5342B6938B2913ba05d818C30F88F6,
        0xFA33D5e9A03984260036E000832391925d5627FA,
        0x76AD5bbce4Ca48F3e6ad7d93959C6b549fF88ebD,
        0x1F725557F4F21093A2F39471Cd7BA77c73F703A6,
        0x28675681aAf7E31bc7FB74E923fAf540ED6ba445,
        0xA329dc8B10b98Ca67DeDEe76bBAEF57FcBbdb5A1,
        0x4526B09df42775975a543e0E984172Ab202b4Ff8,
        0xCd8Ceb90f34f1fe03f384ef33aCB386F45872297,
        0x447970dE34b3BB18D6F7c2D07d5D15D6e3E3249D,
        0xfE4dfFe4cfE50D932920824E38e97540e6e88ae8,
        0x8C18EE90bFF40FDa7a5801B08816658c243186F0,
        0x8C8EaF5Cd9487CD9bA90bD42F1292E7f6aa40AfC,
        0x42De8F255C207dC18F0850E1eFb8e1318f667E0D,
        0x91B47c35098B52D6a8325668e59bf9483f36fEC6,
        0xE2117d556F23df3d26eb9c79757e47B4607f0966,
        0x66B33937624Cb80329BCE31F5b3E734fd73b79b5,
        0x15D8fc70f2326F6FacF1c7e87B014a814F149919,
        0xf5d60bA2757491C891A1362Ad26ED460FbCF32A5,
        0xc6906368543E97F7e11D6f26aB7935830a4152be,
        0x3328A363f5b1d111be13773dA9F9ADc64B25D4BF,
        0xD4Cfb9925b37999795952Ef1b9E7A92434112ec8,
        0x96C995bDBba467608A35686265749243C8c51e14,
        0x8A623E5c75BD0b65305624b7b23E9F9b38473A4D,
        0x0b4Cb562806E535c18B5a8481D01a8FBf851AA30,
        0x566E75bb816e3147eaD414feA9b71F6efbDB1376,
        0x5d78dD564d4a94dD6C76848dE07d700B7Dc2dd42,
        0x6b8707271AB9b2CD2CdE5519E48e1F9aFB84FE7B,
        0xeD65A36d5EbD6e89a61db3B0ae7BE590b93fC560,
        0xcae07dF74E103700e6Fe2FDee3E8A9CE6836EBdd,
        0x25c0Eb04eC90E79c983C60fAF9933a90E05e7A30,
        0xbAc3b90e0B9c8777Ed184c2d881159dEE687Ce1a,
        0xB89cc3161A81beF03CF864e1B8Adf3B70546587F,
        0xA9f769B32323041850Bd6A8a79c1C3ED8eCdB34d,
        0x2e12466d66fBc2CF1dD718Dd1d6426D4889f33b3,
        0x09c058E919b8923A24a4677a1Ef267E5D8E4084e,
        0x45dAFCCd09216A8c3Be30587BFDBBd8E1ceB9356,
        0x2F5fb83711c3F27e9CcF9D38165B86A412EB7A2E,
        0xe7387b044E872CD1B08D7f02C4CC052747211236,
        0xd46a7368ea1f42c49Ffd1832eFB1ca6F6f4f28eD,
        0xE03A7587C9faAe452F27671e942Ff1DE5a358256,
        0xD2b72478108e59c7A39cdb541738dc79522674C0,
        0x7C691080EFA81cE1A27A414Bc65F60FEAA99C089,
        0xd70C97AeD47dc922F94D249058314A9D3e67cBdb,
        0xc84e5961F4DcB5F8e7d681A2f6A98D4b3F1d0334,
        0xE442d910fE795484D2561775a952880aca7EA5bA,
        0xB4e374314d899316A6447e054d844d4ed4Cf13d0,
        0x08Ea54122C0FF2A76E9bD455762C170Ed27DE8C3,
        0xe7bCe9b521274e947f901fec946f6BcE713BECc3,
        0x2e4F6d6B417408Bdac14Ae490A3642C6EcC093Ae,
        0xb43051f89307855908da5fB4e12f6ae975F455A4,
        0x2A069DA30407a64cE2e274Efc45542D6566B564a,
        0x500CE51FeE3C714773F59a13e772B0F7823Db5b0,
        0x25EBF8b2b3e4F872cd48639b6958cEC31304cEe9,
        0xac201888aaa3866B1B6a5EAd3058057B9E827168,
        0xB1db34bECb617656c9691623f59A98E10be033A3,
        0x55c9A76bF8DB7387F86b81e953E4320b9a7c032c,
        0x99fc735cF3C9EB68879fB4bE3261496Bc236a3B5,
        0xf38693fa7a41fBCE094791e204Dd0FB8793CAD0e,
        0x1FC014c5206b70D95488A805C1ABe4fAa6bb0763,
        0xC1381aC11867Adfd0609FE3eD4ed824A866C432e,
        0x439D003ac7E79236AF9870780E02E021Ab2ab72C,
        0x57D8a3cD9C7ef4C4d5A01e9D35D4Ce2ED59af04C,
        0x86da0aBd8Cad883764De448699c4A01092D3a015,
        0x86da0aBd8Cad883764De448699c4A01092D3a015,
        0xC1a8B81b880D65F5778Aa628605E928670A5f57D,
        0x082E005fA0D507199211C7E22fB057cb00b33eD0,
        0xb5C0186B5faFc58c2fEDaD716Ce3D00c599a1133,
        0x9B9A0fc1B0F0BdebfF8519DE85910A2EF11F752d,
        0x616d2b48CCD564f33A7EC1a215ca658C2686Df4C,
        0x80bEd5cA5ef4614fc20e820851A04784A31d5969,
        0x8496cF298C09c1EBfe7c9813304c3511eE82B0aD,
        0xf3dbe5890F930704FB2Fec85e45756b22AF36353,
        0x8636f1Bb7799486b3E8C704B0A7792641470B131,
        0x2F8b788eB0616daB8F2b22C6e377e25a6e92de66,
        0xe0Ecce6515f8b366aa120480C231AaAFda4B21d5,
        0xdc9ed7193b2516C84cB73f7F076426165c0ab459,
        0xcA71300C7b92274d8D0bdcf8264aF98F514e7A89,
        0xCD19b36e94Aefc0465FBB7D1f133BeEedaDF9dd2,
        0xD3af7e66dbD95a4366BF17775Ab858b3B8032316,
        0x1dd6899DBC3a5aE89b024C6e056B9B5Fad657816,
        0x7EB09FD8f090e04F9d49E3aC1Da7a05D52c235fF,
        0x644EeBDd4E5bCcc7612861A5a406449d4BfF8c32,
        0x48cA387945c9cB7fCA34635bEbD51F508Be9992D,
        0xF42f002e0082582effFcb3e2aFC38617d4A54Da9,
        0x5E66E82122b858349A1F2B4b543fe33D2B73ca11,
        0x2D2BC79B591bcECd15Be3d268C8B4Cf413009234,
        0x86DfB63c002BAd7FA9d553DCC0dE6f0Dc0227b87,
        0x38C94f2415e97A0a22EF9f518db1D3af96fdb9D5,
        0x63798e3B351f04a7d8cCf739C5c12855f55f5DB5,
        0x6E5F8785A2D87A986748bA2bd2D05d0b208e8df5,
        0x982DDF654ef2B438DC009a7721b84DdE8faA0686,
        0x9DeF0A0880F25DA5E8B7527464eB9D4D5a2184A2,
        0x54E3ae2C3Ba2808a21A34914f017749830712d63,
        0x9a9ed4D4Da3304cce514aaac08CfEcc654C7E05b,
        0x1b2F1b1542234CC20F3e1e01eB6827BDfd2e3388,
        0xd73422AD72c77c278Abe29B295B6C2782FE8Ef80,
        0x1647C45c71584F76C2EB27Ee210Ae81A193ccF50,
        0xF915A71E1B6144a2a893Ac00b49cC8eE79A0e1aE,
        0xb9Db63531686eb4363C8463d37aDBaC1dEB7d03B,
        0xc5045AacA5F759C543cddf91CF14Ee0cd76A3811,
        0x378E0B5a96Ab28a088dCc674f4D14a576D957453,
        0x577bb0C8fdAdE7B99ff6d02d15CD9360572ac968,
        0xf1A352A0047149a84E7978d83db172884eaee72d,
        0x04de12bB7498BAf75E31e6358ADE440B0fCA1923,
        0xBDe9ca5940bfc9F3521D762310710bCB951D76da,
        0x871b7E6637e50B195907550AB15A7F7797856a6a,
        0x927131BB01B391BbbC25bfbaeE3f826257FcBE20,
        0x55cc409d435161CAB80eEdC323210c149b94A4A5,
        0x4511BbeF15bC4aBB8c19283918222bbA9b024b9c,
        0xdb14F464694D7AbAEf61c104C3c78D1C7d42Cf2C,
        0xC9c5AFF21194b7284973fDc9e83acDE941aD06de,
        0xFE399189E358ED5f67672364f70f509c87fD565A,
        0xf2F7B38dC62175F143e75f70aB3A760268AF8D74,
        0xfA52DE8bB57C3D411A4d2D674526cB7F33aE9aC5,
        0xd347843C2867C04F9331427e700065701c26D84D,
        0x5D2568A9daB4043c14A426c50Ac6C5062bD8963b,
        0x55eE199C210b11896E70a0e4062bB488A13E566b,
        0xaA18f3a193bfb207633a92102c7c1d7231707b61,
        0x2e4F6d6B417408Bdac14Ae490A3642C6EcC093Ae,
        0x1175DB298b7a01A5aD6c7aF193C419514309c3fA,
        0xE0395059A3648Da1DE3c25735172a82b5511e39D,
        0x5d52bfa9bB85142a3902ce3717777d2EAAaC2f99,
        0xFF78EF6f0cBFCEef3E4AA862103bb48066AFFfD9,
        0xFF78EF6f0cBFCEef3E4AA862103bb48066AFFfD9,
        0x5aE7bdc89187B80dd636882b7b2fd08A45A4F16D,
        0xc5443158351061aEeCd2FBBFF9aF51Af8045418a,
        0x77c9E6678cFA64730982fBc70C55420eFCbC5Ee4,
        0x3E62889C33E4D7BE852C586d80A9f3E64554082E,
        0x9260fd6B8B2c3A5c9963Ce6f9707D8A1030F7A65,
        0x5EdfADf3BEf59843E7A8762FcA325C00DaA26819,
        0x881309D27b74A660cAddE7d443Ae0002E59BC248,
        0x8FB22E2E4187E5D0c94D4a595ed4767AE8e6aE4D,
        0x9fC79295DBeC52d35a2e56E41816adC40e355e2e,
        0x5e6e88d55b84612651f7670bA2e23018F71E6489,
        0xd5f95DcE2A052972f5dBAb8699c07A8b9eb26968,
        0x89d1006F035Bc7d7bfB6DA8D440eE9A6d0eD5B08,
        0xa306777951FF7D58cFa3dAD9DA1e3Ed55d0fEC38,
        0xfF17Eeb738E9Aeee448A7FC601fCa09498832eda,
        0x3e5dc2e9db1fBf06562B02d8cC70aE62F2F6BaE2,
        0x25c0Eb04eC90E79c983C60fAF9933a90E05e7A30,
        0x2F6d40D46E8ADF77B45b29CB655bCe4Ec59B3AE8,
        0x72627E544DFed699441323cEd59dd64c257a8415,
        0x81F78Ed2Af0EE64F556340F1Da41EF99b3085c4A,
        0x52425a66912beE251D29cFD7782B4cD29c0Bc705,
        0x8c5EBeCef7aFaBf398Abf5fDfD59b4e0D21257ab,
        0x90338d54e8218A8D34f0BB92D9B5faE69bd7F086,
        0x8441F36f5FDB944D9e137B059f75b7b4C3833D7D,
        0x00be53118D94832C963f95CE2F3d9e49c1275B29,
        0x563fF6177A4f57bFdfBAE290143c4c5C53Fa185c,
        0xF61524BE6CEEE9D93C410b80f4a1ba0538f5bfaE,
        0x963e4ebe08Ce75adD6Ea4CeE71D6E6D3730C9af7,
        0xB8Bc30Cce75b2AbD93A443382aE9dCDEB803c852,
        0xB39053b5455520e1990550aEB90da91AAdBb66c5,
        0x7fb3bc300544618b471974e5A5D87289144F6165,
        0x1bFF8Eb09d2bb993448DF3D7E9bE2b1B80029F13,
        0x235F07Ed1201238a99988B0b9DAa438B015B428E,
        0x3584636171540C6136295f55C6E207Bd144D496D,
        0x317688E097e7705EFdC20DA53F11996EBa94c703,
        0x4460D0CbD5e4828709271CaAA5e697495d34fF54,
        0x7874478e911e511039fEc0b5854f7952aA76b629,
        0x7E8D8f5a721770aD17D4d2765c244f7f93b65De8,
        0x3234B50d8599Ee8bcA2E620704e768444B9E8b6b,
        0xb2e7378836d717E2B9125Bd4708eB8DEd1a0cC91,
        0x1343E3BC359aD840951ECd75fE135dc650E47556,
        0x53FBc737fAa98421927529F00D700BEA5bF25a7e,
        0x5B3b55f2E1420f746429365171615A3Eb9951A23,
        0xE442d910fE795484D2561775a952880aca7EA5bA,
        0x2A069DA30407a64cE2e274Efc45542D6566B564a,
        0x0b225CBFc58F532E91Aa1b2CBaC491738e8ACbCd,
        0x797b00ff517Ed9b755E8039ee092ba9D1890B9AE,
        0x59237E1C8423e18B2616f14Cb4AF94F999a8952e,
        0xAbF56ee1E6B127541dAfcF1c233C7EE2f3D0a4bf,
        0x9e246d61372fFcB52f85adDe239B782be2dcbB39,
        0x4622BeF7d6C5f7f1ACC479B764688DC3E7316d68,
        0xe26F54284C451EC4C0F65eb973F737f7962a5a3b,
        0xdf11aD176FED9244551B5Ce5b4EF1427ED1E7abd,
        0xfFaD8E0443b882Cb18715333dAFc514b98D9DF49,
        0x39Af6Ee6eaFfcD73F3d863b02dB52F87E33C6929,
        0x354b9BEB98a04bc4Ca91189adce950257C625973,
        0x236B8f488e20b2652d222F1087A8237957105451,
        0x388CBeEC5a031E4AaD12599b04A4aa4f088e0F73,
        0x28A1b6A3ea26fcE04E1EF889d27ad34845FfD31D,
        0xB81E38d83853618a4958B76A097A1DeA507ac963,
        0xaB4866840d5887Cbd73A0275FB908A4ACc020718,
        0x52EB2DA18023823D00e56D7340C169A06493Aef7,
        0x8ECa8b624cEa7Fb0Ce4FDc828AE4fA3d8d99534B,
        0x629f47A286f7F46Cfaf0ec8C1FE31515C9E573D4,
        0x29825fB8a960c37C52e5464C8053494Fe76Ce63d,
        0x818A3498B99B3ab3eAD9A61dcde2d03fD6698240,
        0xb2B3895Af0238E6a316E6Eaa9F532E1cd1EcB484,
        0x8Ea831b5EcdA009aFbd12B0c3bc6f8473866b0A1,
        0x48DA824B94dAA2ec49b374fC0B1b1B0d00578870,
        0xE442d910fE795484D2561775a952880aca7EA5bA,
        0xba7fD88Ce369E723205aA2215d5C02577b75B86E,
        0xf288D80ABD3add02B2716e3D90C29729Df72863A,
        0x780e47E8C220b53e90E379505558529C296B2C52,
        0x02634D19b82A19Fe1C53e995C5F3c1D6B22c2776,
        0x916AF1F7156E5aBeb49be7C13BffFE75baCc916b
    ];

    _contractOwner = msg.sender;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
   baseURI = _newBaseURI;
  }

  function setFreeMintPerAddressLimit(uint256 _limit) public onlyOwner {
    FreeMintPerAddressLimit = _limit;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function isOnlyWhitelist() public view returns (bool) {
     return onlyWhitelisted;
   }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setAllowAffiliateProgram(bool _state) public onlyOwner {
     _allowAffiliateProgram = _state;
  }

  function setAffiliateProgramPercentage(uint256 percentage) public onlyOwner {
    _affiliateProgramPercentage = percentage;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
     maxSupply = _maxSupply;
  }

  function setWhitelistedAddress(address _wallet) public onlyOwner {
    whitelistedAddresses.push(_wallet);
  }

  function setNftEtherValue(uint256 nftEtherValue) public onlyOwner {
    _nftEtherValue = nftEtherValue;
  }

  function setAffiliate(address manager, bool state) public onlyOwner {
    _affiliates[manager] = state;
  }

  function setIsFreeMint(bool state) public onlyOwner {
      _isFreeMint = state;
  }

  function removeWhitelistedAddress(address _user) internal {
    for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          delete whitelistedAddresses[i];
      }
    }
  }

  //################################ GET FUNCTIONS #########################################################
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

    function getQtdAvailableTokens() public view returns (uint256) {
      if(_numAvailableTokens > 0){
        return _numAvailableTokens;
      }
      return maxSupply;
    }

    function getMaxSupply() public view returns (uint) {
      return maxSupply;
    }

    function getNftEtherValue() public view returns (uint) {
      return _nftEtherValue;
    }

    function getAddressLastMintedTokenId(address wallet) public view returns (uint256) {
      return _addressLastMintedTokenId[wallet];
    }

    function getMaxMintAmount() public view returns (uint256) {
      return maxMintAmount;
    }

    function getBalance() public view returns (uint) {
     return msg.sender.balance;
    }

    function getBaseURI() public view returns (string memory) {
      return baseURI;
    }

    function getNFTURI(uint256 tokenId) public view returns(string memory){
      return string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseExtension));
    }

    function isAffliliated(address wallet) public view returns (bool) {
     return _affiliates[wallet];
    }

    function contractIsFreeMint() public view returns (bool) {
     return _isFreeMint;
    }

    // function getAllowAffiliateProgram() public view returns (bool) {
    //  return _allowAffiliateProgram;
    // }

    function isPaused() public view returns (bool) {
      return paused;
    }

  //######################################## MINT FUNCTION ###################################################
  function mint(
    uint256 _mintAmount,
    address payable _recommendedBy,
    uint256 _indicationType, //1=directlink, 2=affiliate, 3=recomendation
    address payable endUser
    ) public payable {
      require(!paused, "O contrato pausado");
      uint256 supply = totalSupply();
      require(_mintAmount > 0, "Precisa mintar pelo menos 1 NFT");
      require(_mintAmount + balanceOf(endUser) <= maxMintAmount, "Quantidade limite de mint por carteira excedida");
      require(supply + _mintAmount <= maxSupply, "Quantidade limite de NFT excedida");

      if(onlyWhitelisted) {
          require(isWhitelisted(endUser), "Mint aberto apenas para carteiras na Whitelist");
      }

      if(_indicationType == 2){
          require(_allowAffiliateProgram, "No momento o programa de afiliados se encontra desativado");
      }

      if(!_isFreeMint ){
        if(!isWhitelisted(endUser)){
          split(_mintAmount, _recommendedBy, _indicationType);
        } else {
          uint tokensIds = walletOfOwner(endUser);
          if(tokensIds > 0){
            split(_mintAmount, _recommendedBy, _indicationType);
          }
        }
      }
      
      removeWhitelistedAddress(endUser);

      uint256 updatedNumAvailableTokens = maxSupply - totalSupply();
      
      for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[endUser]++;
        _safeMint(endUser, 1);
        uint256 newIdToken = supply + 1;
        tokenURI(newIdToken);
        --updatedNumAvailableTokens;
        _addressLastMintedTokenId[endUser] = i;
      }
      _numAvailableTokens = updatedNumAvailableTokens;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

function walletOfOwner(address _owner)
    public
    view
    returns (uint)
  {
    return addressMintedBalance[_owner];
  }

    function split(uint256 _mintAmount, address payable _recommendedBy, uint256 _indicationType ) public payable{
    require(msg.value >= (_nftEtherValue * _mintAmount), "Valor da mintagem diferente do valor definido no contrato");

    uint ownerAmount = msg.value;

    if(_indicationType > 1){

      uint256 _splitPercentage = _recommendationPercentage;
       if(_indicationType == 2 && _allowAffiliateProgram){
          if( _affiliates[_recommendedBy] ){
            _splitPercentage = _affiliateProgramPercentage;
          }
       }

      uint256 amount = msg.value * _splitPercentage / 100;
      ownerAmount = msg.value - amount;

      emit _transferSend(msg.sender, _recommendedBy, amount);
      _recommendedBy.transfer(amount);
    }
    payable(_contractOwner).transfer(ownerAmount);
  }

  /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
        emit Transfer(from, to, tokenId);
    }
}