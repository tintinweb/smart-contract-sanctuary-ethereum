/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// File: contracts/IERC721A.sol


// ERC721A Contracts v4.2.0
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
// File: contracts/ERC721A.sol


// ERC721A Contracts v4.2.0
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

// File: contracts/RoarClub.sol



pragma solidity >=0.7.0 <0.9.0;




contract RoarClub is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAXIMUM_SUPPLY = 10000;
    uint256 public presalePrice = 0.08 ether;
    uint256 public presaleMaximumHoldingsPerHolder = 3;
    uint256 public publicPrice = 0.1 ether;
    uint256 public publicMaximumHoldingsPerHolder = 5;

    bool private allowMint = false;
    bool private presale = true;
    bool private revealed = false;

    string private revealedBaseURI = "ipfs://CID/";
    string private notRevealedBaseURI = "ipfs://QmQvKWJdn2s6YHWhmTSv1y3t7GQ7p84xaLmmnQRLz9Yto9/";

    mapping(address => bool) private presaleWhitelist;
    mapping(address => uint256) private presaleMintQuantityPerHolder;
    mapping(address => uint256) private publicMintQuantityPerHolder;

    event MemberReservedTotal(uint256 amount);

    constructor() ERC721A("Roar Club", "RCO") {
        _mint(0xBAD7f3B9Fe2DE230Fdec0f10cDD70AB43F2c2c1f, 3);
        _mint(0x25f97C1c0Cac9207186B566EE191360ED256416B, 3);
        _mint(0xFEee490c7F2944022c6CE25A285F4501B322cbed, 3);
        _mint(0x621027DF468ee49B29E931568dACf12824A4ca84, 3);
        _mint(0xd7A90717C955BcF19dBDE72687bb901184FA8Ad7, 3);
        _mint(0xD0c1CFfF980C9608B6F356F1e7c62042A2986AC0, 3);
        _mint(0xADE0788F9a732dbe52AE7CdF5e4Fe0dB72f7Ff66, 3);
        _mint(0xA5c554a9aE0b9C54b346aaDfFCdC3D455Fd3bFc1, 3);
        _mint(0x78f5AC24b641C23e42C9059F89d27818E1323278, 3);
        _mint(0x2DAE972bFC378fcC16701CC76286d552589f3F56, 3);
        _mint(0xe078a4029f2a8db5A50cd522f84F878AC9cD5A8A, 3);
        _mint(0x7301be38468cBB3784A385b1cf247FDF80631A78, 3);
        _mint(0x5dA8C072cE311D7129E7d2216b7497e624dceC45, 3);
        _mint(0x261F2A87eBCF59ce2668Fb3bEb6184433E6405ef, 3);
        _mint(0x49779F34A4cD539b7aA8df58E92d1d90A09A3c90, 3);
        _mint(0x46Df4501196c747C92670543f57C168fd57a16CD, 3);
        _mint(0x7aB7E5Dd408441d00811ba073FbAa0E62b752345, 3);
        _mint(0x462ca2Be187cd64060678e0b027D5853F8de1ba7, 3);
        _mint(0x07F5093Df1Ff499051B821B2D301a9141624322B, 3);
        _mint(0x59610f7a28Ef8221160dE691D385281285221469, 3);
        _mint(0x3aA3F8c0d9F70569A951d2359324e1AE9d578d97, 3);
        _mint(0x1d3a4d05e3C8C25fFCcae2BBCb67B2EC4C7d9650, 3);
        _mint(0xD47079251450d44005Ac30c4CA338E9C874eED92, 3);
        _mint(0x899913Fea631FFE8E970D9b8AA58223C23fd3EA3, 3);
        _mint(0x936fF8D0B9D960DFb73A7455A265A74326222527, 3);
        _mint(0xEa4926A3cE47B3b192481968F2A70327548041F8, 3);
        _mint(0x0A15D6eaE84c9cA5a112669551Ec24fD53E6c222, 3);
        _mint(0xE943f9901EAA787278DABDB4Cd3ccF78d0DD308B, 3);
        _mint(0xFe5FB7eB44caF144321D2212168A7fe59D5ED2aE, 3);
        _mint(0xB97626AfD74E49C65E382F453362f5Eda2117eCE, 3);
        _mint(0x922221e1F3c92C5cf76B4231dCFd294AadD05f38, 3);
        _mint(0x3E4F212eD2EAE859D24587862a80392494B32036, 3);
        _mint(0x053C05A30bAa89C624266759B66F72E2e28645ea, 3);
        _mint(0x8AE4825b9E4264e82941b66D2B804cebCffC0e5F, 3);
        _mint(0xA1191E7CeF910072740c3c2867ad0504c443E42C, 3);
        _mint(0x26227faF16C00bEcA97Ca91f730Fc8507354fa60, 3);
        _mint(0xf3B6068a6Ae17b9c37B5aF27757A4a63AD7565eB, 3);
        _mint(0x913e17b71307EaDF11a0238c0b571f7b38153708, 3);
        _mint(0x53989AA83b5E73732b24247353BDFf050a23303d, 3);
        _mint(0x085fd0D0b2De3586077D2C5A1281c08ca56c6650, 3);
        _mint(0xE7731811B1a45658A007Bb9DcF61e846348F6695, 3);
        _mint(0xd9e465295A13ed25226f7b684DDF1804d088dACB, 3);
        _mint(0xF6B4aF3de4889f43D006BcEcA5b6e0368E7620ce, 3);
        _mint(0xF8e6571645d5dB5A59E4184B07A8BF7b04B5dB32, 3);
        _mint(0x54f9E925c22c910170Cb49C8Fe3AC26422d3A30a, 3);
        _mint(0x9EC262ccfc6217cFE83dE207C2086C6708b99f36, 3);
        _mint(0x4c063103AFa727Fcf89139943Ac8823be23477A7, 3);
        _mint(0xe17Ca60cBB7E7BeF2a78027B5627f70D21A5C523, 3);
        _mint(0x201ba29E991274D84e092539fED2156c2979f12d, 3);
        _mint(0x3b2fF091e0d7cf55bB87DE225A40bf577132aFBf, 3);
        _mint(0x32676f8b659B04406822165b88e7574A382d9082, 3);
        _mint(0x467ef500769bb4208D8d462354790678b8338331, 3);
        _mint(0x3C883639411D5053692839e1ceB7878EE4c6501C, 3);
        _mint(0x9694c517b61671EF2D91DF71dAf530735b640Fd9, 3);
        _mint(0x71DB616ac262eDC0C87283386C3d1f9780c679D8, 3);
        _mint(0x91FA0a32AD123cb890eE645dF793Bf63a1A063cC, 3);
        _mint(0x675De6D6cB22eED3DAF0BCdb3408aCBe743EDF66, 3);
        _mint(0xcC9B3539e57001EdDfB521243D4da00393EfDBd6, 3);
        _mint(0xAA32daBb84DE51f0eD3850E7483f181D3d106B4E, 3);
        _mint(0x2a49E20195E722811E7215f64C5F4b635e9D64c6, 3);
        _mint(0x6310596C3568d3B51BFD49447F671Ec43f6db77F, 3);
        _mint(0x98Bff09b73C946d04EE48Dfe53DC2984762b1E6a, 3);
        _mint(0x484D42b5D7bD6DbA26Aa618eDDe29a5Ba777d5A6, 3);
        _mint(0xD0C590F7B41153988A3837b7FF0a476763D0D895, 3);
        _mint(0xc2495539587d5Cc8cd7Bc40686F3e5C006206305, 3);
        _mint(0x4278F6Fa68DAa9C42BAd0c122DaDf183De75B535, 3);
        _mint(0xbC5F70D73f97cCA7E72B3DF62d71BAE941b60b4f, 3);
        _mint(0x79C4ca68939F059A3176BA99d6cdc257279f80B8, 3);
        _mint(0xe4Fa3A953Db192745F5d0807f079c115262208e8, 3);
        _mint(0x288E453043B5609A87B1D6a856f59Aad5Dfa4437, 3);
        _mint(0xd497241619010E5d37C235E5e0DeA485645603be, 3);
        _mint(0xe93a6C35708F6940461797be57C4649B3b3acdB9, 3);
        _mint(0xC4C7ab2e3f90f78926e76b9684EAf2852CCf3e83, 3);
        _mint(0x6bA81C0C95EA19d248741c76CA71bBD255442496, 3);
        _mint(0xD3D3eBD383d1Ff85eB4B24E8735a58f5160Db572, 3);
        _mint(0xB1143E5363158aBD1d3e988eccAe4099264c73ca, 3);
        _mint(0xFf48Ff2814F57F84732366b819232BECDF3BA826, 3);
        _mint(0xE4dEF841D29635604ddd1a4eF2d163cfc26a32f8, 3);
        _mint(0xdbb7F23F97F9Df18Ee3E0d2BF73E952106Fdf049, 3);
        _mint(0x35a18BD98e5EB67EC989dFb64B06cc7c522685A7, 3);
        _mint(0x6d471422a855B499464eF97f31B880693A469192, 3);
        _mint(0x7419d8404ee6354Ea305725ED435135bF655F1F8, 3);
        _mint(0x2659caB3C56e654F62D02c203FB96fCc38F03062, 3);
        _mint(0xA5f2C5Ce4eCC79ABb1A3671f020ce664f0e4B1E3, 3);
        _mint(0x81Bc1CD5811Cf578c9Fc54e7f7954F9D5B45D956, 3);
        _mint(0x1b32dA60489DE3Fe0c6398c21D0b1CdEbeEaD4DD, 3);
        _mint(0x4c1597f1C65bc95a5F7831643B631262744AB663, 3);
        _mint(0xD2eB07b66A790bA2132aE95D2fD49b3c4528edfb, 3);
        _mint(0x060f36d6EEAf8A89f226d9C42d33df564773bA29, 3);
        _mint(0x78627243b800697612B93a823c1E16A7B165c706, 3);
        _mint(0x348eBCa3f1482287EBa4d40e1E34F4A2a5ecC113, 3);
        _mint(0x77898a01aeE8d184250468Dd049333262235401A, 3);
        _mint(0x105A9da4E37Fe355350610E0Aa97570709912990, 3);
        _mint(0x0bABCB5719A30f5238082b20ACD0dFF17582e6Cf, 3);
        _mint(0x03495185e86d354eEa486680eF14026A961Fb459, 3);
        _mint(0xAB6762274b3716ff29cf16b7d4B0A26be1aA0136, 3);
        _mint(0x92e3bE37AcC398484dbA8f8bA4B89B512041C202, 3);
        _mint(0xcda7e8C665Bf0Eb1E2A94eab14de92059f35a87b, 3);
        _mint(0x882383A232362F1e1cd3Ba09991C5c2C93Ac8F8C, 3);
        _mint(0x637cba0CC95884817CD63fe0147cf403505b2Ced, 3);
        _mint(0x1Ef661C462781700332F2e67397e293e0dEa8468, 3);
        _mint(0x93c090e4289bE0fb97CCcF94c4115a9509B92868, 3);
        _mint(0x42de51b67082C179B31A4aA2Ee47BD1975CAa5df, 3);
        _mint(0x71ef49A06C737ca8DbB59549C45fDDaf16f3D24B, 3);
        _mint(0x37f832b84631cC796485d578Ffcca484e6008205, 3);
    }

    function mint(uint256 quantity) public payable nonReentrant {
        require(allowMint, "Not yet on sale");

        if (presale) {
            require(msg.value == presalePrice * quantity, "The amount you paid is incorrect");
            require(presaleWhitelist[msg.sender], "You are not eligible for the pre-sale whitelist");
            require((presaleMintQuantityPerHolder[msg.sender] + quantity) <= presaleMaximumHoldingsPerHolder, "The mint quantity exceeds the holding quantity limit");
        } else {
            require(msg.value == publicPrice * quantity, "The amount you paid is incorrect");
            require((publicMintQuantityPerHolder[msg.sender] + quantity) <= publicMaximumHoldingsPerHolder, "The mint quantity exceeds the holding quantity limit");
        }

        require((quantity + totalSupply()) <= MAXIMUM_SUPPLY, "The mint quantity has exceeded the maximum supply quantity");

        if (presale) {
            presaleMintQuantityPerHolder[msg.sender] += quantity;
        } else {
            publicMintQuantityPerHolder[msg.sender] += quantity;
        }

        _mint(msg.sender, quantity);
    }

    function airdrop(address to, uint256 quantity) public onlyOwner {
        _mint(to, quantity);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = revealed ? revealedBaseURI : notRevealedBaseURI;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function getCurrentPrice() public view returns (uint256) {
        if (presale) {
            return presalePrice;
        } else {
            return publicPrice;
        }
    }

    function getCurrentMintLimit(address add) public view returns (uint256) {
        if (presale) {
            return presaleMaximumHoldingsPerHolder - presaleMintQuantityPerHolder[add];
        } else {
            return publicMaximumHoldingsPerHolder - publicMintQuantityPerHolder[add];
        }
    }

    function getRemainingNft() public view returns(uint256) {
        return MAXIMUM_SUPPLY - _totalMinted();
    }

    function getPresalePrice() public view returns (uint256) {
        return presalePrice;
    }

    function setPresalePrice(uint256 _presalePrice) public onlyOwner {
        presalePrice = _presalePrice;
    }

    function getPresaleMaximumHoldingsPerHolder() public view returns (uint256) {
        return presaleMaximumHoldingsPerHolder;
    }

    function setPresaleMaximumHoldingsPerHolder(uint256 _presaleMaximumHoldingsPerHolder) public onlyOwner {
        presaleMaximumHoldingsPerHolder = _presaleMaximumHoldingsPerHolder;
    }

    function getPublicPrice() public view returns (uint256) {
        return publicPrice;
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function getPublicMaximumHoldingsPerHolder() public view returns (uint256) {
        return publicMaximumHoldingsPerHolder;
    }

    function setPublicMaximumHoldingsPerHolder(uint256 _publicMaximumHoldingsPerHolder) public onlyOwner {
        publicMaximumHoldingsPerHolder = _publicMaximumHoldingsPerHolder;
    }

    function isAllowMint() public view returns (bool) {
        return allowMint;
    }

    function toggleAllowMint() public onlyOwner {
        allowMint = !allowMint;
    }

    function isPresale() public view returns (bool) {
        return presale;
    }

    function togglePresale() public onlyOwner {
        presale = !presale;
    }

    function isRevealed() public view returns (bool) {
        return revealed;
    }

    function toggleRevealed() public onlyOwner {
        revealed = !revealed;
    }

    function getRevealedBaseURI() public view returns (string memory) {
        return revealedBaseURI;
    }

    function setRevealedBaseURI(string memory _revealedBaseURI) public onlyOwner {
        revealedBaseURI = _revealedBaseURI;
    }

    function getNotRevealedBaseURI() public view returns (string memory) {
        return notRevealedBaseURI;
    }

    function setNotRevealedBaseURI(string memory _notRevealedBaseURI) public onlyOwner {
        notRevealedBaseURI = _notRevealedBaseURI;
    }

    function isPresaleWhitelisted(address add) public view returns (bool) {
        return presaleWhitelist[add];
    }

    function setPresaleWhitelist(address add, bool whitelisted) public onlyOwner {
        presaleWhitelist[add] = whitelisted;
    }

    function getPresaleMintQuantityPerHolder(address add) public view returns (uint256) {
        return presaleMintQuantityPerHolder[add];
    }

    function getPublicMintQuantityPerHolder(address add) public view returns (uint256) {
        return publicMintQuantityPerHolder[add];
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}