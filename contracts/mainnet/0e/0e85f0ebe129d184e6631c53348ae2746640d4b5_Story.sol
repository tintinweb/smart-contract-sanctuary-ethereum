/**
 *Submitted for verification at Etherscan.io on 2022-08-13
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

// File: @openzeppelin/contracts/utils/Base64.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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

// File: erc721a/contracts/IERC721A.sol


// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// File: erc721a/contracts/ERC721A.sol


// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;


/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
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
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
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

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
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

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
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
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
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

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// File: contracts/StoryDeployLogo.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;







contract Story is ERC721A, Ownable, ReentrancyGuard  {


  struct StoryStruct {
    uint256 tokenId;
    string tokenText;
    uint unlockTokenTime;
  }

  //  create constant variables here at the top
  uint256 public maxSupply;
  bool public isPublicMintEnabled;
  bool public isAdminUpdateEnabled;
  string internal baseTokenUri;
  mapping(address => uint256) public walletMints;
  mapping(uint256 => StoryStruct) storyData;
  uint public startingPrice;
  uint public discountRate; 
  uint public startAt; // start time of dutch auction
  uint public unlockTime; // time until next dutch auction starts
  uint public lockDuration; // time to lock between each auction mint

  // events
  event StoryMinted(uint _tokenId, uint _price);


  constructor() payable ERC721A('Story Block', 'STORY') {
    maxSupply = 888;
    isPublicMintEnabled = true;
    startingPrice = 333 ether / 100;
    discountRate = 115625000000000;
    isAdminUpdateEnabled = true;
    startAt = block.timestamp;
    unlockTime = block.timestamp;
    lockDuration = 30 seconds;
  }
  

  string[] private birds = [
      '<path id="0" d="M81,84.5c5.3-3.7,11.2-4,17.2-2.7c8.8,1.9,14.2,7.5,16.4,16.2c0.3,1.2,0.3,2.4,0.3,3.7c0,0.4-0.3,1-0.6,1c-0.4,0.1-0.9-0.2-1.3-0.3c-0.2-0.1-0.3-0.3-0.4-0.4c-4.2-5-9.4-8.9-14.7-12.6c-4.1-2.9-8.3-2.5-12.6-0.3c-0.7,0.4-1.3,0.9-1.9,1.5c-3.3,3.2-7,4.9-11.7,4.5c-2-0.2-3.9-0.2-5.9-0.4c-0.5,0-1.1-0.4-1.3-0.8c-0.4-0.6,0.1-1.2,0.6-1.5c0.5-0.4,1-0.7,1.5-1.1c1.1-0.9,2.2-1.8,3.4-2.8c-0.5-0.5-0.9-0.8-1.3-1.2c-4.4-3.7-9.5-4.9-15.1-4c-4.6,0.8-9.2,1.6-13.9,2.4c-0.9,0.2-2.1,0.8-2.7-0.4c-0.5-1.1,0.6-1.6,1.2-2.2c5.2-5.5,12-7.9,19.2-9.1c2.1-0.3,4.1-0.7,6.2-1.1c1-0.2,1.7,0.1,2.5,0.7c3.4,2.8,6.4,6,9.2,9.4c0.6,0.7,1.2,1.1,2.1,1.1C78.8,84,79.8,84.3,81,84.5L81,84.5z"><animateMotion from="-150 0 0" to="500 -23 0" dur="11s" repeatCount="indefinite"/></path>',
      '<path id="0" d="M31.7,86.6c1.6,0.2,3.2,0.4,4.8,0.7c5.6,1.2,11.1,1,16.5-0.9c4.4-1.5,8.9-3,13.6-3.5c3.5-0.4,7,0,10.4,0.9c2.4,0.7,4.7,0.5,6.8-0.9c4-2.8,8.4-4.1,13.3-3.8c3.6,0.2,7.2,0.2,10.7,0.6c6.2,0.7,12.2,0.2,17.7-3.1c0.3-0.1,0.5-0.2,0.8-0.3c0.1,0,0.3,0.1,0.6,0.1c-0.3,0.4-0.6,0.9-0.9,1.2c-4,3.1-8.4,5.4-13.6,5.8c-1.4,0.1-2.8,0.1-4.2-0.1c-5.5-0.8-10.6-0.3-15.7,2.2c-2,1-4.4,1.5-6.6,1.9c-1.3,0.3-2.3,0.5-3.1,1.7c-1.2,1.8-3.1,2.5-5.2,2.6c-2.9,0.2-4-1.2-3.3-4.3c-0.5,0-1,0-1.5,0c-1.9,0.1-3.7,0.2-5.6,0.2c-3.8,0-7.4,0.5-11,1.5c-7.8,2.1-15.5,1.4-23.1-1.2c-0.6-0.2-1.1-0.5-1.7-0.8L31.7,86.6L31.7,86.6z"><animateMotion from="500 0 0" to="-150 0 0" dur="13s" repeatCount="indefinite"/></path>',
      '<path id="0" d="M68.4,90.3c-1.1,0.6-2,1.1-3,1.6c-0.4,0.2-0.8,0.4-1.1,0.6c-0.5,0.5-0.4,1.1,0.2,1.4c0.4,0.2,0.9,0.3,1.3,0.3c2.4,0.1,4.9,0.3,7.3,0.2c1,0,2.1-0.3,3.1-0.7c1.3-0.4,2.3-1.3,2.9-2.6c0.1-0.2,0.3-0.5,0.5-0.6c2.4-1.5,5-2.5,7.9-2.6c2.8-0.1,5.5,0.5,8.1,1.3c4.5,1.4,8.7,3.3,12.9,5.3c2.1,1,4.3,2,6.4,3c0.5,0.2,1,0.4,1.5,0.5c0.2,0,0.6-0.1,0.8-0.3c0.1-0.2,0.1-0.6-0.1-0.8c-0.2-0.3-0.5-0.6-0.9-0.9c-2.3-2.1-4.6-4.3-7-6.4c-1.6-1.4-3.1-2.8-4.8-4c-3.2-2.4-6.9-3.4-10.9-3.3c-3.2,0.1-6.2,0.9-9,2.3c-1.7,0.8-3.4,1.6-5.1,2.4c-0.6,0.3-1.1,0.3-1.6-0.2c-0.4-0.4-0.9-0.6-1.4-0.7c-0.9-0.1-1.8-0.1-2.7-0.1c-0.7,0-1.4,0.2-1.9,0.3c-0.8-1.5-1.5-2.9-2.4-4.2c-2.5-3.7-5.3-7.3-8.3-10.6c-0.2-0.3-0.5-0.5-0.7-0.7c-0.5-0.5-1.1-0.6-1.9-0.5c-1.6,0.3-3.2,0.7-4.8,0.7c-6,0.3-12,1-17.9,1.9c-0.3,0-0.6,0-0.9,0.2c-0.2,0.1-0.5,0.4-0.5,0.6c0,0.2,0.2,0.5,0.5,0.6c0.3,0.1,0.6,0.1,0.9,0.2c3.6,0.4,7.2,0.6,10.8,1.4c5,1.1,9.7,2.9,13.6,6.4c2,1.8,4,3.7,5.9,5.5C66.9,88.4,67.6,89.3,68.4,90.3L68.4,90.3z"><animateMotion from="-150 0 0" to="500 0 0" dur="13s" repeatCount="indefinite"/></path>',
      '<path id="0" d="M85.6,89.2c1-0.7,2.3-1.6,3.6-2.7c4-3.4,8.6-4,13.6-3.3c4.3,0.6,8.3,1.9,12.4,3.2c0.3,0.1,0.6,0.2,0.8,0.4c0.6,0.5,0.5,1.2-0.2,1.5c-0.6,0.2-1.2,0.4-1.8,0.4c-5.5,0.2-11.1,0.5-16.6,0.6c-2.8,0.1-5.4,0.5-7.7,2.1c-0.5,0.3-1.1,0.7-1.7,0.9c-1.8,0.7-3.3,1.7-4.2,3.5c-0.6,1.2-1.8,1.9-3,2.4c-3.9,1.5-7.4,0.4-10.8-1.4c-0.9-0.5-0.7-1.4,0.2-1.9c0.6-0.3,1.2-0.4,1.8-0.6c2.7-1.3,3.2-4.5,1-6.5c-0.6-0.5-1.3-0.9-2-1.4c-2.3-1.6-4.6-3.1-6.8-4.8c-5.7-4.6-11.6-8.8-18.5-11.5c-0.1,0-0.2-0.1-0.3-0.2c-0.6-0.3-1.2-0.5-1.1-1.3c0.2-0.9,1-0.8,1.7-0.8c0.9,0,1.8,0.1,2.6,0.3c2.3,0.5,4.6,1,6.8,1.6c4.5,1.3,9,2.8,13.5,4.2c1.9,0.6,3.1,1.8,4,3.6c1.8,3.5,4.1,6.8,6.2,10.1c0.4,0.6,0.9,0.9,1.7,0.9C82.3,88.7,83.8,89,85.6,89.2L85.6,89.2z"><animateMotion from="-150 0 0" to="500 0 0" dur="11s" repeatCount="indefinite"/></path>'
  ];

  string[] private clouds = [
      '<path class="st1" d="M305.3,21c10.6,0.2,19.4,2.8,27.7,7.1c3.3,1.7,5.9,4.2,7.7,7.4c1.3,2.3,2.5,4.7,3.5,7.2c0.9,2.1,1.2,4.4,0.9,6.8c-0.1,0.9-0.1,1.7,0,2.6c0.2,1.5,1,1.9,2.4,1.4c0.6-0.2,1.1-0.5,1.7-0.8c1-0.5,2-1.1,3-1.5c3.6-1.6,6.6-0.7,8.6,2.7c0.5,0.8,0.8,1.8,1.2,2.7c0.8,1.8,2.2,2.2,3.7,1c0.6-0.5,1.2-1.1,1.8-1.6c2-1.7,3.9-3.4,6-5c1.8-1.3,3.9-2.2,6.2-2.3c3.8-0.2,6.6,1.5,8.2,5c1.2,2.7,1.3,5.5,0.9,8.4c-0.2,1.2-0.5,2.4-0.6,3.7c-0.3,2.3,0.9,3.4,3.1,2.7c1.5-0.4,2.9-1,4.4-1.6c3-1.1,6.1-2.2,9.4-2.2c1.7,0,3.5,0.1,5.2,0.5c3.4,0.9,5.2,3.1,5.1,6.6c0,1.9-0.5,3.8-0.8,5.7c-0.3,1.4-0.7,2.8-1,4.2c-0.1,0.6-0.2,1.2-0.1,1.8c0.2,1.7,1.3,2.6,3,2.2c0.9-0.2,1.7-0.7,2.6-1.1c1.5-0.7,3-1.6,4.5-2.2c4.1-1.7,7.8-0.9,11,2.1c0.5,0.5,1.1,1,1.6,1.6c2.7,3.1,6.2,4.5,10.2,4.8c4.8,0.4,9.4-0.2,14-1.7c2.1-0.7,4.2-1.5,6.3-2.2c2.3-0.8,4.6-1.5,7.1-1.2c1.3,0.1,2.6,0.4,3.8,0.9c1.9,0.9,2.3,2.6,1.1,4.3c-0.7,1-1.6,2-2.6,2.6c-2,1.2-4,2.2-6.2,3c-5,1.9-10.2,2.8-15.4,3.7c-11.2,1.8-22,4.7-32.5,8.9c-5.9,2.3-11.9,4.4-18.1,5.8c-7.2,1.7-14.4,1.7-21.6-0.4c-2.2-0.6-4.4-1.1-6.7-1.7c-5.2-1.4-10.5-1.3-15.6,0.3c-3.2,1-6.3,1.9-9.4,3c-7.5,2.4-15.2,3.7-23.1,3.1c-2.7-0.2-5.3-0.6-7.9-1.1c-3.5-0.7-6.7-2.2-9.6-4.3c-1-0.7-1.9-1.4-2.9-2c-2.1-1.3-4.1-1.2-6.1,0.2c-1.1,0.8-2.1,1.8-3.1,2.6c-2.1,1.7-4,3.5-6.3,5c-5.6,3.7-11.7,5.3-18.4,4.5c-7-0.9-12.5-4.3-16.7-9.9c-1.1-1.5-2.1-3.2-3.1-4.9c-1.4-2.4-2.8-2.6-5-0.9c-1.6,1.2-3.1,2.6-4.6,3.8c-4.2,3.2-8.8,5.6-13.9,6.9c-6.9,1.8-13.7,1.3-20.4-0.6c-3.7-1.1-7.3-2.4-11-3.7c-2.4-0.8-4.8-1.8-7.2-2.6c-5.2-1.8-10.5-2.3-16-2c-4.4,0.3-8.8,0.6-13.2-0.2c-4.6-0.8-8.6-2.8-11.9-6.1c-1.6-1.7-2.9-3.6-3.4-5.9c-0.4-1.5-0.4-3.1,0.1-4.6c0.6-1.7,1.6-2.4,3.4-2.1c1.2,0.1,2.4,0.4,3.7,0.6c5.6,1,10.1-1.1,12.8-6.1c0.9-1.6,1.5-3.3,2.3-4.9c1.5-2.9,3.8-4.9,7-5.7c1.9-0.5,3.8-0.4,5.7,0.4c0.9,0.4,1.7,0.9,2.1,2c0.2,0.5,0.6,1,1,1.3c0.5,0.5,1.2,0.7,1.9,0.3c0.8-0.4,1-1.1,0.9-1.9c-0.1-0.4-0.2-0.8-0.4-1c-0.8-1.2-0.4-2.2,0.4-3c0.8-0.8,1.8-1.6,2.9-2c1.7-0.6,3.6-1.1,5.4-1.3c4.2-0.6,8.4-0.5,12.6,0.5c3.2,0.8,5.9,2.3,7.6,5.2c0.5,0.8,1.1,1.4,2.1,1.2c1-0.2,1.3-1,1.6-1.9c0.4-1.6,0.7-3.3,1.3-4.8c1.9-4.8,5.7-7.3,10.7-7.9c3.8-0.5,6.8,1.1,8.7,4.5c0.7,1.2,1.1,2.6,1.6,4c0.7,2.1,1.7,2.5,3.7,1.6c1.3-0.7,2.6-1.4,4-2c4.1-1.8,8.4-2.1,12.8-0.9c2.7,0.7,5,2.2,6.7,4.5c0.3,0.4,0.5,0.7,0.8,1c0.8,0.8,1.6,0.9,2.3,0.4c0.7-0.5,0.9-1.4,0.4-2.4c-0.2-0.4-0.6-0.8-0.8-1.3c-0.8-1.7-1.8-3.3-2.4-5c-1.6-4.8,1.3-8.9,6.5-9.1c3.1-0.1,5.9,0.9,8.4,2.5c0.4,0.3,0.8,0.6,1.3,0.8c0.7,0.3,1.4,0.2,1.9-0.4s0.5-1.3,0.2-1.9c-0.2-0.4-0.6-0.8-0.9-1.2c-2.1-2.7-4.4-5.3-6.4-8c-1.1-1.4-2-3-2.9-4.6c-1.5-3-1.5-6,0-9c1.5-3,3.6-5.5,6.1-7.6c4.1-3.5,9-5.4,14.3-6.4C300.6,21.4,303.6,21.2,305.3,21L305.3,21z">',
      '<path class="st2" d="M142.8,105.4c3.6-0.1,6.7-0.1,9.8-0.4c6.8-0.7,13.3-2.7,19.6-5.3c5.5-2.3,10.9-4.9,16.4-7.4c4-1.8,7.9-3.6,12.3-4.4c5-0.9,10-1,15,0.1c2.6,0.6,4.9,1.6,6.6,3.8c1.2,1.6,2.9,1.2,3.5-0.8c0.5-2,0.9-4,1.4-6c2.6-9.8,7-18.6,14.4-25.7c2.6-2.5,5.5-4.9,8.6-6.8c12-7.4,25-11.3,39.1-11c9.7,0.2,18.9,2.8,27.6,7.3c6.5,3.4,10.6,8.7,12.4,15.9c0.2,1,0.4,1.9-0.1,2.8c-0.5,0.9-0.1,1.6,0.5,2.2c0.6,0.6,1.3,0.4,1.9,0c1.7-1,3.5-1.9,5-3.1c11.5-8.9,24.3-10.1,37.7-5.7c9.1,2.9,14.7,9.5,17.1,18.8c0.4,1.4,0.6,2.8,0.9,4.2c0.9,3.4,2.6,4.5,6,3.8c1.7-0.3,3.3-0.9,4.9-1.5c5.5-1.9,10.9-3.7,16.6-4.8c7.5-1.4,15.1-2.2,22.7-1.8c3.3,0.2,6.6,0.7,9.7,2c6.8,2.8,8.6,8.1,4.9,14.5c-2,3.5-5,6.1-8.3,8.3c-4.2,2.8-8.8,4.7-13.5,6.1c-11.9,3.4-24,4.8-36.3,4.3c-3.4-0.1-6.8-0.8-9.9-2.3c-2.7-1.3-5-0.9-7.2,1c-1.9,1.7-3.8,3.4-5.7,5c-6.1,5.2-13,8.7-20.8,10.2c-4,0.8-8,0.9-12,0.1c-6.1-1.3-11-4.5-14.6-9.7c-0.9-1.3-1.6-2.7-2.5-4c-1.7-2.6-3.5-2.7-5.6-0.4c-1.1,1.3-2.1,2.7-3.2,4c-4.7,6-10,11.3-16.2,15.7c-6.1,4.4-12.7,7.6-20.1,9.2c-9.1,1.9-18.1,1.1-27-1.4c-8.5-2.4-16.3-6.4-23.5-11.6c-3.5-2.6-6.9-5.3-10.3-8c-2.4-1.9-4.9-3.7-7.4-5.5c-7.8-5.3-16.5-7.2-25.8-6c-5.9,0.7-11.7,1.9-17.5,2.8c-2.5,0.4-5,0.5-7.5,0.6c-4.2,0-8.2-1.1-11.8-3.3C147.8,109.6,145.4,107.6,142.8,105.4L142.8,105.4z">',
      '<path class="st2" d="M441,128.3c-0.4,0.4-0.8,0.9-1.3,1.1c-1.3,0.6-2.7,1.3-4.1,1.7c-4.3,1.2-8.7,1.3-13.1,0.8c-7-0.8-13.9-1.8-20.9-2.7c-7.6-1.1-14.9-0.1-21.9,3.1c-3.2,1.5-6.2,3.2-9.3,4.9c-2.8,1.5-5.7,2.4-8.9,2.1c-1.3-0.1-2.7-0.3-4-0.6c-10-2.4-18.9-7.1-26.8-13.6c-1.9-1.6-3.5-3.4-4.4-5.7c-0.3-0.8-0.9-1.4-1.8-1.4c-1,0-1.6,0.6-2,1.4c-2.2,4.9-6.1,8.1-10.7,10.5c-1.9,1-3.9,1.5-6.1,1.5c-1.1,0-1.8-0.3-2.6-1.1c-0.9-1-2-1.9-3.2-2.6c-2-1.3-3.5-0.8-4.5,1.3c-1.5,3.1-3.2,6-5.5,8.6c-1.5,1.8-3.3,3.4-5.3,4.7c-3.5,2.2-7.2,2.8-11.1,1.5c-5.9-2-11-5.5-15.1-10.2c-0.9-1-1.5-2.3-2.2-3.5c-0.2-0.4-0.4-0.8-0.7-1.2c-0.8-1-1.9-1.2-2.9-0.4c-0.5,0.4-0.9,0.8-1.3,1.3c-2.9,3.2-6.2,5.9-10,7.9c-3,1.5-6.1,2.5-9.5,2c-0.5-0.1-0.9-0.1-1.4-0.3c-5.7-1.7-10.1-5.1-13.1-10.1c-1.2-2-1.6-4.3-1.7-6.5c-0.1-2.1-0.1-4.2,0-6.3c0.2-2.8-1.8-3.9-3.9-3c-3.4,1.5-6.9,1.4-10.5,0.9c-3.5-0.5-6.9-1.4-10.1-2.9c-7.1-3.2-11.1-9-12.9-16.4c-0.1-0.5-0.2-1-0.2-1.5c0-6.3,2-11.8,6.8-16.2c2.4-2.2,5.3-3.5,8.6-3.9c3.4-0.3,6.9-0.7,10.3-0.9c4.7-0.3,9.3,0.6,13.7,2.2c1.6,0.6,3.1,1.4,4.2,2.8c0.1,0.2,0.4,0.4,0.6,0.5c0.6,0.5,1.3,0.5,2,0.2c0.6-0.3,1-0.9,0.9-1.7c0-0.6-0.2-1.1-0.3-1.7c-0.5-2.7-1.2-5.4-1.6-8.2c-0.4-2.8,0.4-5.3,2.1-7.6c2.3-3,4.9-5.7,7.9-8.1c2.2-1.7,4.7-2.8,7.4-3.3c4.9-0.9,9.7-0.6,14.4,1c3.4,1.2,6,3.3,7.8,6.5c0.8,1.4,1.6,1.9,2.6,1.6c1-0.3,1.4-1.1,1.3-2.7c-0.1-3.3,0.2-6.5,0.9-9.7c0.9-4,2.8-7.4,5.8-10.2c3.6-3.2,7.5-6,11.7-8.3c3.1-1.6,6.3-2.6,9.8-2.6c2.8,0,5.6,0.1,8.3,0.3c1.4,0.1,2.8,0.6,4,1.2c8.8,4.8,15.6,11.4,19.4,20.9c0.9,2.3,1.7,4.6,1.9,7c0.1,1.5,0.1,2.8-1.2,3.9c-0.9,0.8-0.9,1.8-0.3,2.5c0.6,0.7,1.6,0.9,2.5,0.3c6.1-3.6,12.7-3.9,19.5-3.4c2.9,0.2,5.5,1.3,7.8,3.2c1.5,1.2,2.8,2.6,4.1,4c3.6,4.4,4.8,9.4,3.6,15c-0.4,1.7-0.9,3.3-1.4,4.9c-0.2,0.6-0.4,1.2-0.6,1.8c-0.5,2.3,1,3.7,3.2,2.9c0.7-0.2,1.3-0.6,2-0.8c1.3-0.5,2.6-1.2,3.9-1.5c1.7-0.4,3.4-0.8,5.2-0.9c5.3-0.2,9.4,2.1,12.1,6.7c1.1,1.8,1.8,3.9,2.5,6c0.8,2.7,1.4,5.4,2.2,8.1c0.6,2,1.3,4,2.1,6c1.3,3.3,3.6,5.8,6.6,7.6c1.2,0.7,2.3,1.4,3.5,1.9c7.8,3.5,15.9,6,24.5,7c3,0.3,6.1,0.3,9.1,0c0.5-0.1,1.1-0.1,1.6-0.1L441,128.3L441,128.3z">',
      '<path class="st2" d="M360.4,72.2c1.8-0.8,3.4-1.5,5-2.1c5-2,10.1-2.2,15.2-0.3c6.1,2.3,9.3,7,9.2,13.5c0,1-0.1,2-0.1,3c0,2,1,2.9,3,2.5c1.6-0.3,3.2-0.8,4.9-1.1c5.7-1.1,11.2-0.2,16.3,2.5c1.6,0.8,3.2,1.7,4.7,2.8c8,5.9,17,8.5,26.8,9c0.4,0,0.9,0.1,1.3,0.1c0.1,0,0.2,0.1,0.3,0.3c-0.4,0.4-0.7,0.8-1.1,1.2c-5.6,5.6-12.4,8.7-20.1,10c-6.7,1.1-13.4,0.6-20.1-0.5c-9.6-1.6-18.9-4.4-28.1-7.3c-4.7-1.5-9.3-3-14.2-3.8c-7.2-1.2-14.3-0.8-21.4,0.8c-6.1,1.4-12.1,2.9-18.2,4.3c-4.2,1-8.5,1.6-12.9,1.8c-4.8,0.2-9.6-0.2-14.1-1.9c-1.4-0.6-2.9-1.2-4.1-2.1c-1.1-0.8-2.1-1.8-2.9-2.9c-1.1-1.3-1.9-1.5-3.1-0.3c-0.4,0.4-0.7,0.7-1,1.1c-4.1,4.5-9.2,6.9-15.2,7.6c-5.1,0.6-10.1-0.2-15-1.6c-3.3-0.9-6.6-1.9-9.9-2.9c-5.2-1.5-10.4-2.3-15.8-2.3c-6.8,0.1-13.7,0.4-20.5,0.5c-6.9,0.1-13.8,0-20.6-1.1c-2.7-0.5-5.4-1.2-8.1-2.1c-2.3-0.7-4.3-2.1-6-3.9c-2-2.2-3.1-5.2-2.8-7.7c0.1,0,0.2-0.1,0.3-0.1c5,1,9.9,0.1,14.7-1.1c7.5-1.8,14.8-4.5,22-7.4c3.3-1.3,6.6-2.6,10-3.6c3.3-1,6.8-1.2,10.2-0.5c1.9,0.4,3.7,1.1,5.4,2.2c1.4,1,2.6,2.1,3.2,3.7c0.1,0.2,0.2,0.4,0.3,0.6c0.3,0.6,0.8,0.9,1.5,0.8c0.8-0.2,1-0.8,1-1.5c0-0.4-0.2-0.8-0.2-1.2c0-1.8-0.2-3.6,0.1-5.3c0.5-3.7,2.7-6.2,6.2-7.5c6.1-2.2,11.8-1.5,17,2.7c0.4,0.3,0.7,0.7,1.1,1c0.8,0.7,1.5,1.7,2.7,1.2c1.2-0.5,1.2-1.7,1.3-2.7c0.1-0.9,0.3-1.8,0.4-2.6c1.5-10,6.6-18,14.5-24.1c2-1.5,4.1-2.9,6.2-4.2c6.5-3.7,13.5-6.2,20.9-7.8c6.9-1.5,13.6-1,20.2,1.4c6.5,2.4,12.4,5.8,17.8,10.1c3.8,3.1,6.9,6.8,9.1,11.2c2.2,4.4,3.2,9.1,2.5,14.1C360.2,69.8,359.9,70.9,360.4,72.2L360.4,72.2z">'
  ];

  string[] private cloudAnimations = [
    '<animateMotion from="-470 0 0" to="350 0 0" dur="55s" fill="freeze" repeatCount="indefinite"/></path>',
    '<animateMotion from="-470 10 0" to="350 12 0" dur="50s" fill="freeze" repeatCount="indefinite"/></path>',
    '<animateMotion from="-470 0 0" to="350 0 0" dur="69s" fill="freeze" repeatCount="indefinite"/></path>',
    '<animateMotion from="350 7 0" to="-470 10 0" dur="55s" fill="freeze" repeatCount="indefinite"/></path>',
    '<animateMotion from="350 0 0" to="-470 0 0" dur="50s" fill="freeze" repeatCount="indefinite"/></path>'
  ];

  function random(string memory input) internal pure returns (uint256) {
      return uint256(keccak256(abi.encodePacked(input)));
  }
  
  function getBird(uint256 tokenId) public view returns (string memory) {
      return pluck(tokenId, "BIRD", birds);
  }
  
  function getCloud(uint256 tokenId) public view returns (string memory) {
      return pluck(tokenId, "CLOUD", clouds);
  }

  function getCloudAnimation(uint256 tokenId) public view returns (string memory) {
      return pluck(tokenId, "CLOUDANIMATION", cloudAnimations);
  }

  function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
    uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
    string memory output = sourceArray[rand % sourceArray.length];

    return output;
  }

      
  function toString(uint256 value) internal pure returns (string memory) {
  // Inspired by OraclizeAPI's implementation - MIT license
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


  function getPrice() public view returns (uint) {
    uint timeElapsed = block.timestamp - startAt;
    uint discount = discountRate * timeElapsed;
    uint finalPrice = startingPrice < discount ? 0 : startingPrice - discount;
    return finalPrice;
  }

   function mine(string memory s) internal pure returns ( uint256) {
    return bytes(s).length;
  }

  //  CREATE A STORY
  function setStory(uint256 _tokenId, string memory _tokenText, uint256 _lockTime) internal  {
    require(mine(_tokenText) >= 4, "Text is too short. Must be at least 4 Characters.");
    require(mine(_tokenText) <= 193, "Text is too long. Must be at most 193 Characters.");
    StoryStruct memory story = StoryStruct(_tokenId, _tokenText, block.timestamp + _lockTime );
    storyData[_tokenId] = story;
  }

  function updateStory(uint256 _tokenId, string memory _newTokenText)  public {
    require(ownerOf(_tokenId) == msg.sender, "You must be the owner of this Story to update the text.");
    uint tokenUnlockTime = getTokenUnlockTime(_tokenId);
    require(tokenUnlockTime < block.timestamp, (string(abi.encodePacked("Token is not unlocked yet. Must wait until: ", tokenUnlockTime))) );
    setStory(_tokenId, _newTokenText, 0);
  }

  function adminUpdateStory(uint256 _tokenId, string memory _newTokenText, uint256 _lockTime) external onlyOwner {
    require(isAdminUpdateEnabled, "this feature has been turned off by owner.");
    setStory(_tokenId, _newTokenText, block.timestamp + _lockTime * 1 minutes);
  }
  function readStory(uint256 _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), 'Token does not exist!');
    return string(abi.encodePacked(storyData[_tokenId].tokenText));
  }

  function setNewRates(uint _newDiscountRate, uint _newStartPrice) public onlyOwner  {
    require(_newDiscountRate > 0, "Discount price is too low");
    require(_newStartPrice > _newDiscountRate, "Discount price is too high");
    require(_newStartPrice > 0, "Start Price too low");
    require(_newStartPrice > _newDiscountRate, "Start Price too low");
    discountRate = _newDiscountRate;
    startingPrice = _newStartPrice;
    startAt = block.timestamp;
  }

  function getDiscountRate()  public view returns (uint)  {
    return discountRate;
  }

  function getUnlockTime()  public view returns (uint)  {
    return unlockTime;
  }

  function getStartPrice()  public view returns (uint)  {
    return startingPrice;
  }

  function getTokenUnlockTime(uint _tokenId) internal view returns (uint) {
    return  storyData[_tokenId].unlockTokenTime;
  }

  //  lets owner enable or disable minting
  function setIsPublicMintEnabled(bool _isPublicMintEnabled) external onlyOwner {
    isPublicMintEnabled = _isPublicMintEnabled;
  }

  function setLockDuration(uint _lockDuration) external onlyOwner {
    lockDuration = _lockDuration * 1 minutes;
  }

  function setIsAdminUpdateEnabled(bool _isAdminUpdateEnabled) external onlyOwner {
    require(isAdminUpdateEnabled, "this feature has been turned off by owner.");
    isAdminUpdateEnabled = _isAdminUpdateEnabled;
  }

  function setBaseTokenUri(string calldata _baseTokenUri) external onlyOwner {
    baseTokenUri = _baseTokenUri;
  }


  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    string[11] memory parts;
    parts[0] = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" id="sb-canvas" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 500 500" style="enable-background:new 0 0 500 500;" xml:space="preserve">';
    parts[1] = '<style type="text/css">#sb-canvas{overflow: hidden; width: 1000px; margin: 0 auto;}.st0{fill:#FFFFFF;}.st1{fill:#FFFFFF;stroke:#231F20;stroke-width:3;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;}.st2{fill:none;stroke:#231F20;stroke-width:4;stroke-miterlimit:10;}.st3{fill:none;}#text{font-family:Chelsea;font-size:25px;}</style>';
    parts[2] = '<rect id="bg_1_" y="-2" class="st0" width="500" height="500"/>';
    parts[3] = getCloud(_tokenId);
    parts[4] = getCloudAnimation(_tokenId);
    parts[5] = getBird(_tokenId);
    parts[6] = '<rect id="bg" x="2" y="2" class="st2" width="496" height="496"/><rect x="45.3" y="264.5" class="st3" width="409.3" height="192"/>';
    parts[7] = '<foreignObject id="text" x="20" y="230" width="460" height="230"><p class="base" xmlns="http://www.w3.org/1999/xhtml">';
    parts[8] = readStory(_tokenId);
    parts[9] = '</p></foreignObject>';
    parts[10] = '<path id="logo" d="M463.6,431.7c0.7-0.3,1.2-0.1,1.4,0.6c0.2,0.6,0.6,1.2,1,1.7c0.2,0.3,0.5,0.2,0.6-0.1c0.1-0.3,0.2-0.6,0.3-0.9c0.3-1.2-0.6-2.4-1.8-2.6c-0.1,0-0.3,0-0.5-0.1c0.1-0.2,0.2-0.2,0.3-0.3c0.6-0.7,1-1.5,1.1-2.3c0.1-0.9-0.4-1.7-1.2-2c-0.6-0.2-1.2-0.2-1.8,0c-0.8,0.2-1.4,0.7-1.9,1.3c-0.5,0.6-0.9,1.2-1.3,1.8c-0.3,0.5-0.8,0.7-1.4,0.8c-0.1,0-0.3,0-0.5,0c-1.4-0.2-2.9-0.6-4.2-1.1c-0.2-0.1-0.3-0.2-0.3-0.3c0-0.6-0.1-1.2-0.1-1.9c0-0.1,0-0.3,0.1-0.4c0.6-1.1,1.5-1.8,2.7-1.9c0.3,0,0.7,0,0.9,0.2c0.5,0.3,0.5,0.4,0.4,0.9l0,0.2c-0.1,0.6-0.2,1.2-0.1,1.8c0,0.3,0.2,0.6,0.4,0.9c0.3,0.3,0.6,0.2,0.9-0.1c0.2-0.2,0.3-0.4,0.3-0.7c0.1-1-0.1-2-0.7-2.9c-0.6-0.8-1.4-1.2-2.4-1.1c-0.8,0.1-1.5,0.5-2.1,1c-0.6,0.5-1,1.1-1.2,1.9l-0.1-0.1c-0.8-1.1-1.9-1.8-3.1-2.4c-0.3-0.1-0.6-0.2-1-0.3c-0.6-0.1-1.1,0.2-1.6,0.6c-0.4,0.5-0.3,1.1,0.2,1.4c0.3,0.2,0.6,0.3,0.9,0.4c0.6,0.2,1.1,0.4,1.7,0.6c0.4,0.2,0.7,0.4,1,0.6c0.3,0.2,0.5,0.4,0.6,0.8c-0.2,0-0.4-0.1-0.6-0.1c-2.1-0.4-4.1-0.6-6.2-0.4c-1,0.1-2,0.3-3,0.5c-6.4,1.1-9.2,4.5-10.4,7.4c0,0,0,0,0,0c-0.1,0.1-0.2,0.3-0.2,0.4c-0.3,0.6-0.5,1.2-0.6,1.9c-0.2,1.2-0.2,2.4,0,3.6c0.2,1.2,0.7,2.3,1.5,3.2c0.8,0.8,1.6,1.6,2.6,2.1c0.4,0.2,0.8,0.5,1.2,0.7c1.3,0.9,2.6,1.7,4.1,2.3l0.1,0.1v0c0,0.1-0.1,0.2-0.1,0.4c-0.5,1.5-0.6,3-0.5,4.6c0.1,0.6,0.1,1.2,0.1,1.8c0.1,1.1,0.2,2.2,0.4,3.3c0.2,1,0.7,2,1.2,2.8c0.1,0.2,0.1,0.3,0,0.5c-0.2,0.6-0.6,1.1-1.2,1.5c-0.1,0.1-0.2,0.1-0.3,0.2c-1,0.7-1,2-0.1,2.7c0.6,0.5,1.3,0.6,2,0.3c0.3-0.2,0.7-0.4,1-0.6c0.5-0.3,0.9-0.5,1.4-0.8c0.5-0.3,1.1-0.3,1.7,0c0.5,0.2,1.1,0.4,1.6,0.7c0.7,0.3,1.5,0.5,2.3,0.5c0.5,0,0.9,0,1.4,0.1c1.4,0.2,2.7-0.2,4-0.8c2.3-1.2,3.9-3,4.9-5.4c0-0.1,0.1-0.2,0.2-0.4c0.1,0.1,0.1,0.1,0.1,0.2c0.6,1.2,0.8,2.4,0.5,3.6c-0.6,2.7-2.1,4.6-4.7,5.5c-1.9,0.7-3.9,1.1-5.9,1c-1.9,0-3.8-0.1-5.8-0.3c-1.5-0.1-2.9-0.5-4.1-1.3c-1.4-0.8-2.7-1.9-3.8-3.1c-0.8-0.8-1.3-1.8-1.5-2.9c0-0.2-0.1-0.5-0.1-0.8c-0.1-1-0.3-2.1-0.4-3.2c-0.2-1-0.6-1.9-1.3-2.7c-0.4-0.5-0.9-0.8-1.5-0.9c-0.4-0.1-0.8-0.1-1.1,0c-1.6,0.1-2.8,1.3-2.9,2.8c-0.1,1,0.1,2,0.2,2.9c0,0.1,0,0.3,0.1,0.5c-0.1-0.1-0.1-0.1-0.2-0.1c-0.5-0.8-1.1-1.5-1.7-2.2c-0.6-0.6-1.2-1.1-2-1.3c-1.3-0.4-2.4,0.1-2.9,1.6c-0.1,0.4,0,0.6,0.5,0.6c0.1,0,0.2,0,0.3,0c0.6-0.1,1.1-0.1,1.7,0.1c2,0.4,3.4,1.6,4.2,3.4c0,0,0,0.1,0,0.2c-0.5-0.5-1-0.8-1.7-0.9c-0.6-0.1-1.2-0.1-1.7,0.2c-0.3,0.2-0.6,0.5-0.9,0.7c-0.3,0.3-0.4,0.7-0.4,1.2c0,0.3,0.2,0.5,0.5,0.6c0.5,0.1,1,0,1.2-0.5c0.1-0.3,0.2-0.6,0.3-1c0.1-0.2,0.1-0.4,0.1-0.6c1-0.2,2,0.2,2.4,1c0.2,0.4,0.3,0.8,0.4,1.2c0,0.1,0,0.3-0.1,0.4c-0.5,0.7-0.9,1.3-1.4,1.9c-0.7,0.9-1.2,1.9-1.5,3c-0.2,0.7-0.3,1.3-0.4,2c-0.2,1.6,0,3.2,0.6,4.8c0.1,0.3,0.3,0.6,0.4,0.9c0.8,1.3,2,2.1,3.6,2.1c2.2,0,4.5-1.7,5.2-3.8c0.2-0.5,0.2-1,0.2-1.6c-0.2-1.6-2-2.4-3.3-1.4c-0.2,0.2-0.4,0.4-0.6,0.5c-0.2,0.2-0.4,0.4-0.7,0.6c-0.5,0.3-1.1,0.2-1.6-0.2c-0.5-0.5-0.7-1.3-0.4-2c0.3-0.8,1-1.5,1.7-1.9c0.4-0.2,0.8-0.3,1.2-0.5c0.7-0.3,1.5-0.4,2.3-0.3c0.3,0,0.5,0.1,0.8,0.1c1.4,0.2,2.7,0.6,3.9,1.3c2,1.2,4.1,1.9,6.4,2.4c1.7,0.4,3.4,0.5,5.1,0.4c2.2-0.2,4.3-0.6,6.4-1.1c1.1-0.3,2.2-0.7,3.2-1.2c0.8-0.4,1.5-0.9,2.2-1.3c1.5-0.9,2.9-2,3.9-3.4c1.2-1.5,2-3.2,2-5.1c0-1.1,0-2.1-0.2-3.2c-0.5-3.1-2-5.7-4.6-7.6l-0.2-0.2c-1.9-1.6-4-2.8-6.3-3.7c-0.1,0-0.2-0.1-0.3-0.2c0.1-0.1,0.2-0.1,0.2-0.2c1-0.7,1.9-1.6,2.5-2.8c0.5-1.2,1-2.4,1.3-3.6c0.3-1.2,0.2-2.4-0.4-3.6c-1-2-2.5-3.5-4.6-4.4c-0.1,0-0.2-0.1-0.3-0.2v-1.1c0-0.4,0-0.7,0-1.1c1,0.3,2.8,1.3,3.6,1.9c0.7,0.5,1.2,1.2,1.6,1.9c0.6,1.1,0.9,2.3,1.1,3.6c0.1,1,0.2,2,0.4,3c0.1,0.4,0.2,0.8,0.4,1.2c0.3,0.6,0.9,0.9,1.6,0.8c0.8-0.1,1.3-0.5,1.8-1c0.7-0.8,1.1-1.8,1.3-2.8c0.2-0.8,0.2-1.6-0.1-2.3c-0.4-0.9-0.8-1.8-1.5-2.4c-0.3-0.3-0.7-0.5-1-0.8c-0.2-0.2-0.4-0.3-0.6-0.5c-0.4-0.5-0.4-1.1,0.1-1.5C462.9,432.2,463.3,431.9,463.6,431.7z M441.3,461.9c-0.1-0.1-0.2-0.2-0.2-0.3c-0.4-0.7-0.6-1.4-0.7-2.1c-0.2-1,0.3-2,1.3-2.6C441.6,458.5,441.7,460.2,441.3,461.9z M442.2,451.2c-0.3,1.1-0.5,2.2-0.4,3.4c0,0.9-0.1,1.4-0.7,1.8c-0.4,0.2-0.6,0.6-1,1c0-0.1,0-0.2,0-0.3c-0.1-1.1-0.2-2.1-0.2-3.2c-0.1-1.2,0.1-2.4,0.5-3.6c0-0.1,0.1-0.3,0.2-0.4c0.6,0.2,1.2,0.3,1.8,0.5C442.3,450.7,442.3,450.9,442.2,451.2z M445.3,440.2c-0.1,0.8-0.4,1.6-0.5,2.4c-0.1,0.3-0.1,0.7-0.1,1c-0.1,3-0.1,5.9-0.2,8.9c0,1,0,2.1,0,3.1c0,1-0.1,1.9-0.1,2.8c0,1,0.1,2,0.1,3c0.1,0.8,0.1,1.7,0,2.5c0,0.2-0.1,0.3-0.2,0.5c-0.1,0.2-0.2,0.3-0.4,0.3c-0.2,0-0.4-0.1-0.4-0.3c-0.1-0.3-0.2-0.7-0.2-0.9c0.1-0.5,0.1-0.9,0.1-1.3c0.1-0.8,0.2-1.6,0.2-2.4c0.1-3.7,0.2-7.5,0.3-11.2c0-1.9,0.1-3.8,0.1-5.6c0-0.4-0.1-0.9-0.1-1.3c0-0.7,0-1.4,0-2.1c0-0.5,0.1-0.9,0.4-1.3c0.1-0.3,0.3-0.5,0.7-0.5c0.3,0,0.5,0.3,0.5,0.7C445.5,439,445.4,439.6,445.3,440.2z M444,435.7c-0.1-0.1-0.2-0.3-0.3-0.4c-1.2-1.4-3.1-1.8-4.7-1c-1.1,0.5-1.3,1.6-0.5,2.5c0.2,0.2,0.4,0.4,0.6,0.5c0.2,0.2,0.5,0.3,0.8,0.4c0.9,0.5,1.4,1.1,1.8,2c0.3,0.8,0.5,1.6,0.5,2.5c0.1,0.9,0.1,1.8,0.2,2.7c0,0.1,0,0.2,0,0.3c-0.1,0-0.2,0-0.3-0.1c-2.2-1-3.7-2.6-4.8-4.7c-0.3-0.6-0.5-1.3-0.6-2.1c0-0.9,0-1.8,0.2-2.8c0.1-0.4,0.2-0.8,0.5-1.1c0.3-0.3,0.6-0.7,0.8-1c0.3-0.4,0.7-0.7,1.1-1.1c0.3-0.4,0.7-0.7,1.2-0.9c1.3-0.7,2.7-1,4.2-1.1c1.6-0.1,3.3-0.1,5,0c1.1,0.1,2.1,0.3,3.1,0.6c0.4,0.1,0.4,0.1,0.4,0.5c0,0.5,0,1,0,1.5c0,0.1,0,0.2,0,0.3c-0.4-0.1-0.7-0.2-1-0.2c-0.7-0.1-1.4-0.1-2.1,0c-1,0.1-2.1,0.2-3.1,0.6C445.8,434.1,444.8,434.7,444,435.7z M447.1,445c-0.1-0.4-0.1-0.6,0.2-0.7c0.8-0.4,1.3-0.9,1.9-1.6c0.7-0.9,1.4-1.8,2-2.7c0.3-0.5,0.6-0.9,1-1.5c0.5,0.7,0.8,1.4,1,2.2c0.1,0.6,0.1,1.2,0,1.9c-0.2,1.2-0.6,2.3-1.1,3.3c-0.2,0.4-0.5,0.7-0.7,1.1c-0.1,0.2-0.3,0.2-0.5,0.2c-1-0.1-2-0.2-3-0.3c-0.2,0-0.4-0.1-0.7-0.2c0-0.2,0-0.3,0-0.4C447.1,445.8,447.1,445.4,447.1,445z M451.6,438.1c-1,1.4-1.8,2.9-3,4.2c-0.4,0.4-0.8,0.7-1.2,1.1c0,0-0.1,0.1-0.2,0.1c0-0.1,0-0.2,0-0.3c0-0.8,0.1-1.6,0.1-2.4c0-0.6,0-1.1-0.1-1.7c0-0.7,0.2-1.2,0.5-1.8c0-0.1,0.2-0.2,0.3-0.2c1.1-0.6,3-0.1,3.8,0.9L451.6,438.1z M450.3,465c-0.3,0.1-0.7,0.2-1,0.2c-0.8,0-1.4-0.4-1.8-1.1c-0.3-0.5-0.4-1.1-0.5-1.7c-0.3-2.1-0.5-4.2-0.3-6.3c0-0.1,0-0.3,0-0.5c0.1,0,0.2,0,0.3,0.1c1.1,0.4,1.9,1.1,2.4,2.2c0.1,0.2,0.1,0.4-0.1,0.5c-0.6,0.8-1,1.7-1.2,2.7c-0.1,0.7,0,1.4,0,2c0.1,0.4,0.1,0.9,0.2,1.3l0,0.2c0.1,0.1,0.2,0.2,0.2,0.3c0.2,0.1,0.2-0.1,0.3-0.2c0.3-0.5,0.7-0.9,1-1.4c0.1-0.2,0.3-0.3,0.4-0.5c0.8-0.8,1.1-1.7,1.1-2.7c-0.1-0.8-0.4-1.5-1.1-2c-0.3-0.2-0.4-0.4-0.6-0.7c-0.6-1.2-1.5-1.9-2.8-2.4c-0.1,0-0.3-0.1-0.5-0.2c0-0.9,0.1-1.8,0.1-2.7c0.1,0.1,0.2,0.1,0.3,0.1c1.9,0.9,3.9,1.8,5.8,2.7c0.3,0.1,0.4,0.3,0.5,0.6c0.4,2.2,0.3,4.5-0.4,6.6C452.6,463.5,451.7,464.5,450.3,465z M456.1,441.1c0.3,2.9-0.7,5.5-2.8,7.6c-0.4,0.4-0.8,0.6-1.3,1c-0.1,0.1-0.3,0.2-0.5,0.3c0.5,0.1,0.8,0.1,1.2,0.2c2,0.5,3.4,1.6,3.9,3.6c0.6,2.2,0.8,4.5,0.1,6.7c-0.6,2-1.7,3.6-3.4,4.8c-0.2,0.1-0.4,0.2-0.6,0.3c-0.2,0.1-0.3,0.1-0.5,0.1l-0.2-0.2l0.1-0.2l0.1-0.1c2.3-1.2,3.6-3.2,4.1-5.6c0.5-2,0.3-4-0.3-5.9c-0.5-1.8-1.8-2.7-3.6-3c-0.5-0.1-1-0.1-1.5-0.2c-0.2,0-0.3,0-0.5-0.1c-0.1-0.3,0.1-0.5,0.3-0.7c0.2-0.1,0.4-0.2,0.5-0.3c2.2-1.1,3.4-3,4-5.2c0.4-1.3,0.5-2.6,0.1-3.9c-0.6-2.1-2.1-3.5-4.2-4.1c-0.2,0-0.4,0-0.5-0.3c0.1-0.2,0.2-0.2,0.4-0.2c0.3,0,0.7,0.1,1,0.2C454.4,436.9,455.9,438.6,456.1,441.1z"/></svg>';

    string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
    output = string(abi.encodePacked(output, parts[9], parts[10]));
    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Story Block #', Strings.toString(_tokenId), '", "description": "Story Block is the first all on-chain experiment in collaborative storytelling.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    output = string(abi.encodePacked('data:application/json;base64,', json));
    return output;
  }
  function withdraw(address _address) public onlyOwner {
    payable(_address).transfer(address(this).balance);
  }

  function mint( string memory _tokenText) nonReentrant public payable  {
    require(isPublicMintEnabled, 'Minting is not enabled yet!');
    require(unlockTime < block.timestamp, "Minting is not unlocked yet");
    require(mine(_tokenText) >= 4, "Text is too short. Must be at least 4 Characters.");
    require(mine(_tokenText) <= 193, "Text is too long. Must be at most 193 Characters.");
    uint price = getPrice();
    uint totalCurrentSupply = totalSupply();
    require(msg.value >= price, "The amount of ETH sent is less than the price of token");
    require(totalCurrentSupply + 1 <= maxSupply, 'sold out');
    setStory(totalCurrentSupply, _tokenText, 0);
    _safeMint(msg.sender, 1);
    emit StoryMinted(totalSupply(), msg.value);
    startAt = block.timestamp;
    unlockTime = block.timestamp + lockDuration;
  }


  function getAllTokens() public view returns (StoryStruct[] memory) {
    uint256 counter = 0;
    for (uint256 i = 0; i < totalSupply(); i++) {
      if (_exists(i)) {
        counter++;
      }
    }
    StoryStruct[] memory res = new StoryStruct[](counter);
    uint256 index = 0;
    for (uint256 i = 0; i < totalSupply(); i++) {
      if (_exists(i)) {
        res[index] = StoryStruct(storyData[i].tokenId, storyData[i].tokenText, storyData[i].unlockTokenTime);
        index++;
      }
    }
    return res;
  }

  function getTokensByUser(address account) public view returns (StoryStruct[] memory) {
    uint256 counter = 0;
    for (uint256 i = 0; i < totalSupply(); i++) {
      if (_exists(i) && ownerOf(i) == account) {
        counter++;
      }
    }

    StoryStruct[] memory res = new StoryStruct[](counter);
    uint256 index = 0;
    for (uint256 i = 0; i < totalSupply(); i++) {
      if (_exists(i) && ownerOf(i) == account) {
        res[index] = StoryStruct(storyData[i].tokenId, storyData[i].tokenText, storyData[i].unlockTokenTime);
        index++;
      }
    }
    return res;
  }
}