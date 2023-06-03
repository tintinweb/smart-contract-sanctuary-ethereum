/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// File: erc721a/contracts/IERC721A.sol


// ERC721A Contracts v4.2.3
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
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

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
    ) external payable;

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
    function approve(address to, uint256 tokenId) external payable;

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


// ERC721A Contracts v4.2.3
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
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
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
    function approve(address to, uint256 tokenId) public payable virtual override {
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
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
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
    ) public payable virtual override {
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
    ) public payable virtual override {
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
    ) public payable virtual override {
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
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
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

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
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
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

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

// File: contracts/Terrapins.sol


pragma solidity ^0.8.0;



 
library TerrapinsLibrary {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

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

    function toString(uint256 value) internal pure returns (string memory) {

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
}


error AlreadyClaimed();
error NotOwnerOfToken();
 
contract Terrapins is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 1406;
    uint256 public constant SHELL_PRICE = 950 ether;
 
    struct Trait {
        uint256 base;
        uint256 mouth;
        uint256 eye;
        uint256 head;
        uint256 outwear;
    }

    address public terraCrateAddress;
    address public shellAddress;
    address deadAddress = 0x000000000000000000000000000000000000dEaD;
 
    mapping(uint256 => uint256) public hasClaimed;
    mapping(address => bool) public allowlist;

    uint256[] private oneOfOnes;
    uint256 private maxOneOfOneSupply;
 
    event claimedIds(uint256 indexed _Ids);

    string[4] private baseNames = ['Green', 'Grayscale', 'Gold', 'Dark'];
    string[4] private baseColorOne = ['#37946e', '#ffffff', '#ff6700', '#000000'];
    string[4] private baseColorTwo = ['#99e550', '#bcc6cb', '#f8ed00', '#cbdbfc'];
    string[4] private mouthNames = ['Straight', 'Smile', 'Frown', 'Smirk'];
    string[4] private mouthLayers = [
        '<path stroke="#000000" d="M13 18h4" />',
        '<path stroke="#000000" d="M12 18h1M17 18h1M13 19h4" /><path stroke="#ffffff" d="M13 18h4" />',
        '<path stroke="#000000" d="M13 18h4M12 19h1M17 19h1" />',
        '<path stroke="#000000" d="M12 18h1M13 19h4" />'
    ];
    string[10] private eyeNames = ['Right', 'Up', 'Ocean', 'VR', '3D', 'Nouns', 'Wood', 'Gray and Black', 'Closed', 'What'];
    string[10] private eyeLayers = [
        '<path stroke="#ffffff" d="M12 11h1M15 11h1M12 12h1M15 12h1" /><path stroke="#000000" d="M13 11h1M16 11h1M13 12h1M16 12h1" />',
        '<path stroke="#000000" d="M12 11h2M15 11h2" /><path stroke="#ffffff" d="M12 12h2M15 12h2" />',
        '<path stroke="#000000" d="M12 10h2M17 10h2M8 11h4M14 11h3M19 11h1M11 12h1M14 12h1M16 12h1M19 12h1M12 13h2M17 13h2" /><path stroke="#5fcde4" d="M12 11h2M17 11h2M12 12h2M17 12h2" />', 
        '<path stroke="#000000" d="M9 10h1M11 10h9M10 11h1M20 11h1M10 12h1M20 12h1M10 13h1M20 13h1M9 14h1M11 14h9" /><path stroke="#417ce7" d="M11 11h1M19 11h1M11 13h1M19 13h1" /><path stroke="#9dc0ff" d="M12 11h7M11 12h1M19 12h1M12 13h7" /><path stroke="#ffffff" d="M12 12h7" />',
        '<path stroke="#ffffff" d="M8 10h12M9 11h3M15 11h1M19 11h1M11 12h1M15 12h1M19 12h1M11 13h9" /><path stroke="#005cff" d="M12 11h3M12 12h3" /><path stroke="#ff0000" d="M16 11h3M16 12h3" />',
        '<path stroke="#ff0000" d="M9 10h6M16 10h6M6 11h4M14 11h3M21 11h1M6 12h1M9 12h1M14 12h1M16 12h1M21 12h1M6 13h1M9 13h1M14 13h1M16 13h1M21 13h1M9 14h6M16 14h6" /><path stroke="#ffffff" d="M10 11h2M17 11h2M10 12h2M17 12h2M10 13h2M17 13h2" /><path stroke="#000000" d="M12 11h2M19 11h2M12 12h2M19 12h2M12 13h2M19 13h2" />',
        '<path stroke="#663931" d="M11 10h4M16 10h4M8 11h3M15 11h1" /><path stroke="#8f563b" d="M11 11h4M16 11h4" /><path stroke="#d9a066" d="M11 12h4M16 12h4" />',
        '<path stroke="#ccd4e4" d="M11 10h4M16 10h1M11 11h4M16 11h1M11 12h1" /><path stroke="#ffffff" d="M17 10h1M17 11h1M12 12h1" /><path stroke="#000000" d="M18 10h2M8 11h3M15 11h1M18 11h2M13 12h2M16 12h4M11 13h4M16 13h4" />',
        '<path stroke="#000000" d="M12 11h2M15 11h2" />',
        '<path stroke="#000000" d="M12 11h2M15 11h2M13 12h1M16 12h1" /><path stroke="#ffffff" d="M12 12h1M15 12h1" />'
        ];
    string[10] private headNames = ['Halo', 'Punk', 'Cap', 'Trapper Hat', 'Golden Cowboy', 'Pirate Hat', 'Red Hair', 'Curly Hair', 'Fast Food', 'None'];
    string[10] private headLayers = [
        '<path stroke="#fff300" d="M10 1h7M9 2h1M17 2h1M10 3h7" />',
        '<path stroke="#000000" d="M14 1h1M13 2h3M12 3h4M11 4h5M13 5h3M13 6h2M14 7h1" />',
        '<path stroke="#000000" d="M10 4h6M9 5h1M16 5h1M8 6h1M13 6h7M8 7h1M12 7h1M20 7h1M8 8h1M12 8h1M20 8h1M9 9h12" /><path stroke="#373737" d="M10 5h6M9 6h4M9 7h3M13 7h5M19 7h1M9 8h3M13 8h6" /><path stroke="#ffffff" d="M18 7h1M19 8h1" />',
        '<path stroke="#663931" d="M8 3h3M7 4h4M7 5h4M7 6h4M7 7h4M7 8h4M8 9h2" /><path stroke="#8f563b" d="M11 3h2M11 4h1M11 5h1M11 6h1M11 7h1M11 8h1M10 9h1" /><path stroke="#eec39a" d="M13 3h6M12 4h8M12 5h8M12 6h8M12 7h1M14 7h1M16 7h1M18 7h1M13 8h1M15 8h1M17 8h1M19 8h1M10 10h1" /><path stroke="#d9a066" d="M13 7h1M15 7h1M17 7h1M19 7h1M12 8h1M14 8h1M16 8h1M18 8h1" />',
        '<path stroke="#ff7f28" d="M10 2h1M14 2h1M9 3h2M13 3h2M10 4h1M18 4h3M21 5h1M21 6h1" /><path stroke="#ffdd28" d="M11 2h2M15 2h1M11 3h2M15 3h2M11 4h7M11 5h7" /><path stroke="#d55d0b" d="M7 4h3M6 5h5M6 6h6M7 7h7" /><path stroke="#ffa304" d="M18 5h3M18 6h3" /><path stroke="#fff300" d="M12 6h6" /><path stroke="#ffda12" d="M14 7h7" />',
        '<path stroke="#000000" d="M11 1h5M10 2h7M9 3h4M14 3h1M16 3h2M9 4h5M15 4h3M7 5h6M14 5h1M16 5h4M6 6h15M6 7h15M7 8h13" /><path stroke="#ffffff" d="M13 3h1M15 3h1M14 4h1M13 5h1M15 5h1" />',
        '<path stroke="#ff1616" d="M10 4h8M9 5h9M8 6h3M17 6h2M8 7h2M18 7h1M8 8h1" />',
        '<path stroke="#000000" d="M16 1h1M8 2h1M12 2h1M14 2h1M16 2h3M5 3h1M7 3h1M9 3h2M12 3h6M19 3h1M6 4h2M9 4h10M6 5h14M5 6h1M7 6h13M6 7h15M10 8h2M13 8h4M19 8h1M9 9h1M15 9h1" />',
        '<path stroke="#ff1616" d="M10 4h7M9 5h3M13 5h1M15 5h3M8 6h5M14 6h1M16 6h2M8 7h14" /><path stroke="#fbf236" d="M12 5h1M14 5h1M13 6h1M15 6h1" />',
        ''
    ];
    string[7] private outwearNames = ['Gold Chain', 'Diamond Earing', 'Gold Earing', 'Turtleneck', 'Yellow Jacket', 'White Tie', 'None'];
    string[7] private outwearLayers = [
        '<path stroke="#fbf236" d="M8 22h1M12 22h1M9 23h3" />',
        '<path stroke="#74e7ff" d="M7 13h1" />',
        '<path stroke="#fbf236" d="M7 13h1" />',
        '<path stroke="#000000" d="M7 21h5M7 22h7M7 23h7" />',
        '<path stroke="#fbf236" d="M7 21h3M7 22h3M12 22h1M7 23h3M12 23h1" /><path stroke="#ffffff" d="M10 21h1M10 23h1M13 23h1" />',
        '<path stroke="#ffffff" d="M7 23h7" />',
        ''
    ];
    string[5] private oneOfOneNames = ['Night', 'Skull', 'Nothing', 'Colors', 'Dot'];
    string[5] private oneOfOneLayers = [
        '<path stroke="#ffffff" d="M10 5h7M9 6h9M8 7h11M8 8h1M15 8h4M8 9h1M16 9h3M8 10h1M16 10h3M8 11h1M11 11h1M14 11h1M16 11h3M8 12h1M10 12h2M13 12h2M16 12h4M8 13h1M16 13h3M8 14h1M15 14h4M8 15h1M15 15h4M7 16h1M16 16h3M7 17h1M16 17h3M7 18h1M16 18h3M7 19h1M16 19h3M8 20h1M15 20h4M9 21h10M14 22h5M14 23h5" /><path stroke="#cbdbfc" d="M9 8h6M9 9h7M9 10h7M9 11h1M12 11h1M15 11h1M9 12h1M12 12h1M15 12h1M9 13h7M9 14h6M9 15h6M8 16h8M8 17h8M8 18h1M10 18h6M8 19h8M9 20h6" /><path stroke="#639bff" d="M10 11h1M13 11h1M9 18h1" />',
        '<path stroke="#ffffff" d="M9 7h8M8 8h10M7 9h12M7 10h12M7 11h2M12 11h2M17 11h2M7 12h2M12 12h2M17 12h2M7 13h12M7 14h12M7 15h12M8 16h10M9 17h2M12 17h2M15 17h2" /><path stroke="#000000" d="M9 11h3M14 11h3M9 12h3M14 12h3" />',
        '<path stroke="#639bff" d="M10 14h7M9 15h9M8 16h11M8 17h1M15 17h4M8 18h1M16 18h3M8 19h1M16 19h3M8 20h1M10 20h1M13 20h1M16 20h3M8 21h1M16 21h4M8 22h1M16 22h3M8 23h1M15 23h4" /> <path stroke="#cbdbfc" d="M9 17h6M9 18h7M9 19h7M9 20h1M12 20h1M15 20h1M9 21h1M12 21h1M15 21h1M9 22h7M9 23h6" /><path stroke="#ffffff" d="M11 20h1M14 20h1M10 21h2M13 21h2" />',
        '<path stroke="#99e550" d="M4 11h4M4 12h4" /><path stroke="#ffffff" d="M8 11h4M8 12h4" /><path stroke="#fbf236" d="M12 11h4M12 12h4" /><path stroke="#000000" d="M16 11h4M16 12h4" />',
        '<path stroke="#ffffff" d="M11 11h2M11 12h2" />'
    ];
    
    function randomTrait(uint256 tokenId) internal pure returns (Trait memory) { 
        Trait memory trait;

        trait.base = getBase(tokenId);
        trait.mouth = getMouth(tokenId);
        trait.eye = getEye(tokenId);
        trait.head = getHead(tokenId);
        trait.outwear = getOutwear(tokenId);

        return trait;
    }

    function getTraits(Trait memory trait) internal view returns (string memory) {
        string[11] memory parts;
        
        parts[0] = ', "attributes": [{"trait_type": "Type","value": "';
        parts[1] = baseNames[trait.base];
        parts[2] = '"}, {"trait_type": "Mouth","value": "';
        parts[3] = mouthNames[trait.mouth];
        parts[4] = '"}, {"trait_type": "Eye","value": "';
        parts[5] = eyeNames[trait.eye];
        parts[6] = '"}, {"trait_type": "Head","value": "';
        parts[7] = headNames[trait.head];
        parts[8] = '"}, {"trait_type": "Outwear","value": "';
        parts[9] = outwearNames[trait.outwear];
        parts[10] = '"}], ';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
                      output = string(abi.encodePacked(output, parts[8], parts[9], parts[10]));
        return output;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getBase(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("BASE COLOR", TerrapinsLibrary.toString(tokenId))));

        uint256 rn1 = rand % 120;
        uint256 bc = 0;

        if (rn1 >= 70 && rn1 < 100) { bc = 1; }
        if (rn1 >= 100 && rn1 < 110) { bc = 2; }
        if (rn1 >= 110) { bc = 3; }

        return bc;
    }

    function getMouth(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER TWO", TerrapinsLibrary.toString(tokenId))));

        uint256 rn2 = rand % 49;
        uint256 l2 = 0;

        if (rn2 >= 10 && rn2 < 20) { l2 = 1; }
        if (rn2 >= 20 && rn2 < 30) { l2 = 2; }
        if (rn2 >= 40) { l2 = 3; }
        
        return l2;
    }

    function getEye(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER THREE", TerrapinsLibrary.toString(tokenId))));

        uint256 rn3 = rand % 260;
        uint256 l3 = 0;

        if (rn3 >= 40 && rn3 < 80) { l3 = 1; }
        if (rn3 >= 80 && rn3 < 100) { l3 = 2; }
        if (rn3 >= 100 && rn3 < 120) { l3 = 3; }
        if (rn3 >= 120 && rn3 < 140) { l3 = 4; }
        if (rn3 >= 140 && rn3 < 150) { l3 = 5; }
        if (rn3 >= 150 && rn3 < 170) { l3 = 6; }
        if (rn3 >= 170 && rn3 < 180) { l3 = 7; }
        if (rn3 >= 180 && rn3 < 220) { l3 = 8; }
        if (rn3 >= 220) { l3 = 9; }
        
        return l3;
    }

    function getHead(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER FOUR", TerrapinsLibrary.toString(tokenId))));

        uint256 rn4 = rand % 130;
        uint256 l4 = 0;

        if (rn4 >= 10 && rn4 < 20) { l4 = 1; }
        if (rn4 >= 20 && rn4 < 30) { l4 = 2; }
        if (rn4 >= 30 && rn4 < 40) { l4 = 3; }
        if (rn4 >= 40 && rn4 < 50) { l4 = 4; }
        if (rn4 >= 50 && rn4 < 60) { l4 = 5; }
        if (rn4 >= 60 && rn4 < 70) { l4 = 6; }
        if (rn4 >= 70 && rn4 < 80) { l4 = 7; }
        if (rn4 >= 70 && rn4 < 80) { l4 = 8; }
        if (rn4 >= 80) { l4 = 9; }
        
        return l4;
    }

    function getOutwear(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER FIVE", TerrapinsLibrary.toString(tokenId))));

        uint256 rn5 = rand % 110;
        uint256 l5 = 0;

        if (rn5 >= 5 && rn5 < 10) { l5 = 1; }
        if (rn5 >= 10 && rn5 < 15) { l5 = 2; }
        if (rn5 >= 15 && rn5 < 30) { l5 = 3; }
        if (rn5 >= 30 && rn5 < 35) { l5 = 4; }
        if (rn5 >= 35 && rn5 < 55) { l5 = 5; }
        if (rn5 >= 55) { l5 = 6; }
        
        return l5;
    }

    function getSVG(Trait memory trait) internal view returns (string memory) {
        string[13] memory parts;

        parts[0] = '<svg id="terra" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24">';
        parts[1] = '<path stroke="#000000" d="M10 5h7M9 6h1M17 6h1M8 7h1M18 7h1M8 8h1M18 8h1M8 9h1M18 9h1M8 10h1M18 10h1M8 11h1M18 11h1M7 12h1M18 12h1M8 13h1M18 13h1M8 14h1M11 14h1M18 14h1M8 15h1M11 15h1M18 15h1M8 16h1M10 16h1M19 16h1M8 17h1M10 17h1M19 17h1M8 18h1M10 18h1M19 18h1M8 19h1M10 19h1M19 19h1M8 20h1M11 20h1M18 20h1M8 21h1M12 21h6M8 22h1M12 22h1M8 23h1M12 23h1" />';
        parts[2] = '<path stroke="';
        parts[3] = baseColorOne[trait.base];
        parts[4] = '" d="M10 6h7M9 7h9M9 8h3M9 9h2M9 10h2M9 11h2M8 12h3M9 13h2M9 14h2M9 15h2M9 16h1M9 17h1M9 18h1M9 19h1M9 20h2M9 21h3M9 22h3M9 23h3" />';
        parts[5] = '<path stroke="';
        parts[6] = baseColorTwo[trait.base];
        parts[7] = '" d="M12 8h6M11 9h7M11 10h7M11 11h7M11 12h7M11 13h7M12 14h6M12 15h6M11 16h8M11 17h8M11 18h8M11 19h8M12 20h6" />';
        parts[8] = mouthLayers[trait.mouth];
        parts[9] = eyeLayers[trait.eye];
        parts[10] = headLayers[trait.head];
        parts[11] = outwearLayers[trait.outwear];
        parts[12] = '<style>#terra{shape-rendering: crispedges;}</style></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
                      output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12]));
        return output;
    }

    function getOneOfOneSVG(uint256 _int) internal view returns (string memory) {
        string[3] memory parts;

        parts[0] = '<svg id="terra" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24">';
        parts[1] = oneOfOneLayers[_int];
        parts[2] = '<style>#terra{shape-rendering: crispedges;}</style></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        return output;
    }

    function getOneOfOneTraits(uint256 _int) internal view returns (string memory) {
        string[3] memory parts;

         parts[0] = ', "attributes": [{"trait_type": "1 of 1","value": "';
         parts[1] = oneOfOneNames[_int];
         parts[2] = '"}], ';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        Trait memory trait = randomTrait(tokenId);
        string memory json;

         if (check(tokenId)) { json = TerrapinsLibrary.encode(bytes(string(abi.encodePacked('{"name": "Terrapin #', TerrapinsLibrary.toString(tokenId), '", "description": "Terrapins is a collection of 1406 creatures that are utility-enabled PFPs generated and stored on-chain."', getOneOfOneTraits(getIndex(tokenId)), '"image": "data:image/svg+xml;base64,', TerrapinsLibrary.encode(bytes(getOneOfOneSVG(getIndex(tokenId)))), '"}'))));} 
         else { json = TerrapinsLibrary.encode(bytes(string(abi.encodePacked('{"name": "Terrapin #', TerrapinsLibrary.toString(tokenId), '", "description": "Terrapins is a collection of 1406 creatures that are utility-enabled PFPs generated and stored on-chain."', getTraits(trait), '"image": "data:image/svg+xml;base64,', TerrapinsLibrary.encode(bytes(getSVG(trait))), '"}'))));}

        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }

    function oneOfOneMint(uint256 tokenid) public {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Not enough tokens left.");
        require(maxOneOfOneSupply < 5, "Max 1 of 1 supply.");
        require(allowlist[msg.sender], "Not in the allowlist");

        if(ERC721A(terraCrateAddress).ownerOf(tokenid) != msg.sender) revert NotOwnerOfToken();
        (uint256 key, uint256 idx) = _getKeyToWriteTo(tokenid);
        if(_unpack(hasClaimed[key], idx) > 0) revert AlreadyClaimed();
        _setClaimValue(idx, key);

        oneOfOnes.push(_nextTokenId());
        maxOneOfOneSupply += 1;
        allowlist[msg.sender] = false;

        emit claimedIds(tokenid);
        
        IERC20(shellAddress).transferFrom(msg.sender, deadAddress, SHELL_PRICE);
        _safeMint(msg.sender, 1);
    }

    function claimByIds(uint256[] calldata ids) external {
        uint256 length = ids.length;
        require(totalSupply() + length <= MAX_SUPPLY, "Not enough tokens left.");

        for (uint256 i; i < length; ) {
            uint256 currentId = ids[i];
            if(ERC721A(terraCrateAddress).ownerOf(currentId) != msg.sender) revert NotOwnerOfToken();

            (uint256 key, uint256 idx) = _getKeyToWriteTo(currentId);
            if(_unpack(hasClaimed[key], idx) > 0) revert AlreadyClaimed();

            // Set claim status for `currentId` to true
            _setClaimValue(idx, key);

            emit claimedIds(currentId);

            unchecked {
                ++i;
            }
        }

        uint256 shellPrice = length * SHELL_PRICE; 
        IERC20(shellAddress).transferFrom(msg.sender, deadAddress, shellPrice);

        _safeMint(msg.sender, length);
    }

    function _unpack(uint256 slot, uint256 id) internal pure returns(uint256) {
        return (slot >> id) & uint256(1);
    }

    function _getKeyToWriteTo(uint256 id) internal pure returns (uint256, uint256) {
        // 0...254 can be used as the 255th bit is already occupied
        if(id < 255) return (0, id); 
        // 255...509 
        if(id < 510) return (1, id - 255);
        // 510...764
        if(id < 765) return (2, id - 510);
        // 765...1019
        if(id < 1020) return (3, id - 765);
        // 1020...1274
        if(id < 1275) return (4, id - 1020);
        // 1275...1529
        return (5, id - 1275) ;
    }

    function _setClaimValue(uint256 id, uint256 key) internal {
        hasClaimed[key] = hasClaimed[key] | uint256(1) << id;
    }

    function _initialize() internal {
        for(uint i; i < 6;) {
            hasClaimed[i] = 0x8000000000000000000000000000000000000000000000000000000000000000;
            unchecked {
                ++i;
            }
        }
    }

    function checkClaimStatus(uint256 n) external view returns (bool) {
        (uint key, uint id) = _getKeyToWriteTo(n);
        return _unpack(hasClaimed[key], id) == 0 ? false : true;
    }

    function setAddresses(address _terracrate, address _shell) public onlyOwner {
        terraCrateAddress = _terracrate;
        shellAddress = _shell;
    }

    function addToAllowlist(address[] calldata toAddAddresses) 
    external onlyOwner
    {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            allowlist[toAddAddresses[i]] = true;
        }
    }

    function check(uint _num) internal view returns (bool) {
        for (uint i = 0; i < oneOfOnes.length; i++) {
            if (oneOfOnes[i] == _num) {
                return true;
            }
        }
        return false;
    }

    function getIndex(uint _num) internal view returns (uint256) {
        for (uint i = 0; i < oneOfOnes.length; i++) {
            if (oneOfOnes[i] == _num) {
                return i;
            }
        }
        revert("Number not found in array."); // revert if _num not found in array
    }

    constructor(address _terracrate, address _shell) ERC721A("Terrapins", "TERRA") Ownable() {
        terraCrateAddress = _terracrate;
        shellAddress = _shell;
        _initialize();
    }
}