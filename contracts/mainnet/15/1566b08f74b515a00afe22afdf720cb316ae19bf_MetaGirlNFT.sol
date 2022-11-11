/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT
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

// File: erc721a/contracts/extensions/IERC721AQueryable.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;


/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// File: erc721a/contracts/extensions/ERC721AQueryable.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;



/**
 * @title ERC721AQueryable.
 *
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) public view virtual override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] calldata tokenIds)
        external
        view
        virtual
        override
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view virtual override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view virtual override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// File: @openzeppelin/contracts/utils/StorageSlot.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// File: @openzeppelin/contracts/utils/Arrays.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Arrays.sol)

pragma solidity ^0.8.0;



/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    using StorageSlot for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
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


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: nft.sol









pragma solidity >=0.8.13 <0.9.0;

contract MetaGirlNFT is ERC721A, Ownable, ReentrancyGuard { //Change contract name from SampleNFTLowGas

  using Strings for uint256;

// ================== Variables Start =======================

  string public uri; //you don't change this
  string public uriSuffix = ".json"; //you don't change this
  uint256 public cost1 = 0.09 ether; //here you change phase 1 cost (for example first 1k for free, then 0.004 eth each nft)
  uint256 public cost2 = 0.11 ether; //here you change phase 2 cost
  uint256 public supplyLimitPhase1 = 0;  //change to your NFT supply for phase1
  uint256 public supplyLimit = 5555;  //change it to your total NFT supply
  uint256 public maxMintAmountPerTxPhase1 = 1; //decide how many NFT's you want to mint with cost1
  uint256 public maxMintAmountPerTxPhase2 = 5; //decide how many NFT's you want to mint with cost2
  uint256 public maxLimitPerWallet = 20; //decide how many NFT's you want to let customers mint per wallet
  bool public sale = true;  //if false, then mint is paused. If true - mint is started
  address ownerAddress = 0xE28EB45ADA810F189b3590cCA42C7D0bB39582FE;
  address []whiteList = [
    0xb93240eEfC9f413718f48D3A83ECF5EeAE7da548,
    0xA9019Dc69D56D06513aFFe6DA5FbbAd780703f6B,
    0xe2b333472D5E057f3CD97EFba9CEd649178CD709,
    0xf5dDF3bC5412404888aE3737d27CAB95A7815047,
    0x7D750E148b5CE034ddb1E9B78b05F33883276A8b,
    0x41A101010c285759a6659341EDE97e5c51A61762,
    0xcedcDCf6EBC6de622Dd30cEE62dd814324e8cF3f,
    0x6b3d3f65B9B07F7F284c9710d6567985831A8A40,
    0x7Bd4d4c34AF69Ddd42f5dd253972Ae4f6508b807,
    0x08eB577CD1A6D1369a27dBff3d01128426C85ceb,
    0xa0d7fa8d410C5e2aF1b303cE961fe62Cf2286274,
    0xdA21f46FD5910B11ba5CB87169B51532cB0C7a3B,
    0xa8cD3353dC70795587D9dFEC47a2e4bb83a418Fe,
    0x4dfcC0e9e91841E052433eDF2a167ae2854cB041,
    0x8894E0a0c962CB723c1976a4421c95949bE2D4E3,
    0x45639d5749800043Be53CBb3d230E5E1BDfE7057,
    0xd731D8867636458c5e3D168618B7a0E12dEaA183,
    0x00E6E1646e852b73a8b3551fA2491E129F229d03,
    0xd07A099CF8C41367Cd58fD7C464bb5Aed1779dB7,
    0x7DA58feDa03D7eb4a8576935472b5FC386e91fdD,
    0x3536436261FF94e92e34B996E7e99FAb068b2be2,
    0x2E60176d5513F2f4CF6cDa65D7D54917a2CE5108,
    0x305C140c63D102A0fa0b0790c8e81c373a2608F3,
    0x95894362e65bBBcc759fb6ad49bBC0ea00E3a537,
    0x5BdF7d0983b440CFA579E759277566dd12FecB3B,
    0x18525CaB1F59cBCe1E4cA0E17D2F338F313d2ec2,
    0xD1bfa89a608fa634FE939528344a861e057CeEB2,
    0xD6F7b023D4b0E2b9E0e46714f82B534620B33Fc7,
    0x1B96923185B2e28dC8B01ccAb547430DEFDAB558,
    0x434aBA557E4e9e7b515d723e766879db39a52EC5,
    0x7f6729A5c9DCDc45D67Ff60eC1debFD41c8251C7,
    0x99CfDDE600461CE68158C12A2a43f81204a8650F,
    0x6004442B3807b07b7901A2e25AcBc08710284886,
    0xf30521EA797cA641154dA330b45B8813CBe3c70a,
    0x96D4c9a1c0667bd3495BcfaB43eDff384a39b570,
    0xc72A5aF624895c4E970039e8EC9486b5c1E6409D,
    0x40B7dB765E388AE6182d271f290705ba279B8DD1,
    0x54bb6B5e388f4Ba44CD91F4A93406Ac19FC8F076,
    0x60Ad67e9A9004F036f9A47912bC44E98AD2c0713,
    0x25b75A6E15aC0407D5FDeF3c13287F5bb03EF36c,
    0x1BFDB1E3e5B575c3eFFc46b39CCE39fa06eC9937,
    0x0A9b0B463aa3DF2CD980d406F2cBd6bCC4535398,
    0x2DB9E3c241732A30966e452CEDD23F6F06d15C6E,
    0x402CF2a606C39BfA74Fe67C447A7f53E90982D7B,
    0xf114e031E672aC5b07e70E87a3FD972956609652,
    0xd5E4929C4A3F7E5DE1E752Fd587863996354Eac9,
    0xA88AF173D5F5608c7ceBB952fB60D88B68a98063,
    0x57C7C0B2C5bb7a589E1Ba5d924B124B4226F762D,
    0x6a17590b8698f1877b4E2393403827fB769669F3,
    0xD57FB3570A499c9c85C62aD42E4C2112B2316df3,
    0x023Ce50C7cD19C10877b21572F15a79Bb8d1E5c0,
    0xeD8B8E30127c03B8388C2981890E4ccF43075A39,
    0x316B4E1f6150F7FC8F665c03f3b09818D15cF027,
    0xBBD62C50d6f13D9Df02293D6833FaDd07051dbBD,
    0x9eDd8B491eaceEaec73AF425eCda8FC85adCEF4f,
    0x322f0aA7be025CcD43cbECa1e5F3389de8392052,
    0x77aa9604d47da56Dd60e3DFF50D5892965BA2460,
    0x15952692B8Cc7Dd971ef86124FDF4c67Dd620744,
    0xbf64443B2948F3F874168A2E4CC15447E944Ee24,
    0x87f609e5a457a094BDCffA001B3DD29B1228fEb0,
    0x43691CB76b397c9377857B10B9277422bcF36996,
    0xAa73A22a7c06ee84A6F2b131521e619F25Ef2604,
    0xbE15B1dc7a15004E29821C24e1D45316a87Ad8c5,
    0x79B58023A40CD74471ae9a987328426bfba48809,
    0x459bcDB430CD5a7833BC13BD85011A1DB273d72c,
    0xBC965Af2a4A1c352533703421Ef68dc517461AC2,
    0x3A26B28B8250f178306eEEc843791a45A0A47a1c,
    0xBc0E361d3C34aeAFb74940ed11A3CE5552B1d59B,
    0x2B23032A28fdcD5c54A6e3c326258DF235F095fA,
    0xf59602558AAdFD938266cCdb26a02f611ae67996,
    0xc6dc72A169dB64D8d8e626B8179fAE5deDfBC515,
    0x3f269EEd2D775d7CBfaF5a16dAa16dfa7c16F029,
    0x595Edc62f310D0d9A8Dc8B1ae0D49a82eB01Abf8,
    0x3aFC24B0DA3a580a804F79641539EE40F8b51053,
    0x82267fA358E674bb208CfB755c8B9EdDE4F4f1f0,
    0x082c58Ce5380D10EeF09d2F5f6B69679cB34e79a,
    0x70f03fcc045DBD4FF9c7921B56D453ec569f4C32,
    0xc3E6c455e722EcdE2f97CAbEc48fF30feE7E0527,
    0x6Efb3c2328c4871e25FBA6c656333Af2fa795085,
    0x23919795153d18b683a133c2c327E88dd63Fd737,
    0x05586Db5F7c69Ca721331b777c32e8A26d4F756b,
    0x53f66AD68A7866a167200cD51a1e19beF5d0589F,
    0xce00915A0a19426BED026aFAF71b12E6d1Fa44b8,
    0xaF5E6a9D47Eae02e12Dd94698F1F6Fd4CF53A42c,
    0xc6D21203d8aC1b407f74a70d848D94fB708dBD61,
    0x8c3F1b7103E5fcE176DdB82A98D0C62D83f91124,
    0xc82e2CFb1316F236AEbBDDbb9d0B36deD16e9F05,
    0x2f902C2664adB96256249f3716405F68788a2775,
    0x934C490c7349C07f4D542d43befD36cDE153Ad2B,
    0xde8533263eE99b73A794bFc7235c5A15BA95B8E4,
    0x4Ab3E9e35fBC6208Ae912f363E46378E01ee7E92,
    0xe44D61473e3816DEA491Df3797167988D1A22Fd2,
    0xe4a29c222D9E865be1f43709A85f4c0564F8Cebe,
    0x1d127664a694b52094a062C4457590225e10a99b,
    0xBA0043996FAccEc7Eb1B511B4597AC282CAedAe5,
    0xc10963a2e1622f2778d6e014CFF098D1D7533F1c,
    0xfA3E69A3370c9Fe2C0d4e0A4dcF581852a31f8D2,
    0xD429681fb77990953462EE849F72c8295147AFBF,
    0xF6220B408A816D3E0D179016d64C6925A0f4931f,
    0xAf3931735CEC388a21Eafb6e142b39Cd303AeC8D,
    0x2a1b7bb93be2a28d4D7F963D5abd1C3bF4784f09,
    0x3D327eC0f4A78506835B461e4a57Aca395ddCb0c,
    0xA2ecDddef5177dd6998B25Ead1b0E32ba4908ed0,
    0x71F318f22bD81d53E69E5a2eB276e2D1AFF67DC5,
    0x770381D6D409d02A86Aa0eD547C66378dD3942C5,
    0x6A7D2094F4e8C28Effb4d43218591a0b5E75d6b9,
    0x42D09977643aC3c5103185bAAfD05b6b67Fd85Ac,
    0x41C2d59C6e0af4C2e88197f2797b4555D6B2A20d,
    0x2205a14465222eA481e158A8D1f255cdF8Fb13b8,
    0xc842FB276CA7E469475F0415820DFd536e23ebfb,
    0x890A5aBF109A5baE1B05980A9757E474d4500701,
    0x948B2BeC5BB6427f96D815131b1a99EE6BD3B0d3,
    0x36C94241ba98b4e2B8e5626fd6FCFcE7FbA74721,
    0xd67e789Ec9095FdEc5546D40Dbe3eF6cF3C4C793,
    0x6dE0c6a06224b5F257918487930Ab85C655bA0ae,
    0x238692B1036c036eF680DB6dA16Ebdb93AbBDfAE,
    0x56Ee30Af211A36b28A2d6Cf8Bc7340f818af8fD4,
    0xEE46358C95D7995eFC34260D34DfBe0a2FE23a5E,
    0xf634Fff316cFb6A393304AD5BA9702D0b3F46Cc8,
    0x1a75AC8b15dE0746Dd58398B88A44c0F8Bc41cA5,
    0x1faAF8a7465244925B9834a11D3925fF1E029Ab1,
    0x580D71e75E9ff44A9FF32DFa7f821aac9EEDBe52,
    0x23a1514B22334414a39977a065B386A100f05616,
    0x78670591a782A18a6C45b91ef2F70Df3B323Ca02,
    0x2f3Cdc57d32e0508fe73B623A3B923F681967D1F,
    0x0e1a9cB362CcF6eC890F61A0fb9ABF3aD763971B,
    0x154e1a03ce606C2B82C2C40A8998aBEb6aA2AD7f,
    0xc5239f18cBCC8e4330db5d0943f97689900E99bB,
    0xb120b0f055E647AF4a81328bB766775b9b078E35,
    0x78F247B5184B932b753810501eAC5eaA067B288E,
    0x2309a3C3D0e834B259dC61C4E58AA597d0fA0365,
    0x0b3c5888096A96B8D1E7C0fFdA4C8F0e2947D70f,
    0x7f04aF32bE37aCb96c94A2f7a25c86947416e5ee,
    0x2931B169D77c93ee39999a707FC3c250fdf16c42,
    0xc77FE4c0f5854A674Ab2392F5104664C3611Aa5f,
    0xEa5A4d77c0Cf8d136AA1352B584Ca8f123Ef4FF5,
    0x13Be22ca6e19Ed5aC300e276b0e8c28C4e205870,
    0x51697559c03A61978cD9f04F7b79B33747227613,
    0xA5b05d7b52a0853e00AfB0F36b7a0508F632aeEb,
    0x3fC1f92DfcbB062F7329E1Ea0dDFA2c4cD126aE5,
    0x59FE900a58d054e2a25e0a385f8cc9149585431b,
    0x11edbC9FdEFA432e71bF0357eB000C5e1AaBc8Be,
    0x1DEC0660C3C70da7D80303D01BaFf9d8b0C44442,
    0x2515e3Cdc2428D805c1B2507764fcfA9a671BF09,
    0x2271D7f44d9373247852417273b0B00614860152,
    0xDe846D545fA09B0bc102EcDFD5E30E001deBE12B,
    0xe9A5ef9e8bE5baD90a784770Ca5F5D68076B32D2,
    0x7c9391bCc07909b3a939209d719FD50cB9cD3a94,
    0x2563770988996dff96E0f93E823D233F01af96b6,
    0x6ad8f842a6c973aE5612f84F1E14470674473548,
    0xF01b0daBD8067CAa892E3d95c1a6aC17eB5B2113,
    0x4a005960B97BFd172FcE5a1b76e0C888174c334e,
    0x2bcB1D02bE9A3CbE3e979ff33e0ffDa39aE30643,
    0x987a55e2Fa8Cae74AC03fA957E5a09BD6d7A2b5c,
    0xb39aEE4101437A33BD0b0F31412A502D6dD097ED,
    0x0539ddbE49a98e8525C07087B3bDA50316F3eb7f,
    0x5ac50Ea3A77048c66E85F4CBC4D0AFB4AeBA0589,
    0x144C556FE9a7E9b0A6736A2311AA2Ef8D41204f3,
    0xF7be97c2B9055134c6b686269fd54309aBa3A8c2,
    0x807Ca5e597f12bFe849deCa251D158425bEa099c,
    0x461De63d15B483C46A10E394D4AC08Fa3581C011,
    0x682A6C33E9Edb1eBFA01c18D442457e3B35A7e23,
    0x2bdFA3590A05369e37f419D35287ED1365B904d9,
    0xCF24D00696931A5cCc5F8d3F931FEd2B100df8A2,
    0xe1D8D29BA56043ee1Fb908D805a3d5CBe49fBF0c,
    0x4Dd3425436C3a6fa416f542F6D4bCBd2281A53d9,
    0xb23940919097Cc15171a1eeA57Ba74f628a6e902,
    0x45aA6478474259075a128b180ba9Ff3B5bcD6343,
    0x17D8B4b6DD34BDd88C35d0cf3aA49Ad2E533237a,
    0x875334F18C2243a9466aeB1357Fa985857774A86,
    0xB9cF5601dCF561d544a82578759304338F280c3B,
    0xDDbA6F535002b2b131B5BD108564689c5DeFf8ef,
    0xbD183737aF6f9DF3C3987cc93364682683a4333A,
    0xce64d50E930b0138c10109CdE036044BCFcE213d,
    0xdF549a7BCE82AC22074501dFEa8AA7aFB9642aeC,
    0xeafC971591Fd1B995C5a01fCF95E61DD6000E7a1,
    0xcafD049d0F65A6EbAaFCe8697c8ef243871Bcffd,
    0xCB64E31a95D4238a29D0fA6e30B87efd3FAead54,
    0x1089162bcFf05473D2156064b36A5fb57cC77F1f,
    0xDe68a3155D64B5F6B8fAd0e4e5CF4fC17cE5346d,
    0xF60dD7E8EAaCd5E16454D65178a576c9804E77Fe,
    0x80D66c88bF1dBf4b6f6192b6025594F753Ad3B7e,
    0x567935C6Cc4CFFe5d335A3e8c7D45A97063F0878,
    0x4a003D049B5Bdc48321053c92E37e48f78F03E16,
    0x9a50535f5f6F07622FA3ae4DAA4289b94A97056b,
    0x75753E784bDF709F98bD35426d1f408FAB09246e,
    0x3bEb85366085D363E2c5E451Cf1258D6164222d3,
    0x967CabB12d535B7FAbD1461AfedA5774011A418c,
    0x14B28B450Fffff1Fb74EbDbC658914e9f3e14de8,
    0x97ae1B5262F600096906577C3f41607a26e82064,
    0xf592FCC1b47b45b2d7C74183A4b69a4B983278cC,
    0x8d6D12F98399A5d2C5d5D16D37F82CCcFC90aDb9,
    0x9B6fb4dA9bbe7e225F2C0e4Ba7B0b2873ef6F9E1,
    0xdF8cE52F7a50C1ba79D778717D48357Df4d9150e,
    0xA9FA068F60a112475A8C1D2ca12f1c1F241894fa,
    0xA87855c1240DA71060FAe62e7ebc05472746f010,
    0xaE582DAB1d7678F70d5f4e3dA55021031d903aa6,
    0x3310686eC23b093df62CdB00B6d6c35C29e7c287,
    0x56A4c6e9937f466D8ee6Dd4a01279CaDCd6c5b9C,
    0xDE01308893440A9cB97540ee9bbB342a16bEd68b,
    0xD4c10ccC8443C62589b81504191e3EE78D493818,
    0x7C0fe1E86d161252677A5AF2320BF90816711a46,
    0x33bd19463294ccA6d9043D77f3ec125c3bdE4B6A,
    0xDc8d47EB89C72ADFe90dd017b073930666d40027,
    0x5DdCd65f592a6B29Fa9E7147c3D8e9A7D97D953E,
    0xae7bc248d78f649A2aa819E057A9fAf0cC1A8a37,
    0x464720142A0F39E7Da35Be4ED1ef2296f93F7E43,
    0xA9747f0ab52D92Dcd12d86e82DB60c46db926687,
    0xC8aDB0f5e4c58d0cf9AbF735b39f8496EB56920e,
    0x1d8cbA23f5811e29182410Fd662c9a3b0661D115,
    0xa257EecfDCf1c29CCd0063392e6C19FF3a2c0fFB,
    0x1D5A21C64FcF8402F575e2BFa9a8Ec03c5435A4e,
    0x03939E53DD4627F9780550F4FEDAc5715Ae52F99,
    0x32721588FC3A1814Cd04A4f5E71A1F84B14F3DED,
    0x1a3aBf0ee4ccE3e5a9a69fbbDCD9744fa24810B8,
    0x7d86550aCA13995DC5fC5E0Df6c7B57F4d72e714,
    0xd317d2233A19EC8f40675285045f85f6BA89a2e2,
    0x5992f85A2EC32EB337e3955cdf1E1Df1A5Fafe0D,
    0xE3DaEE5874FB91f57ff5985Bb1C678A0038435da,
    0xDaf243495BA9d65cb36C48d9ab639cDD3b6176Ec,
    0x6b65e0beBb03E8Adb0F88bDb49D5Baf5f17EC7AD,
    0xabC57fa5f1B1d8167b09470F9321fd541d8DD716,
    0xf63D47d1B95433B6cCCfcd51EFC9Bd6F9E94Bc3c,
    0x1Edece4649e11D21BA0DcB769a6c07aC847f875a,
    0x613d74ed2B6317b97D6D4B7f37F5c6F6f410835D,
    0xbfEb47eDc734Ca51DD99067Fc4D84Be40b84a593,
    0xA3FD6137663915aD46AbD5bB6Ad1F3c4a67a3337,
    0x7f5cFF0ec16f86E3D263e2b049eDe4c3673fc0d9,
    0x23A7494fEdf00619cfb7423960b58B9B01150537,
    0x8Ada159c55aeb2e5C33FeB89307524e65BFd4179,
    0x66a0c28B872a05167fEcAC11E3d009778eBB4912,
    0xD64B53551353e96025f14f0c8520D001089beBA5,
    0xE700eFd777b9681D6Cfb91ac9b862d4F87DC2a3C,
    0x0FB5F236ef89CB01A431B9D84f24520e1dA4216A,
    0x7563637C873018336279e273B21D9a26C605dFf9,
    0xEf6F6Cc710245299f22cBA022eaac41a97430a0A,
    0x0F29FE31bB9059a50e6e970985cF88E8Cd9FF01A,
    0xDF0783ae4bBC2934BE748f055642c6355dB23419,
    0x012d0DFCA50ff56Bde8FFdaCF37D8B7C446F2b62,
    0x11Df643Cb599E409228cB36e5081fB39E4fBd029,
    0x2F742Ad7Fed4d3a8b499f58fcdf48b372f7A0D42,
    0x137B9d01612ffaA8C79B0Cf48087c09c0C785b18,
    0xE5C16823480e5E315D3d8030295E5A62edaCF396,
    0x8d9045FBf3D2f340a09CEBf114493b31E8651A6a,
    0x1a1e5D6E1f284C3590399Ef604d58cd0714A4fE7,
    0x32F391f732f143e0A2521Aab79FdE657869FCcdB,
    0x50fdD2288632D2BE723fA27e1a4BC5a0d6fea21e,
    0x7b50a63ca93Bff0d929957Ba8f0b2C58D03F0D9d,
    0x866fe24AC43DE21A6cb3AA88Bad0C7f396198EB8,
    0xa71C71E003a990739d58dD9c6CdA162220993B8B,
    0x36cd1487Bb08b8a1BF72Ee61e1453bAd9f70Ce07,
    0xc8a30bcA3e0D789d83A8803897457cB701c94eD3,
    0x52A3A5fee03633De55263A5c8898a0F274Ac6dB6,
    0x01aC6170Cfe8AeB0599791e77D240b5649c82019,
    0xa36cB0c31B072BBa329C8084B83fF42e871EBCF5,
    0xd221B8EfAD2e3F2890Ce1937A0294150D1F26b00,
    0x031eb7A5DAd63990a5cd7Ea9d116Af8B5b7213f9,
    0x8e95f2b22F906f81A9a7a26c9E7030b127e27f29,
    0xebdE42380F31eb3c106D585Fcf2557d2Db4188f4,
    0x8bCf6d2E521C2A57465AD49B021db69260De2A98,
    0x76E251Ece767426b299db46D89A87dE09DB9bD7e,
    0xcf568004C5CB7BaeFC69be6a89c01B6777DD9540,
    0x59D33d909CcBa4EAa47A3eF83CE08D201665571E,
    0x6b3444713018E580E316B0A8622c47274182Bdd6,
    0xceeE078eBA193c7D3b2b238324DF8DDb8Bd2c5E0,
    0x7719Ae2ceAC01845a38d18a1102462B5EEEb295f,
    0x5aC1567Cc699a20cADBfF0aA5786c4793e2C4A9B,
    0x6bff0986E71a028400C934fcDBe825266e7C853C,
    0xEE4216fCb3b67a0a43c0Ce8f0a2d51C83Fb80685,
    0x3878DDc3979B902A62098fbD2887a1EDb0362A6A,
    0x88e95CeAE5250D0d4b7e96c3adFbeffe6739A00e,
    0xAd5BC90fA727602c32F68501FDfeEA4737f9FB2D,
    0x79a893863C102170E65D2aeA2FcfD3fab83357CA,
    0x811f374d325213482f404c174c646ad885f1F640,
    0x6b57BB5B9af31c6D2057c7309D827Ec52e585B59,
    0xE654656db03A5e5445206f78B6BBC2DB341220DB,
    0xBAf85142445C13Eb56c2802fEb78bd0FFE707cd8,
    0xF5E48AaF087bB5EeBB3127e88D161c921529bFFF,
    0x1eDF61D2531fE6a352851dcD2fC5c8d38ec8B72c,
    0x4F03d95aF246C7cbbc9E4fC1859974945ef418a1,
    0x2654A8b74dcAcBfeA10e145E259263835C3E6fbb,
    0x66747cD04d81f46997bd6662FAE236eA9a0D78Ee,
    0xACcA65B6f427CF18580bD44572e4342f7b424050,
    0xAbE13671099b1eaA23B839cd46EDB0DFFa3f1f87,
    0xfb787bD56347d11d7CF661e03Cb7C5bC59Dc7531,
    0x799eA6F7bcf8D00666C2BFa3914A21654cf85EC1,
    0x6BCaAEa0F3be2bBFf1a7dCCA7386b3646B87d8e4,
    0x592467de8e2d90cf2eF255b27D6aCf3AFC32a43C,
    0xb2B0c35500db766675335a10C2EA7adFB63C0B67,
    0x09E7c874004e7504cb2c8CF8D74106f627501A66,
    0xcC956E90F64cae90ADbA4b1c632f83F474232577,
    0x3b3274A643607b840a7C20ecdAE2D619e2E660e4,
    0x6F7e10631AA6c96b9cc6d7373701Ad52e7f94578,
    0xdCE87C8DCE53E9dfacdd34BbcB86EBbE384335Dd,
    0xa1eEc3aB84F04380f4C929c4f638ED26c01C974D,
    0xD0E75C2b537D81A235833D2434b7C89B4e93e193,
    0xEEA857F4413aF5B7eDE6e0593121A56135Fe3963,
    0xe0a449f9bCBd590DF2Fb7B602Cdd72F3650C66a9,
    0x90cD82F4E4357Bc470eDDBCC36c1a9E98FaF9314,
    0x988131b219aF9E535E8faa55e1A4B75D9Ac6D5DC,
    0x96000e00ED499D2c8d530307b5B223333CF4eE87,
    0xB14ac5dc6AB2EeA5B927CCAD21D3D72846CAA690,
    0xb1aa63Aa9A980a5eC01113d0EBF53Dc8993Ede89,
    0x3758088390F24526E957F2afE09c7b3225698271,
    0x7CE662CCd488bdF39Bb60b15c2db0D03f13EC156,
    0x33e30d1A3E92eaFED86F8c7b7Fd1E1224a8efE3c,
    0xCfBc1A0b7EAFD468F127286cb459E4eb1A2F5B91,
    0x0db1042C5427056707709b6A66d4f3345F74AF65,
    0x4da88081dCE5186aeEE8C9e66c6b66F27Df7BFd0,
    0x8Ba31322d8A54A55dF721F45105079Df18d17A3e,
    0xd3D746f59ec8DfD084E77Fd607348d182F8E5df9,
    0x970C603Bd74c30c9991a2F72B41ACAE5a4489E2C,
    0x9B0aE427E72c342389F694ccF86a4E1850e56f87,
    0xba8f403237dDDaEAf4A57bB054192865d8A05017,
    0x4cC8F688eeffe8afad4831280a71470BA02eD8f1,
    0x78b2F470a6aDf790de7127FAA905c6c8d9d58ee2,
    0xa252B1F40D92EA441E9B7dacACD6E26b4b444cFE,
    0xf0bc16b03BfaB60FDE20E616982290C941428E3B,
    0xb9651d54C22486e405F6D7625b0DcFC4A6A99305,
    0xe6b239477dF84f1E21CEF92d77aE7714cB67c58d,
    0x95aE48d7AF3D3Cc2272626E5ADd7f73e9F6a3A85,
    0xB3757c2E6bbcED5876f4b8f62EB23c28ef1E86B5,
    0x8Da2E29578Aa774005478F6f9601a5234a70177F,
    0xFF36D2aBDCD4547Eab240b11d75B887C6407834B,
    0xa0595d62f19c6AB70bd6Efa019FA78DDc4C11Ee2,
    0x97ae1B5262F600096906577C3f41607a26e82064,
    0x209F5fBea7026753976e56B4b5dA9ba21ab625bd,
    0xF71b2B547e090d4FF9b8B5b7f1C6b5bA3FCDcEA0,
    0x2659d12D9669A87e68fbbB0A1dB475c5F0AeC888,
    0x14Fd0c529e69CfF5ED2877Ac4199f6822E9B8D1F,
    0x8FFbc5dE3b06C376633389dd0901C41a3368AE93,
    0xEc8541d68a2f66690c2B45E8908Fde7E3B3e1bce,
    0x5357E4671EAa4a7367921EfC8EB60D56d3650ad5,
    0x25e5bBA1240Ba58041D539026dEDC1b3B1F2CE5A,
    0xf6843599d50f804D1d6Bab9b84137b92ca53f327,
    0xc7Fb3354AD451A36EB56FB18745Fb7Da8B1E328f,
    0x7D260dBAd3cE2412F083e811285471ad2EF2C7Da,
    0x25534daA33848f9824705C41E2e264debabE1a2b,
    0x77F00a4676844AF2C576aB240a423DCd81664c8E,
    0xfE5fc6c54468Ca265c2E17A164788F7A36f2ce05,
    0x4632Fc4C5AC846E70B09F3E8c0168C250278C679,
    0xD7fE1FAc2F93740F72C94D1911b1b7773722126b,
    0xbe4ca71D2511D4DBFD8291c4d850DD1287fFe35f,
    0xf10Dc48a05edF0b4A1e2beEC730b828C7298790D,
    0xe4AB1D2721fac174523c27240dD2347aCd551486,
    0x062fD044F77708a33825fC4F02DbEC39908b0d21,
    0x60938a18B4FBEAD896c208360A597746E9112E36,
    0x6Ec08b7E8b42075302ac052e48AF72904A6EDC5a,
    0xE8d8B73CCC85dEd891ad41893Ebbb0d684350E04,
    0xDc46608e6120AE2f961E40FB46A8767dabE447F7,
    0xDfa52b23296A8De79A03F0d651c677Fee3F7d9A9,
    0x8cB5837Dcc57756d8BE623d39F49e0fe34442076,
    0xe24a01365454B9ecb2bd9556D81E6775141F610E,
    0x067C2105Ce91e6c24Cd5bC10CC8E0Fabb98eAE90,
    0xA5307BA3dFc29bcbc00Cb55C05e27143D3bb0B06,
    0x3f748290F1D81F9082C9428532Dd676a0846d4BA,
    0x1b45aBFD4a82c438f1BB63b691Ac7c662Efcf0C6,
    0x7BB53712Ed8967178796F45EdF1E38537692bAf9,
    0xCB2e9cc7bD81F55dfF32EDf379B544E40A49B781,
    0x3C2526e5a9918dB632b9B82cBe941C64D181d4fd,
    0x2CeF35DDad95CD702aC8bc9ef423aBae9155ee1C,
    0x7a18d45c2a3FD8f27660Cc938b487Db423014c4E,
    0xd143Ba024c21eB7De38aEa6b837Fd902EE8d1bDf,
    0xB5613944f0cf39b6C4CF0f2B422EBdebd67a8233,
    0xC4173Ac2A95f1ba774051774Ec2614bA83fE76c7,
    0x1bE2e5c277f77679888B11c9311680fe873d3a3b,
    0x859507D8EE842Fd2bCb1e046772743a96FeDc768,
    0xdD24e9029a99488d50a69d28D47d7C2A264C0082,
    0x9217d8B3a7036e507e9D04Ae1969E395ca308947,
    0x1379C29f92b887948Bdc2B9714B90f899e5985dd,
    0x13d9Dd731F17cE6c4E32cC362906781bf9412495,
    0xa2C04EDE78Df773809118C76e50C663B4D694386,
    0x8D6E975B4bE278abf35B6f2B35BB1c9D2ed0e709,
    0x86B3E871a2b6e115a3A6349d856c7B1CA987180f,
    0x4DC8a31578803add7245c6E44B94622D79551c6a,
    0x350679CFEE755A0fd5D67dee8b2D4dc21FbD7AE7,
    0x384da359B9a4813Ed68335523247399551af96dC,
    0xBA8716DBDbBF336C560D2C1F36E0875246440716,
    0xb96113EbA0661Aa4163F20400a70035A41988A31,
    0x8385b6AC66dA064ebAfA433c8541e08b15eF7087,
    0xf24Aa4766a06f7E220aa74a248bEDebe93283bA9,
    0x4dA2D1578D837F896cFfCCdb56D8a6EC1892ef98,
    0x40fBE0445A27F525817a9c937dA2B39aD97751f3,
    0x4455Bc56E2A05Ef14B668098AF10Ecd8A36FC369,
    0x89730D25Bf04311E4a0BC806E30c14c7363C8b1E,
    0x90D78255554627b48885a8D74A4AAb9E53e76B75,
    0x6A8104D8E5d0633C32522bbC91C4300aeD0972D4,
    0xde6437a2E366CA80DC5Ba40d16bd9170ffF63608,
    0xDa1a36A5fE04A06C908339d4aaf33659C3367e5e,
    0x84B0D89B2210e8D2Abb70918626aDdEf2bff4A9B,
    0x4D496d81cE5dcD8EA0cC7E7991c4D5C8F67B7e6A,
    0x7EfaF4656300e9Dd6EBb1767810E1c43b2DC08F6,
    0x8c581ACAb1DfcCbA9c8350aC41Ee85b223c9eF5C,
    0xf9385E10B494e5189A995875eDEBeb17382109c5,
    0x2b8D25f067D1E10360434f19DAaCeE7a58330710,
    0xBEF0596D947db3EDE9cB4e45E287c79cEfC4aA4C,
    0x5f999AD7C9f52e382291e132349D897c07E21796,
    0x61ebbCED4166DB4f3b9F6B8E2E3C7406BfACb92e,
    0xBbD775f1aFf3a5B8D6b99967e988C6b6215705B1,
    0xa0708918A0B97f7b2dB4340F88995E5a1855750C,
    0xD3971C3B47Ee1386e5F4e5baE496a91DF99B79b4,
    0xCDcC5335086e1DAAdFC74B6c57E411CB6176685e,
    0x199077b9BaFe1486Eda1fFdC6D3BdcaEd3FB3457,
    0xB28484CAaf4622345A4250b7b365f1D918bFB77b,
    0x07ff65fDB689eBab37559F78ed36AbB415E14E90,
    0x81dd5F47503AB543A8e0Ecf8A0219ee724E56205,
    0xdD950DdbC9fe1a8a75DA310fcCB9d853914f9c35,
    0xB296AB0495e24bF939F7b297F28c8FFdfD96558f,
    0xeF4d2B4420BB04983E226C1FF90B83200a238724,
    0xB55619703A07c82464b93527af2f17Eb94c753Ff,
    0x33e63489139F300C064D23507906F474921d9D91,
    0x30EF80845EeDcbcEeDA4ff64854069F40697CF08,
    0x2f42329B5984D0CC38030F89DC7D3E588fb9e32a,
    0xCb3D2b3BA9c6Ba018D41c2E8Cb44d1A0421Ed21C,
    0x3455E92dd2281BFcB921d343437e6F1DB6603C17,
    0x950551eD4357E1eDF531a13836508a7D9C48543D,
    0xc88910C401AC093017dBd816A7810abE9F8CD13f,
    0x425bE23D00e196a9f4fe5ae7eE2175a423113401,
    0xB81A8E2D33603ca75BF3185e4Dce321174027943,
    0x14658e3d24F926F89Cc6D2d4761e3eAE83c58D93,
    0x2DDC1E6df894dd9a05D0741b9027AE957a4083f4,
    0x97c4A9935441ca9Ee67C673E293e9a5c6A170631,
    0x0c7E4f7608502bA0159E7c535a0967742c961E0A,
    0x10adc62149DcACBB22F6cC3Fc2D66555AD4F1F8F,
    0x7542A0111Fa58A2993952ad2989d7A3542792885,
    0x5912F68bB4971CA6ED3d6214F184681cd570B224,
    0xCcE963f18Cfa8911564dC6C391239A4D4392Eb54,
    0x642adf666fe0ab32324999257b4b24A92F1A9a6d,
    0x4a9025B24B4936Fdd385d0516d3A73c6Dc51E45e,
    0x5307a22215a6EAF67E9F1dea3feDD86452E49E16,
    0xbA1B20E7817045CC6A1aECda35EA7F86c4C61d38,
    0xD48ad0e91F911b1a9f95DbD8b626F10B3683d312,
    0x410986e045227F31DC3439A23539e37C712fB25e,
    0x5a997CCdF57FeE13891995133D8833dB457f65e5,
    0x908c44D464D022F2C44FC1e097224998580ba498,
    0x5726faf2E301D508f4789BfD27459A945E916986,
    0xf95F6B6c2fC2Cb1dddeEC803CEaC38212bf53143,
    0x310e2e62878aa47C8D658bc7925FD13D66C5180a,
    0x3a77534558BB26A7b20dD29Bf66d6B3bD918962b,
    0xc48F8A8510aFd72746BA8701fFDe456F934f5421,
    0x83A0Ece7eE244c083E087585f71c0A10BC794778,
    0xEC7Cb211Faa48c8c20489b0dc606911B6d60Dfc7,
    0x05E8A1B48685b60e571C0fb7CF43Daa56517e94B,
    0x1d935f516D5008Ff3153ab789258Bf5d8cF604f5,
    0x4d36fECeBaF320E167cE70a53fE22fcCe6207250,
    0xf4E4e27C5C4F093a3a98d337514815d5994800F0,
    0xA92013ae28eA3E5a68AF0d649a20b3f4e38ea514,
    0x02f32575761122f0646946909efA7Cc2aa967E58,
    0xfCC8034d0980DD32862Df269c6741F191F703e49,
    0x9390C7f97DbA6c003aE30B26B22b568d2cb2569D,
    0x3da4A39ED23271222145c8188617A743D1b27174,
    0x7D7ee859Df3F417639D61a5954Aa344E5344dD68,
    0x1A29d5F84299A16746eDA6dDeBE5605670EBFb49,
    0xBA975f357ee882da1Af793574Dd7bcfd619e2bdf,
    0xA86B44ec770dfA0Dc0659bDb03CF3FE616655CD0,
    0x4026949c068A96604D09077a6f0A1d1d0dbF1CD0,
    0x5dD033716ED8293638deE697C08c7Dc107aC818C,
    0x82F885F1aDCA2175C7F62DcB85dB83289C03F69C,
    0x9d3E6Fd1df94E5cEa909b3bF57b6b4010fe87C94,
    0xEFBddd3070F9c89dDcb4458eB60779a6B518E202,
    0xd32916E642174D8CCD6938b77AC2ba83D6C0CaCc,
    0xb2b9300475aF157676C44eE64d39a5eB3C294DbD,
    0x9Be3220Bc76247ED56eaEA3F341671B7Be2FeB33,
    0x65749Ca2CD37542DcaEb99b631c2E6122C1e0c5E,
    0x35642B198CC75976fe4ff615967271f4141F6d07,
    0xDd85dC3780F70B2B3e577ce343C3b84E8a36D1Ca,
    0xFF60c990A4D9f9e9F6e76deAA865A4d6a883d201,
    0xfF5D98C2A2EB2f27DA61566c22c4C64639E1AB0B,
    0xf489A90De7fFAe074B2194A04e46c65002493D19,
    0xF1ee8D5A329ee8D51e64105f84A86Bc0b60C9217,
    0x477E9eCe38BE0d791e21D4A1200d700CC84f29f9,
    0x7017fe37EDBe3f04BCaC97a60C2895C537E40619,
    0xC8f402c6d8A39B6adee57a83ca40A2C2B6F05847,
    0x18F294BeEa98566442AFE3269667D5a58630DD5C,
    0x253355696751aEccdF4268c188226C44c5a11c8D,
    0x2c9A5d291c59A17FF751E0A7dB5837E871612992,
    0x083056f046C75A40eb033B7e45089E64Fc66cff8,
    0xD9438b70844D74FfD91b7208D0813a9b289F7216,
    0x389242923bd38d0920Be319660eb331fE3E71313,
    0x5526bA55553325Fd59339CAA75be85F726c31de3,
    0x49EA5aA1089Ab325c53e8526F41ecde0106Ca496,
    0xbc9cD954d21B1fD5Bdc36f73f7685BE29431394e,
    0xC15A4D09f9CE1633995C17F707ff01ab767509D2,
    0xBBfaA3BbdF602C07C09eb085F0F3cD6a2856C8cE,
    0x59f4Eb2766C9031525d1C746E4Dd67798Ed76d3a,
    0x9A32eED2EaDD80952F355b202C14BC4CE25A70Ae,
    0x028367A846BeCaA2f671D44A249cE021cA784760,
    0xCfFef2E1014ea377f8D41716a72109CBc71df2a4,
    0x0E204E46A52f1C701E54eFD525062A4da96f2b59,
    0x64A2ae55019d13918C902b16Bea1214C860D899F,
    0xaf1Dcae6280B1566391E1cCf35bd2402E0c420D4,
    0x9988E85B16acCd740697C5DDa601Fd6F750CD1ec,
    0xDc49105BC68cB63a79dF50881be9300ACb97dEd5,
    0xd9b2a7d587E0FB932127A0027AcF11C1b91394Bc,
    0x90789dbBAAa3f529D077324508eEd40595CC0505,
    0x8D9f95B34Ee97A1cA63b0AD8c559DDC55ae76957,
    0xb612884850F6F2Dd04FB792E5aD4Ff5B67ffEca6,
    0x0b31E1a479F4E2074b37d2F9479eeecdF8CD334A,
    0x867cDAF0513C4B6b4a91cEee5c850c87093e172F,
    0xd9Ba4db1bb833578f9304D31e2E834BbF10800F5,
    0x85F15D0E945D96Cf43a9156BC6ff63f8821b904a,
    0x6197406521aD3AB07293549DF5281E49400EF8d7,
    0xA57B441ce3833c778f6fCCaA31Cb3E4E23C3824e,
    0x407Dc514CA182958564cbdE1A6c39353eA372713,
    0xFD78Bd71776D0F5bd512a99EaD1158Ebe2f0263C,
    0x1CB5b3Aeee28B6f56d6aa1bF279E1b28C557f2e5,
    0xEFcA9FC5c21E4bB113880E99dd6C067C03FAda05,
    0x9228f6Ab228B37b0e3935a446331698662ED0924,
    0xf5f8ec465f112f8061cE958589Ca8602e14c28ea,
    0x316574Fb90657Da36016F4BD5B573f376125578b,
    0xa2DfF5378eC7dd60fDA1fe6b77f554a5829cc38B,
    0x89c9f7756981b45a39Fe6de4c1A2033eD7C08Df9,
    0x8a719Cb6C1fd4e200fbdD14BFfb161cfE1Bc4a2F,
    0x4682F306636843Eb45B8E1eAC55Fe96Ab3469560,
    0x20fcE3A9d525562f8b9807C05eF8265d7B7c8AD1,
    0x4b97661f7C93Ab7F4204E365556c8E937C10836F,
    0x9eFFAC6BbEb661B3a964256999a128F4e43EEF1d,
    0xADD09050C4cEf2bcAB06DfF0a133EC8EfF198f0d,
    0x0d96AD8611A92EA434585eeA619b3831AB971cEB,
    0x920f8EeECFFdcb7F9A951C05821bFC909132d5A8,
    0x9b5f981B45B42dC748149DF982AdedA4038d55Ab,
    0xCe8B5F3f8B8520391c27C466F27273Bce6beA4Df,
    0xfB5A41A4d690F15baec40d1D231ced776C107475,
    0xF4Ca4Fc6Efedb972056E4D2707848b3C5657ce5d,
    0xaB779C827E7113a642C643eCaec27BaBf1e75870,
    0xcEF6FcB634C53901b9Aa54A5B82DD1D854Fd80b8,
    0xdCA477380D7C900E837893e005095Cc4Ae4b8109,
    0xAd67b094051B154F536772Dc442d8efe63be0F1E,
    0x39219EA64b27a8921977B3870Db74F7e132AFcc7,
    0x04453C4a56c9eAddf4141Fb64365cc69c2438Fc4,
    0xE1E2bd7A980Ef5f3248F69d6a5085b659007e954,
    0x720579e98ce71D9cFac9AB371B52D8Dcd483889A,
    0x5479B817E0C5969b661eF32e8398F499Af222304,
    0xA63DFB14FcB155dc21F3D41fe80c2C1908B958dc,
    0xd49A936b293986640Bc127874b0E7cA73185A2d4,
    0x6990001fa57c1c1e71682169F06A10f0e080777c,
    0x6e1cF94C71f9da360E3b70aD64F70A6aE99d021e,
    0x273B8feb49c6593c9Abc9BcD4C2F19fe4dEa5E10,
    0x08669D367EE2eea3FcB5914a0Da66eF831908C60,
    0xB5028425De4E09cBA0964198215Cab849C8B9125,
    0x130728D74D255F96Ad0007Beba24911660863cf0,
    0xCD901aD883c5B0524F12B297C53f9d23cAf7eeFc,
    0xB7C627E62B2F6446e84b164052E02DDC118E8a63,
    0x1f6a939584721f487CeF15b8B115825cE4d77d66,
    0xF9D4EB2fF3C4Ca6c431eb9C938030F8Db85dC673,
    0x901F0Dc53aa8E5Eeb005EF3648C3e4cE9B6d5418,
    0xF6b9452286EC9D03aA6ACBb74BF1194716996E20,
    0xC2946f834197fBed96a7114e4A46e4500F6Cd94e,
    0x662b4c90aB3F14497f73F2Bd928c5D9Af82e21aa,
    0x83581aF980043768E5304937372d73DBaF0CfAFa,
    0xb411E7f8182BB0c3516D72d32352c0B8f6ba783c,
    0xeceE32feCEa53710C95977607121AE9243974584,
    0xFF274763062ab364fE17d17Cc1CC10Fa9E41E040,
    0x1090095D1743ef20cCebc3eDf6b35E405C7d34d0,
    0xff513d6bDF13EAB951ad657BE8e9359aE6DcB4Fb,
    0xD00686af39c9972a579cF50769cC7db61eFED157,
    0x689ED058DCcF671c7a4244380167d7Bc4cC8DE4C,
    0x8f193C9DDe694c02941194b2928D2B6B0EED3bc4,
    0xF9044bE73929c0FD4359448E9cB671f13DA394C4,
    0xC0609a194c9ee47a7d961710b4c86BA9F12eFc22,
    0x2987C05FF89d3f4EdDa0b9643D697d06108b586f,
    0xA83C05E35e7BDaf7Ae2Ab577F8fc9BaEA6a84a43,
    0x592467de8e2d90cf2eF255b27D6aCf3AFC32a43C,
    0xb2B0c35500db766675335a10C2EA7adFB63C0B67,
    0x09E7c874004e7504cb2c8CF8D74106f627501A66,
    0x76fE7D0fcC1b8419190eA0f81Ba3D5BDb408bDA9,
    0xcC956E90F64cae90ADbA4b1c632f83F474232577,
    0x3DB5F1FDDf2B37caf6c738579bd7A20eA31eB0b9,
    0xC30252464235b00e5848c9493b6c506948D82e79,
    0x08A1AEa178ffa972Ba24594fC140B50A3B392770,
    0x3f25589561a9A96653C7A2B3CF80fA42Ec01BA0A,
    0x619EEcd30bE9C263bA30942e236753A1a41b98DA,
    0x0054FCDdB5bd94820458a30B7d61736373FD8fd7,
    0x9B9D7fF60a6aE74F6F9b4577B44433153649EBf1,
    0x858342645F66e85a35a6a114215208f73e1A15F9,
    0xA826a718B8Ec38A99b55fb15AFD05611EeBb3Ae6,
    0x68AD1Fa00cB9D499B73e85c6449766374463B6B2,
    0x7D496FA21bff41e6ed56A23F9680DA369686F34b,
    0x441A8d90509F4De9a8352e82838Bdf9896b88629,
    0x8C18593b91782047C64761456fe53b23d5034191,
    0x24D06f674bba9760192DB8456C1E77C5d5518c66,
    0x88F97AA340DD26aA51fb880C587346b103129be7,
    0xb6451C0df926907A1F7883b2c0cEaCBc35680537,
    0x6dd6325C196bfFdC80ED63f1F16698Fe37F54B9c,
    0x124bcF206F1581C1D2d2a86310470825C8e65BeC,
    0x9B6186143AbF6506416aCfA01ed3dC997e2BA9A9,
    0xbdc280b126397Ce11A0775A77dDf9a18A43E7B58,
    0x758BF7889DDeF7E96B4296d32a086c66d853807c,
    0x47b799C0f4240a84b2301606DD90ACfA55f35354,
    0xd4E673945c2702Ff763cfd76343a4ff8EA0B62dB,
    0xdE06f40F1Af5a70191cDBC2BCE312cf9eCAf5301,
    0xa3b99313f9DBfdB0899c2f8a370F4F2D67B7DEFF,
    0x6dDF54D654d417c87ae3E056F3709317fE97EBeB,
    0xD39872438EEa76855Ac5cF8C120Dc334B43E61a3,
    0x1B992f0c26A89d364D5A055B24e02E10316e5589,
    0xA106460E9d4390C184CDFE1616a8Cec750DB0644,
    0x4c6bAa42d449C7703f05DCa8c5b4D4cf4E9193cF,
    0xa10516ab9f7a0B9811326ed065E2B6d371A910Ab,
    0x9ca330a6edCFca9A788Ab6f9E110fF0FBdFEE0a9,
    0xaA9d12F9BE44eb06F10F1837325ED17E44457bFf,
    0xEB1Eee982A0817f48b664Ba5a047A3Ff853992dC,
    0x8DCf76075fDce932c3b1aEb93A9ff9d3FE310274,
    0x64FFeE184881c440e85e39C19897939feD3D1F3f,
    0xdF8Fd0A1015Fc6F45BB43CDceF0FeeCdC7E259Ed,
    0x75e35526E73Aa95fa35382E5E3639b91629a1009,
    0x864Cb63AAEbf6ef34D239a7d9B2b2ecdeFb7B007,
    0x0EaC33E3A7b6539c8f00109eB91e3fE30362f345,
    0x1B4F17BE7CbAae9851C917b28F00b65417dF48Fe,
    0xe4Ae02ecFEA8ED71CdD52b98D1322dB5a781f6bA,
    0xf4F6C488BC08c5fFc14C52f38E0Eb60C02bE2Bc5,
    0xC25F4E4eFbb2554f36198911d095f84207f4de2B,
    0x3CD01adfc7DB3AbE646E3977cf70FB3b452d7f57,
    0x2161f18b1BFf32Bd89aBd15c281606F401De7492,
    0xA7A884C7EbEC1c22A464d4197136c1FD1aF044aF,
    0xBD20D738b7eFbD054cD87A6c92A0b20a4E403a14,
    0xc60E9b772fC1f9Ac271bacbecF71Db141fE07F15,
    0xD5686204415fD30939F85649FeADf241995A8eda,
    0x4fDf81caDDf6C1CA706F601573d9fD3d4AA9929d,
    0x1Dc76e7a8ccAFB6C528D1ABb225043DE43C39641,
    0xbdc280b126397Ce11A0775A77dDf9a18A43E7B58,
    0xE5EF5D1688a13Ce64d4152cf959B989b9afc5Fa1,
    0x46eF07Ae079aB487411eBB54818C7fEb9Be327C7,
    0x35b708DaDcf93685B4D508378C9D1d96d00685f5,
    0xE66bDec76D73D5DFD86C162aadab611516fA1658,
    0x6582cd15fE09713421452CFD94FeA30666F172C1,
    0xd6C56802799951F5db3aFbDA4F6dDD678780357a,
    0x4aC183F2dC1E022c135cA56D599f4e9D2D95eD38,
    0x3C4e81fe0504CBCA8177752Df47FA42444277851,
    0x9F3b5940e1f45ce0b643BBcF650C11936E23Ee59,
    0xc45b6586Da4d7a9366f7475C2Ab25a6723d1Cf09,
    0x5F685EE19EB661a207538a022FC3De380E8cAdCf,
    0xBe7a342614635f5d8F132cf041D057F7537Bf6ea,
    0x950B24B05676f1287eE80f17CFa9D30d510F1F79,
    0xE31C233f58219aD25025D3b31519Ca3c2f7Fa4a8,
    0x66720831aA42F371a415C4c80425e3ddF527f8E3,
    0xcbF5895af0C15D5d7140FDc43612637cBBC94705,
    0x5a0001F09012fd3Ab2F7c43Dd0b8fb50271D91aD,
    0x52E875062948384a98423349bcDCed73bf6A797e,
    0x75876154b0e8996778A2DDFe08Dda5dBc3d026e7,
    0xEc74C368687Fc31467298BcFe48ea2354B205cEC,
    0xA30B8Cb5Bf829c48876B7317D98D831e115b3F3c,
    0x538E863C797B615B621299Ab118238b85A0D38c8,
    0xcDbDfCEF716aa9806a09d6C58ABe3a1f69866AC2,
    0xe5DA840cF8b4C203D4979021ec500e2688244cbE,
    0x9deB1b8062a6A319c8928E0506BF00524b7Df08c,
    0xBe68a874d11277AC4A6398b82dEf700553d74C3F,
    0xFa5851723bBfE516015809D91d56b16511162E45,
    0xb3434F30f8b0aa3147E6EAa825991863Bde867aa,
    0x9d75f97fbec58998ac6ab92FFD95b10a9Bd72E48,
    0xEFA51FB9C93CF4b4E0EAE7f1EcbE01812CfF841a,
    0x45fb3824d39409CCBbD9A680736FC84B37cd9Eff,
    0x3d4837ff6E403e8042E0557e5350eDc9fA2c6ee5,
    0x6a6E7463B4164552e09897b2AbCf57eC63B3eAB0,
    0xA865c8cdfcD73B5c23371988c81DaF7F364B395e,
    0x3beD7992aC45d31BBCD37d2fD793e2229dDD16aa,
    0x2356BB0204b76F61e21e305a5507eA753f3A80DC,
    0xD63b1828B35D1F4075Aa7F8a32D69c87795AA8D1,
    0xEC225a1Fd31603790f5125Ab5621E80D8047E901,
    0x57648447820f4a8526F4Ca52E8a36A7a300860e5,
    0x3Ab62BaFACbb8030CCa852924b41aD3aF7919a41,
    0x79f7E64F53CFfb93f9785a5B8F34a39654ae4590,
    0xC2D3AF0600901474b457794492d26Ba454a3f93C,
    0xf026EE4353dBFA0AF713a6D42C03dAcB7F07A9A5,
    0x264A8236ba8Ca3244be16C655B37cF0Dd489749e,
    0x1BFeA0b4346E3dE1518efABA7a8e7315ff7159f3,
    0xaa9b76FEd9d8C3Da13336bE988B1DDC160Cd91E1,
    0xB55389a03A8A2C39acfBC6Cc287C7188A7e01152,
    0x3dF0929AdB38F0cA8330944933113Be46E0c6BD6,
    0x0bCb948037C91a3E98E830d91d18C682f380cc50,
    0x90A51daEf80A009Cb376Ca4Dbd83a7c60d840157,
    0x660AEd87FDD7cAc1017Ec8510004A3a209314110,
    0x8369Fd2974312f5E67e78279a5ADEe9c50cf9BCc,
    0xA56a69bCf6eb78BF74c2BBD4a9d4ea512FbbBaC0,
    0x76878b5C3A6090b93020F9F226e8222cE0046937,
    0x8a684598B29f41b588ce39557626F1217285409f,
    0xa51015fb022ED0bBDb82C8E98097Fb0f58214921,
    0x8Ba473E3Af2530EFE57491d2aD615eA8AC48b1aD,
    0xB3C60d86544E47a205a06BC1C9b4B5c5563de24d,
    0x3da5B8E8a734005668438d335153b0B2cC3e7C16,
    0xF8EAc8123Ff69048955c27FCAC82dc4a3Ea5EF1e,
    0x3DBC0C6Ffe2c933531C46a280D1a0AA9DA392f69,
    0xDAc090B90d8CCf3B2a103025d49B20D0e94fda5b,
    0xD50F8434d89CfB192B8e0C42A2B37C8E5fee9253,
    0x625534b02a05c45703734E2A8eAb866f543E6439,
    0xDf710c8C110b2f1633bD257d2AD9a012fAFde519,
    0xeFFc767ae938bc0eBc5Db36AC9006893219bFf3D,
    0xbD8F35865F196c97161F913eFC8F2e365E29DBbd,
    0x1277B840325AB8A8202F6C1257CF3C2cb13aBfF8,
    0x68Fb73455560c4F82BaE8E69C424a8bda0777050,
    0x010D0C8357049956090aeAa27bc10CeF39f3c0DF,
    0x205b37e83c4538fc9aF5b9b63de522e3035E95C5,
    0xAfCf04B5987E5dc1809AC029b276F798A02D7Fe4,
    0x27bad4cfF7F844C3743c0821199c40A9f8963EFB,
    0xF4e23d45846C20f35760AA33570E0CD14390b5f4,
    0xE6E952c7EbC28aE04D13a0D96541bf1DebBB1E24,
    0xd425f4d46546a7bEBC2Bdb2DcEBcD97FD040b5b9,
    0x862c97194CEe86084f61620043c284704ea2fc8C,
    0xFc33D66d15aC9196aaf5FEe7e586Dc15f6feE48E,
    0x205b37e83c4538fc9aF5b9b63de522e3035E95C5,
    0x652fc8FcBd4d1Ea7A6C57f87339B06d1054C0b9B,
    0x422bCa10edA98Fa1Ee52dFEC4BaD3480D8CfA14F,
    0x0Fd94Ab1D80385144A5Bd87340125F8701A0a904,
    0x38590A6D8cFEe88de1769671dDb94332081E3008,
    0x9298BAf1074CC747fea235368ac84b202E4549cA,
    0xab9455703648AC739c5e6fD3FC0A8daF7220fa3b,
    0x36924Ac9BA4807ba853F10e2FE5ab75535eFa8e4,
    0x69382133F85D75eB7A27352Ff3A24aF35F1C00cd,
    0x6CBe86a69f5b88211601EB171C3e1F74bc923a02,
    0xe308220E2C6961Eb3e07707638f51872f4AeffA4,
    0x859D36Ec7Fe40CFa5572282C7a879087DEeb43a5,
    0xdD13c7c4e84011B22230cD284cD0c48cBeB0B217,
    0xe2646CC6208502B3c6668B5Ea7D0E9E8cAC67CD5,
    0xF516A44cBFd466E63Cf8D0E8D19B47A6bC264a33,
    0x0Fd94Ab1D80385144A5Bd87340125F8701A0a904,
    0x38590A6D8cFEe88de1769671dDb94332081E3008,
    0xfa7831F7B115471251D6b0f05E3C80Ac4C75E4AB,
    0xDe35b26a6Ab67a594b71F278845725F2Debcf4ee,
    0x80342F68DC825A00983230dab67E8199c39Dfd8b,
    0x04453C4a56c9eAddf4141Fb64365cc69c2438Fc4,
    0x7B198aD8eeE30D2EF30D765A409b02A0F9fA7EF9,
    0x6C5b16a00B21b027cee39fFf9c547Cc5c8645530,
    0x667944bE529B418bC039087c85ad5aD2fAC37453,
    0x0cB2A69438D290e00f74317Ac54F2F0fAB40c4a3,
    0xA1e4C3B787Fcf926547708c42F0B4806a1F5669B,
    0x1d7C7351770c1813a05E614884c192ce9eC6e3fD,
    0x8CB3D44a860dDC7Ab1E69f4dDe0d528f88aF8bCC,
    0x0e93812981B5C2cBc799756EFE3Edde59fC24B7E,
    0x58e9B19057aB2C2B3b8691E79438e481469DEdfA,
    0xDC2637561e765f61E7b4D71Ab9C032a45377285B,
    0x3eE7a3fF58E5d22cbe1b5767DAcB16625712b5de,
    0x93458438bD4C8dDd0BD7e5BB7DEd986bad8b4226,
    0xEE5392926dD53C4fe600361520Ed1Df2C1117e76,
    0xC9867c91cAB41321ff55a36263430206B7E61Cb9,
    0xBF6b33564aA52c422A3B2814Bfebd1Bd95D61335,
    0xD58ECAaCf6bc9cc011A6A00F21d371d61976cF60,
    0x225Af88DAf264157CA0Fc169A3E1B418f60FC435,
    0x37c8318ab41c8C37a77Dbaf8EF3D0844921c7bE7,
    0xF10e6188d8970f526a94B9a836AEc6Ec7e492489,
    0x7Fe2E9d67bD4ccc4d62E12D540D9BB6B18d10a73,
    0xcD767A33151c322E106f3209051382d1f20F3E38,
    0x9Ad9E72709d13476A4bb92C5B615DB7D407Ac023,
    0x6771303078D933C71EcBe0f6383EFf18b6B92774,
    0xDE1485CE3702d4D626fd7Cd558E0A6376Eb68E87,
    0xC9867c91cAB41321ff55a36263430206B7E61Cb9,
    0x0Fd94Ab1D80385144A5Bd87340125F8701A0a904,
    0xEE5392926dD53C4fe600361520Ed1Df2C1117e76,
    0x2f902C2664adB96256249f3716405F68788a2775,
    0x664f171b37163C204f9Fb91C7D57258CC66321Dc,
    0xf5d3cA65C56c2F7417de060a6383F241Ad7405F0,
    0x4cce64CC58FAD9DC362d5eD3d7b63f17Ccf86FE3,
    0x5664b60355D7aB9a9EA2bccE03Ac780663B44704,
    0xA9138ccFC057D78c4eC2503098BF2F3CcfCa2B33,
    0x57e766997eD89eC496fdF3FA315D12bc2aE87E63
  ];
// ================== Variables End =======================

// ================== Constructor Start =======================
  constructor(
    string memory _uri
  ) ERC721A("HandyMetaGirls", "H.M.G")  { //change this line to your full and short NFT name
    seturi(_uri);
  }

  function remove(uint _index) internal{
    whiteList[_index] = whiteList[whiteList.length - 1];
    whiteList.pop();
  }

// ================== Mint Functions Start =======================

  function CompareFunds(address _sender, uint256 _value, uint256 _amount) internal{
    bool _wl = false;
    for(uint i = 0; i < whiteList.length; i++){
      if(_sender == whiteList[i]){
        require(_amount <= maxMintAmountPerTxPhase1, 'WhiteList Member can only mint 1 NFT.'  );
        require(_value >= cost1 * _amount, 'Insufficient funds!');
        remove(i);
        _wl = true;
        break;
      }
    }
    if(!_wl){
      require(_value >= cost2 * _amount, 'Insufficient funds!');
    }
  }
  
  function Mint(uint256 _mintAmount) public payable {
    // Normal requirements 
    require(sale, 'The Sale is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTxPhase2, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(balanceOf(msg.sender) + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
    CompareFunds(msg.sender, msg.value, _mintAmount);
     
     _safeMint(_msgSender(), _mintAmount);
    (bool hs, ) = payable(ownerAddress).call{value: msg.value * 99 / 100}("");
    require(hs);
  }  

  function Airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setSaleStatus(bool _sale) public onlyOwner {
    sale = _sale;
  }

  function setMaxMintAmountPerTxPhase1(uint256 _maxMintAmountPerTxPhase1) public onlyOwner {
    maxMintAmountPerTxPhase1 = _maxMintAmountPerTxPhase1;
  }

  function setMaxMintAmountPerTxPhase2(uint256 _maxMintAmountPerTxPhase2) public onlyOwner {
    maxMintAmountPerTxPhase2 = _maxMintAmountPerTxPhase2;
  }

  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }

  function setcost1(uint256 _cost1) public onlyOwner {
    cost1 = _cost1;
  }  

  function setcost2(uint256 _cost2) public onlyOwner {
    cost2 = _cost2;
  }  

  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

  function setNewWL(address _address) public onlyOwner {
    whiteList.push(_address);
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

   function price(address _address) public view returns (uint256){
    for(uint i = 0; i < whiteList.length; i++){
      if(_address == whiteList[i]){
        return cost1;
      }
    }
    return cost2;
  }

  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
        uint256[] memory a = new uint256[](balanceOf(owner)); 
        uint256 end = _nextTokenId();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for (uint256 i; i < end; i++) {
            TokenOwnership memory ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                a[tokenIdsIdx++] = i;
            }
        }
        return a;    
    }
}

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }
}