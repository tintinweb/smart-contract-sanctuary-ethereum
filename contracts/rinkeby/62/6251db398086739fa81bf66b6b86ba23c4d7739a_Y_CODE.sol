/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 
abstract contract ReentrancyGuard { 
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
   _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
 
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
 
    constructor() {
        _transferOwnership(_msgSender());
    }
 
    function owner() public view virtual returns (address) {
        return _owner;
    } 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
 
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
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

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

    // ==============================
    //        IERC721Metadata
    // ==============================

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

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);


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
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with `_mintERC2309`.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to `_mintERC2309`
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The tokenId of the next token to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
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
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

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
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
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
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
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
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> BITPOS_EXTRA_DATA);
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, BITMASK_ADDRESS)
            // `owner | (block.timestamp << BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
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

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << BITPOS_NEXT_INITIALIZED`.
            result := shl(BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
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
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
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
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
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
    ) internal {
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
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
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
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 tokenId = startTokenId;
            uint256 end = startTokenId + quantity;
            do {
                emit Transfer(address(0), to, tokenId++);
            } while (tokenId < end);

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
    function _mintERC2309(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

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
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        mapping(uint256 => address) storage tokenApprovalsPtr = _tokenApprovals;
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            // Compute the slot.
            mstore(0x00, tokenId)
            mstore(0x20, tokenApprovalsPtr.slot)
            approvedAddressSlot := keccak256(0x00, 0x40)
            // Load the slot's value from storage.
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    /**
     * @dev Returns whether the `approvedAddress` is equals to `from` or `msgSender`.
     */
    function _isOwnerOrApproved(
        address approvedAddress,
        address from,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
            from := and(from, BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, BITMASK_ADDRESS)
            // `msgSender == from || msgSender == approvedAddress`.
            result := or(eq(msgSender, from), eq(msgSender, approvedAddress))
        }
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
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
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
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
                BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
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
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) public virtual {
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

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
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
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (BITMASK_BURNED | BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
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

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << BITPOS_EXTRA_DATA;
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred.
     * This includes minting.
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
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred.
     * This includes minting.
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

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}
contract Y_CODE is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
  uint256 public  PRICE = 0.0 ether;

  uint256 private constant TotalCollectionSize_ = 7; // total number of nfts
  mapping(uint => string) public metadata;
  uint token_id;

  constructor() ERC721A("Y-CODE","Halfbreedz") {
    //   string memory json = Base64.encode(bytes(string(abi.encodePacked('{"image": "data:image/jpeg;base64,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"}'))));
    //   json = string(abi.encodePacked('data:application/json;base64,', json));
    //   metadata[1] = json;
  }
  
  function insert_nft (string memory m) public {
      metadata[token_id++] = m;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function mint(uint256 quantity) external payable callerIsUser {
    require(totalSupply() + quantity <= TotalCollectionSize_, "reached max supply");
    require(msg.value >= PRICE * quantity, "Need to send more ETH.");
    _safeMint(msg.sender, quantity);
  }

   function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        return metadata[tokenId];
  }
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return _ownershipOf(tokenId);
  }
  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
  function changeMintPrice(uint256 _newPrice) external onlyOwner
  {
      PRICE = _newPrice;
  }
  function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}