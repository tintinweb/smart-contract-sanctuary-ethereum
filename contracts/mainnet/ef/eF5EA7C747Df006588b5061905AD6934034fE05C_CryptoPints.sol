// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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





abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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
        return 1;
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

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC721A {
    /// @dev This event emits when the metadata of a token is changed.
    /// Third-party platforms such as NFT marketplaces can listen to
    /// the event and auto-update the tokens in their apps.
    event MetadataUpdate(uint256 _tokenId);
}

//
//
//       C     R     Y     P     T     O     P    I      N     T     S
//
//                        100% ON CHAIN SVG BEER
//
// 
// ChatGPT, please create ascii art of a pint glass of beer with foam at the top
//
//
//       /     \
//      | () () |
//      |       |
//      \=======/
//      (#######)
//   ,--,\_||_/`--.
//  //  (\)   (/) \\
// ||___/`|   |`\\___||
//      \  \   /  /
//       `wwwwwwww`
//
// ChatGPT, please try again but this time draw the beer in a mug
//       .---.
//      /     \
//     | () () |
//     |   _   |
//     \_______/
//    _/_____\_
//  //|||||||||\\
// |||||||||||||||
// |||||||||||||||
// |||||||||||||||
// |||||||||||||||
// `"""""""""""""`
//
// XD

contract CryptoPints is ERC721A, Ownable, IERC4906 {


    struct TraitVals {
        uint256 btype;
        uint256 gtype;
        uint256 bg;
    }

    uint public maxWalletFree = 10;
    uint public MAX_SUPPLY = 1000;

    mapping(address => uint) public mintedPerAcc;

    enum Step {
        Before,
        PublicSale
    }

    Step public sellingStep;
    
    //aohell.eth
    address public constant OWNER_ADDR = 0xcaDE4B581E3aB2bE3F74422ae0954013E9BFf478;
    
    constructor() ERC721A("CryptoPints - On Chain Beer", "PINT") {}

    function mintForOwner(uint quantity) public {
        if(totalSupply() + quantity > MAX_SUPPLY) revert("Max exc");
        require(msg.sender == OWNER_ADDR, "No");
        _mint(msg.sender, quantity);
    }


    function renderSvg(uint256 tokenId) internal pure returns (string memory svg) {
        string memory col1;
        string memory col2;
        string memory bgcol1;
        string memory bgcol2;
        string memory bgcol3;
        TraitVals memory traits = getTraits(tokenId);

        //Beer colors
        if(traits.btype < 4) {
            col1 = '6a2f1a';
            col2 = '2c1206';
        } else if(traits.btype < 5) {
            col1 = 'bfef0f';
            col2 = '475910';
        } else if(traits.btype < 14) {
            col1 = 'fff5ae';
            col2 = 'e1ae29';
        } else if(traits.btype < 20) {
            col1 = 'efa00f';
            col2 = '593610';
        } else if(traits.btype < 28) {
            col1 = 'f6ce51';
            col2 = '856617';
        } else if(traits.btype < 32) {
            col1 = '7e1305';
            col2 = '2a0402';
        } else {
            col1 = '371205';
            col2 = '070301';
        }
        
        // Re-use strings to prevent the smart contract from exceeding size limits.
        string memory bubx = ' r="3.4" fill="none" stroke="rgba(255,255,255,0.5)" stroke-width="1.5" transform="matrix(.568 0 0 .563 ';
        string memory anim = ' 5000ms linear infinite normal forwards" transform="';
        string memory stk = '" fill="#fff" fill-opacity=".5" stroke="#000" stroke-linecap="round" stroke-linejoin="round" stroke-width="';
        string memory foam = '" fill="#fff" stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="m';
        string memory line = '" stroke-linecap="round" stroke-linejoin="round" stroke-width="';
        string memory fill = '" fill="#fff" stroke-width="0" opacity=".5" rx="';
        string memory cub = ';animation-timing-function:cubic-bezier(.42,0,.58,1)}';
        string memory tt = '{transform:translate(250.0px,226.3px) rotate(0deg) scale(1,1';

        svg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" id="g" width="512" height="512"><style>@keyframes g-u-fgts{0%',tt,');',cub,'26%,70%',tt,'.15);',cub));

        svg = string(abi.encodePacked(svg, '50%',tt,'.1);',cub,'to',tt,');}}@keyframes b2t{0%{transform:translate(252.4px,350.7px)}60%{transform:translate(252.1px,335.5px)}to{transform:translate(240.9px,176.6px)}}@keyframes b2c{0%,60%,to{opacity:0}90%{opacity:1}}@keyframes b1t{0%{transform:translate(256px,350.7px)}40%,to{transform:translate(265.4px,180px)}}@keyframes b1c{0%,40%,to{opacity:0}30%{opacity:1}}@keyframes b3t{0%{transform:translate(257.5px,326.9px)}28%{transform:translate(252.3px,328.1px)}68%,to{transform:translate(249.2px,174.1px)}}@keyframes b3c{0%,28%,68%,to{opacity:0}58%{opacity:1}}</style><defs><linearGradient id="gf" x1=".5" x2=".5" y1="0" y2="1" gradientUnits="objectBoundingBox" spreadMethod="pad"><stop id="gf-0" offset="0%" stop-color="#'));
            
        svg = string(abi.encodePacked(svg,
            col1, 
            '"/><stop id="g1-1" offset="100%" stop-color="#', 
            col2, 
            '"/></linearGradient></defs>'));
        
        if(traits.bg == 0) {//british
            bgcol1 = '252320';
            bgcol2 = '472525';
            bgcol3 = '321515';
 
        } else if(traits.bg == 1) {//dive
            bgcol1 = '825f3f';
            bgcol2 = '724c28';
            bgcol3 = '58391c';
        } else { //irish
            bgcol1 = '2d3e2d';
            bgcol2 = '49331e';
            bgcol2 = '352618';
            
        }
        svg = string(abi.encodePacked(svg, '<g id="g-u-bg"><rect id="r10" width="512" height="512" fill="#',bgcol1,'"/><rect id="r11" width="512" height="213.7" fill="#',bgcol2,'" transform="translate(0 298.3)"/><rect id="r12" width="512" height="213.7" fill="#',bgcol3,'" transform="matrix(1 0 0 .161 0 477.6)"/>'));

        //shadow
        svg = string(abi.encodePacked(svg, '</g><ellipse id="g-u-sw" fill="#050505" fill-opacity=".1" rx="73.2" ry="22.8" transform="matrix(1.154 .21 -.244 1.34 218 350.7)"/><g style="animation:g-u-fgts',anim,'rotate(-.2 54708 -60181.4)"><g id="g-u-fg" transform="translate(-250.6 -219.4)">'));
        
        //Glassware - Boot is 2x rare
        if(traits.gtype < 4) { //American and Imperial Pint
            svg = string(abi.encodePacked(svg, '<path id="j-pint',foam,'18.7 71.4 122.7.8-1.5-22.3c.6-17.7-120.3-16.5-120.5 0v13.8l-.7 7.7Z" transform="matrix(1 0 0 1.512 172.3 67.8)"/></g></g><g id="g-u-mp" transform="translate(172.4 100)"><path id="g-u-og',stk,'5" d="M34.8 267.1C29.5 202.8 23.3 135 22.5 127c-.3-3.5-'));
            if(traits.gtype < 2)
                svg = string(abi.encodePacked(svg, '9-14.5-10-26.7-.7-11.3 6.4-23.8 5.9-27.5l1-30 120.5.2v30.4c0 2 7.6 15.6 6.5 29.1-1.2 15.5-11 31.2-11.3 33.7'));
            else 
                svg = string(abi.encodePacked(svg, '3.6-50.5-4.1-54.2l1-30 120.5.2v30.4c0 2-4.6 60.3-4.8 62.8'));
            svg = string(abi.encodePacked(svg, 'l-9.6 130.4c.7 10.8-20.2 18.2-43.9 18.4-14.4-.4-49-6-46.8-17.9" transform="translate(.2)"/><path id="g-u-ig" fill="url(#gf)" stroke="#000',line,'5" d="m28.6 74.2 102.8.5'));
            if(traits.gtype < 2)
                svg = string(abi.encodePacked(svg, 'c-.2 1.6 6 13.5 5 25.7-1.2 13.1-9.5 26.8-9.7 30.2'));
            else
                svg = string(abi.encodePacked(svg, 'a4901 4901 0 0 0-4.7 56'));
            
            svg = string(abi.encodePacked(svg, 'l-4 72.7-3.8 44.7c-.9 8-11.5 12.8-19.3 12.8-9.9 1.7-31 1-42.5-.4-6-.4-13.4-7-14.1-14.4-4.5-50.2-8.8-86-11.2-114.2-.5-5.8-')); 
            if(traits.gtype < 2)
                svg = string(abi.encodePacked(svg, '9-19.6-9.6-32.2-.7-12.8 6.4-24.3 6.4-25.4Z'));
            else
                svg = string(abi.encodePacked(svg, '3.2-56.5-3.2-57.6Z'));
            svg = string(abi.encodePacked(svg, '" transform="translate(0 -.3)"/><ellipse id="ke1',fill,'4" ry="22.3" transform="matrix(.653 -.06 .214 2.316 47.2 191.1)"/><ellipse id="ke2',fill,'4" ry="22.3" transform="matrix(.962 -.03 .015 .49 33.4 98.1)"/></g>'));
            
        } else if(traits.gtype < 6) {//Pilsner
            svg = string(abi.encodePacked(svg, '<path id="j-p',foam,'208.9 133.2c-1.3-20 94.5-19 94.7-1.3l-1.1 23a399.2 399.2 0 0 1-93.2.7l-.4-22.4Z" transform="matrix(1 0 0 1.01 0 -1.4)"/></g></g><g id="g-u-p" transform="matrix(1.004 0 0 .997 -1 .7)"><path id="g-u-og2',stk,'5" d="m212.4 130 88.2-.2c1 19.6-12.3 122.5-21.4 205.8-4.4 15-2.2 32.2 6.5 31.8l-4.8-5.5c6.9-.3 16.4 4.7 20.5 8.7-24.3 10.5-69 11.6-92-.9 1.7-3.2 10-7.5 20.5-8L224 367c7.9-2 12.3-17.1 8-31.2-9.6-95.9-22-195.4-19.7-205.7Z" transform="matrix(1.066 0 0 1.038 -17 -9.4)"/><path id="g-u-ig" fill="url(#gf)" stroke="#000',line,'4" d="M221.5 167.3c32.3 1.7 58.8 1 66.2-.7 8.1 3.4-7.2 89.3-15 168.3-9.3 4.8-27.7 5.9-36.4-.2L219.7 181c-.4-6.8.2-14.7 1.8-13.7Z" transform="matrix(1 0 0 1.052 .3 -20.8)"/><ellipse id="ke3',fill,'4" ry="22.3" transform="matrix(.713 -.066 .305 3.297 236.3 241.2)"/></g>'));
        } else if(traits.gtype < 8) {//Stange
            svg = string(abi.encodePacked(svg, '<path id="j-l',foam,'208.9 133.2c-1.3-20 94.5-19 94.7-1.3l-1.1 23a399.2 399.2 0 0 1-93.2.7l-.4-22.4Z" transform="matrix(.81 0 0 1.387 47.7 -46.7)"/></g></g><g id="g-u-l"><path id="g-u-og4',stk,'4" d="M215.6 373.2c19.2 10.4 58 10.3 77.8 1.4v-51.1l.3-197.8c-21 2.9-59.7 4-78 0v247.5Z"/><path id="g-u-ig" fill="url(#gf)" stroke="#040303',line,'4" d="M222.3 171c16 2.6 49 2.4 66.3 0l-1.8 183.4c-11.8 7.8-41.2 11.2-64.6 0V171Z" transform="matrix(1 0 0 .999 0 .3)"/><ellipse id="ke8',fill,'2.3" ry="52.2" transform="matrix(.937 0 0 1.484 230.4 264.1)"/></g>'));
        } else if(traits.gtype < 10) {//Weizen
            svg = string(abi.encodePacked(svg, '<path id="j-w',foam,'207 130c5.1-9.8 95-9.6 97.7.3a57.4 57.4 0 0 1 6.3 34.8c-23.7 3.2-88 3.5-111 .4.2-9.8 3-27.4 7-35.5Z" transform="matrix(.81 0 0 1.387 47.7 -46.7)"/></g></g><g id="g-u-w"><path id="g-u-og5',stk,'4" d="M215.6 373.2c15.8 7 58 6.6 77.3 0-.5-36.7-6.4-94.8 0-141.7 6-43.8 12.8-62.7 1.7-103.2-21 2.9-61.2 4-79.5 0-7.6 40.5-7 61.1-1.6 103.2 6.4 49.5 1.6 106.9 2.1 141.7Z"/><path id="g-u-ig" fill="url(#gf)" stroke="#040303',line,'4" d="M219.7 185.2c15.9 2.6 53 3 70.3.6-3.6 21-8 62.2-8.6 82.4v91.4c-15.9 6-41.1 4-54.4 0l-.3-91.4c.2-20.9-3.4-62.4-7-83Z" transform="matrix(1 0 0 .999 0 .8)"/><ellipse id="ke9',fill,'2.3" ry="52.2" transform="translate(235.4 300.1)"/></g>'));
        } else if(traits.gtype < 11) {//Boot (rare)
            svg = string(abi.encodePacked(svg, '<path id="j-b',foam,'207 130c5.1-9.8 95-9.6 97.7.3a57.4 57.4 0 0 1 6.3 34.8c-23.7 3.2-88 3.5-111 .4.2-9.8 3-27.4 7-35.5Z" transform="matrix(.94 0 0 .91 15.3 25.4)"/></g></g><g id="g-u-b"><path id="g-u-og6" fill="#fff" fill-opacity=".5" stroke="#000" stroke-width="5" d="M207.3 142.5c24.8 3.9 73 4.5 96.5 0 5 21.8 4 67.2-.6 94.5-4.1 18.7-10.5 90.2 1.5 119.5 3.2 12.8-2.4 30.2-13.4 27.7h-29.8c-6.2-10-29-.7-46.6-.7l-53.2.3c-20.6-1.5-21.8-32.1 6.8-38.7 33-8.9 58.2-23.8 44-82.2-8-35-13-95.7-5.2-120.4Z" transform="translate(.3 .3)"/><path id="g-u-ig" fill="url(#gf)" stroke="#000" stroke-width="4" d="m217.2 176.4 80.5.4c4.3 1.2 3.4 19.3 1 37.4l-6.3 35.8c-8 29.7-7 78.4 0 90 5.8 13 6.5 31-12.1 30.5-12-1.8-34.6-1.4-45.3 1.5-23 3.3-58.7 4.2-70 1.6-11-3.1-11.2-16.4 0-19.9a205 205 0 0 1 28.4-7.3c28.7-5.5 37.7-44.5 31.3-78.4l-11.3-51.4c-2-15.5-3-38.7 3.8-40.2Z" transform="translate(0 .4)"/><ellipse id="ke10',fill,'3" ry="4.1" transform="translate(165.2 364.1)"/><ellipse id="ke11',fill,'3.6" ry="18.5" transform="translate(221.5 204.3)"/></g>'));
        } else if(traits.gtype < 13) {//Tulip
            svg = string(abi.encodePacked(svg, '<path id="j-t',foam,'204.6 128.6c5.1-9.7 99.1-9.4 101.8.5 1.5 9.7 3 28.4 5.5 35.9-23.8.5-89.2.2-114.2.5a190 190 0 0 0 6.9-36.9Z" transform="matrix(.81 0 0 .876 47.7 65.5)"/></g></g><g id="g-u-t"><path id="kp4',stk,'5" d="M212.6 179.4c20 5.5 62 5.2 84.2.9-.5 30.4 7 40.6 12.7 55.7 18.9 50.6-13.3 84.1-54.2 84.1-47.2 0-73.7-36.4-56.5-83.9 7.3-19.9 16-34.7 13.8-56.8Z"/><path id="kp5',stk));
            svg = string(abi.encodePacked(svg, '5" d="M275 364.8c-8-7.7-12.4-26.5-7.1-44.7H242c9.1 20-8.3 46.7-5.9 44.7-13.9 0-31.7 2.8-32.3 7.3-.2 9 101.5 8.5 101.5 0 0-3.3-19.4-8.2-30.3-7.3Z" transform="translate(-1)"/><path id="kp6" fill="none" stroke="#000',line,'3" d="M276.7 369.4c2.8 3.6 10.6 7 16.2 5.9" transform="translate(-2.6 -3.9)"/><path id="kp7" fill="none" stroke="#000',line,'3" d="M236.1 366c-.9 3.4-8.8 5.6-16 4.9" transform="translate(0 -.2)"/><path id="kp8" fill="url(#gf)" stroke="#000" stroke-width="4" d="M215.4 217.3h76.4c4.9 9.7 12 26.9 13.5 35 7 33.6-20 57.6-48.5 58.8-27 .5-58.8-19.7-53.7-58.7 1.9-8.7 8-26.2 12.3-35.1Z" transform="matrix(.986 0 0 .98 3.7 5.1)"/><ellipse id="ke12',fill,'4.4" ry="15.2" transform="translate(212 265.4)"/></g>'));
        } else {//Goblet
            svg = string(abi.encodePacked(svg, '<path id="j-g',foam,'203.5 125.8c13.1-11.1 92-7.6 100.6-.3 8 6.6 8.9 31.4 9 39.6-24 .5-117.4.7-117.4.7s-.7-33.3 7.8-40Z" transform="matrix(1.085 0 0 .542 -23 120)"/></g></g><g id="g-u-g"><path id="kp9',stk,'5" d="M191.1 197.4c20 5.4 100.5 5.3 122.7 1 7.8 24.2 9 47.9 9 66.5 0 31-24 56-67.5 55.2-47.2 0-68.7-30-69.3-56-.4-20.7 2.1-47.3 5.1-66.7Z" transform="translate(-1 .5)"/><path id="kp10',stk));
            svg = string(abi.encodePacked(svg, '5" d="M275.1 365.7c-10.4-7.6-12.8-25.5-10.4-44.8l-22.9.2c6.1 19.2-7.2 46.5-4.7 44.6-14.1-1.3-33.6 2.3-33.4 6-.2 8 101.6 9 101.6.4 0-3.3-19.3-7.5-30.2-6.4Z" transform="translate(-2.2 -.2)"/><path id="kp11" fill="none" stroke="#000',line,'3" d="M276.7 369.4c1.8 3.4 10.6 7 16.2 5.9" transform="translate(-5.1 -4.2)"/><path id="kp12" fill="none" stroke="#000',line,'3" d="M236.1 366c-1.7 3.7-8.2 5.8-16 4.9" transform="translate(-1 -.8)"/><path id="kp13" fill="url(#gf)" stroke="#000" stroke-width="4" d="M200.5 218.2H307c4.5 9.4 7 33 6.5 43.8 0 31.7-21.7 50.3-59.5 50.3-35.6 0-59.3-21.6-58.8-55 .2-10.5 1.1-29.3 5.3-39.1Z" transform="matrix(.986 0 0 .98 2.7 3.1)"/><ellipse id="ke13',fill,'4" ry="22.5" transform="translate(208.9 251)"/></g>'));
        } 
        svg = string(abi.encodePacked(svg, '<g style="animation:b2t',anim,'translate(252.5 350.7)"><g opacity="0" style="animation:b2c',anim,'matrix(2.036 0 0 2.1 -199.3 -517)"><circle id="ke15"',bubx,'100.6 250.2)"/><circle id="ke16"',bubx));
        svg = string(abi.encodePacked(svg, '94 244.9)"/><circle id="ke17"',bubx,'101.8 242.2)"/></g></g><g style="animation:b1t',anim,'translate(256 350.7)"><g opacity="0" style="animation:b1c',anim,'matrix(1.651 0 0 1.588 -161.6 -390.9)"><circle id="ke18"',bubx));
        svg = string(abi.encodePacked(svg, '100.6 250.2)"/><circle id="ke19"',bubx,'94 244.9)"/><circle id="ke20"',bubx,'101.8 242.2)"/></g></g><g style="animation:b3t',anim));
        svg = string(abi.encodePacked(svg, 'translate(257.6 326.9)"><g opacity="0" style="animation:b3c',anim,'matrix(2.036 0 0 2.1 -199.3 -517)"><circle id="ke21"',bubx,'95.7 255)"/><circle id="ke22"',bubx,'94 244.9)"/></g></g><ellipse id="g-u-r',fill,'15" ry="2.6" transform="translate('));
        if(traits.gtype == 10) // Boot, move reflection
            svg = string(abi.encodePacked(svg, '282 377)"/></svg>'));
        else
            svg = string(abi.encodePacked(svg, '253.7 371.4)"/></svg>'));
        

        return svg;
    }   

    function uint2str(
        uint _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function getTraits(uint256 _tokenId) internal pure returns (TraitVals memory) {       
        uint256 btype = uint256(keccak256(abi.encodePacked(_tokenId, "b1"))) % 35;
        uint256 gtype = uint256(keccak256(abi.encodePacked(_tokenId, "g1"))) % 15; //rare boot
        uint256 bg = uint256(keccak256(abi.encodePacked(_tokenId, "bkg1"))) % 3;
        return TraitVals(btype, gtype, bg);
    }

    function mint(uint quantity) public {
        if(sellingStep != Step.PublicSale) revert("Not Live");
        if(mintedPerAcc[msg.sender] + quantity > maxWalletFree) revert("Max exc");
        if(totalSupply() + quantity > MAX_SUPPLY) revert("Max exc");

        
        require(tx.origin == msg.sender, "No");

        _mint(msg.sender, quantity);
        mintedPerAcc[msg.sender] += quantity;
    }


    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function generateAttributes(uint256 tokenId) internal pure returns (string memory) {
        TraitVals memory traits = getTraits(tokenId);
        string memory btypeName;
        string memory gtypeName;
        string memory bgName;

        if(traits.btype == 0) {
            btypeName = "Brown Ale";
        } else if(traits.btype == 1) {
            btypeName = "Barley Wine";
        } else if(traits.btype == 2) {
            btypeName = "Oxidized Homebrew";
        } else if(traits.btype == 3) {
            btypeName = "Porter";
        } else if(traits.btype == 4) {
            btypeName = "Dyed Green Lager";
        } else if(traits.btype == 5) {
            btypeName = "German Pilsner";
        } else if(traits.btype == 6) {
            btypeName = "Vanilla Cream Ale";
        } else if(traits.btype == 7) {
            btypeName = "American Lager";
        } else if(traits.btype == 8) {
            btypeName = "Cerveza";
        } else if(traits.btype == 9) {
            btypeName = "Hazy IPA";
        } else if(traits.btype == 10) {
            btypeName = "Pale Ale";
        } else if(traits.btype == 11) {
            btypeName = "Munich Helles";
        } else if(traits.btype == 12) {
            btypeName = "Kolsch";
        } else if(traits.btype == 13) {
            btypeName = "Czech Lager";
        } else if(traits.btype == 14) {
            btypeName = "Octoberfest";
        } else if(traits.btype == 15) {
            btypeName = "Amber Lager";
        } else if(traits.btype == 16) {
            btypeName = "Dopplebock";
        } else if(traits.btype == 17) {
            btypeName = "English Bitter";
        } else if(traits.btype == 18) {
            btypeName = "Strong Ale";
        } else if(traits.btype == 19) {
            btypeName = "Marzen";
        } else if(traits.btype == 20) {
            btypeName = "IPA";
        } else if(traits.btype == 21) {
            btypeName = "Double IPA";
        } else if(traits.btype == 22) {
            btypeName = "Belgian Tripel";
        } else if(traits.btype == 23) {
            btypeName = "Blond";
        } else if(traits.btype == 24) {
            btypeName = "Saison";
        } else if(traits.btype == 25) {
            btypeName = "Gose";
        } else if(traits.btype == 26) {
            btypeName = "Vienna Lager";
        } else if(traits.btype == 27) {
            btypeName = "Triple IPA";
        } else if(traits.btype == 28) {
            btypeName = "Sour";
        } else if(traits.btype == 29) {
            btypeName = "Red Ale";
        } else if(traits.btype == 30) {
            btypeName = "Lambic";
        } else if(traits.btype == 31) {
            btypeName = "Wild Ale";
        } else if(traits.btype == 32) {
            btypeName = "Dry Irish Stout";
        } else if(traits.btype == 33) {
            btypeName = "Imperial Stout";
        } else if(traits.btype == 34) {
            btypeName = "Oatmeal Stout";
        } else {
            btypeName = "Porter";
        } 

        if(traits.gtype < 2) {
            gtypeName = "Imperial Pint";
        } else if(traits.gtype < 4) {
            gtypeName = "American Pint";
        } else if(traits.gtype < 6) {
            gtypeName = "Pilsner";
        } else if(traits.gtype < 8) {
            gtypeName = "Stange";
        } else if(traits.gtype < 10) {
            gtypeName = "Weizen";
        } else if(traits.gtype < 11) { //boot is rare
            gtypeName = "Das Boot";
        } else if(traits.gtype < 13) {
            gtypeName = "Tulip";
        } else {
            gtypeName = "Goblet";
        } 
        if(traits.bg == 0) {
            bgName = "British";
        } else if(traits.bg == 1) {
            bgName = "Dive";
        } else {
            bgName = "Irish";
        } 
        
        string memory attributes = string(
            abi.encodePacked(
                '{"name": "CryptoPints #',
                uint2str(tokenId),
                ' - ',btypeName,
                '", "description": "100% on-chain SVG beer.", "attributes":[',
                '{"trait_type": "Beer", "value": "',btypeName,'"},',
                '{"trait_type": "Glass", "value": "',gtypeName,'"},',
                '{"trait_type": "Pub", "value": "',bgName,'"}'
            )
        );

        return attributes;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {

        // Get the attribute values
        string memory attributes = generateAttributes(tokenId);
        string memory json;

        json = string(abi.encodePacked(
            attributes,
            '], "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(renderSvg(tokenId))),
            '"}'
        ));
        
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));

    }

}