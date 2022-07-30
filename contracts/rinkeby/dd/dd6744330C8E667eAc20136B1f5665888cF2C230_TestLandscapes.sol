// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ArtOfChoice is Ownable, Pausable, ERC721A {
    string internal _baseMetadataURI;

    address public withdrawalAddress;

    struct TokenAllocation {
        uint32 collectionSize;
        uint32 mintsPerTransaction;
    }

    TokenAllocation public tokenAllocation;

    struct FlatMintConfig {
        bool isEnabled;
        uint72 price;
        uint32 startTime;
        uint32 endTime;
    }

    FlatMintConfig public flatMintConfig;

    constructor() ERC721A("ArtOfChoice", "AOC") {}

    /**
     * -----EVENTS-----
     */

    /**
     * @dev Emit on calls to flatMint().
     */
    event FlatMint(address indexed to, uint256 quantity, uint256 price, uint256 totalMinted, uint256 timestamp);

    /**
     * @dev Emit on calls to airdropMint().
     */
    event AirdropMint(address indexed to, uint256 quantity, uint256 price, uint256 totalMinted, uint256 timestamp);

    /**
     * @dev Emits on calls to setBaseMetadataURI()
     */
    event BaseMetadataURIChange(string baseMetadataURI, uint256 timestamp);

    /**
     * @dev Emits on calls to setWithdrawalAddress()
     */
    event WithdrawalAddressChange(address withdrawalAddress, uint256 timestamp);

    /**
     * @dev Emits on calls to withdraw()
     */
    event Withdrawal(address indexed to, uint256 amount, uint256 timestamp);

    /**
     * @dev Emits on calls to setTokenAllocation()
     */
    event TokenAllocationChange(uint256 collectionSize, uint256 mintsPerTransaction, uint256 timestamp);

    /**
     * @dev Emits on calls to setFlatMintConfig()
     */
    event FlatMintConfigChange(uint256 price, uint256 startTime, uint256 endTime, uint256 timestamp);

    /**
     * -----MODIFIERS-----
     */

    /**
     * @dev Check that a given mint transaction follows guidelines,
     * like not putting us over our total supply or minting too many NFTs in a single transaction,
     * (which is bad for 721A NFTs).
     */
    modifier checkMintLimits(uint256 quantity) {
        require(quantity > 0, "Mint quantity must be > 0");
        require(_totalMinted() + quantity <= tokenAllocation.collectionSize, "Exceeds total supply");
        require(quantity <= tokenAllocation.mintsPerTransaction, "Cannot mint this many in a single transaction");
        _;
    }

    /**
     * -----OWNER FUNCTIONS-----
     */

    /**
     * @dev Wrap the _pause() function from OpenZeppelin/Pausable
     * To allow preventing any mint operations while the project is paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Allow unpausing the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets `baseMetadataURI` for computing tokenURI().
     */
    function setBaseMetadataURI(string calldata baseMetadataURI) external onlyOwner {
        emit BaseMetadataURIChange(baseMetadataURI, block.timestamp);

        _baseMetadataURI = baseMetadataURI;
    }

    /**
     * @dev Sets `withdrawalAddress` for withdrawal of funds from the contract.
     */
    function setWithdrawalAddress(address withdrawalAddress_) external onlyOwner {
        require(withdrawalAddress_ != address(0), "withdrawalAddress_ cannot be the zero address");

        emit WithdrawalAddressChange(withdrawalAddress_, block.timestamp);

        withdrawalAddress = withdrawalAddress_;
    }

    /**
     * @dev Sends all ETH from the contract to `withdrawalAddress`.
     */
    function withdraw() external onlyOwner {
        require(withdrawalAddress != address(0), "withdrawalAddress cannot be the zero address");

        emit Withdrawal(withdrawalAddress, address(this).balance, block.timestamp);

        (bool success, ) = withdrawalAddress.call{value: address(this).balance}("");
        require(success, "Withdrawal transfer failed");
    }

    /**
     * @dev Sets `tokenAllocation` for mint phases.
     */
    function setTokenAllocation(uint32 collectionSize, uint32 mintsPerTransaction) external onlyOwner {
        require(collectionSize > 0, "collectionSize must be > 0");
        require(mintsPerTransaction > 0, "mintsPerTransaction must be > 0");
        require(mintsPerTransaction <= collectionSize, "mintsPerTransaction must be <= collectionSize");

        emit TokenAllocationChange(collectionSize, mintsPerTransaction, block.timestamp);

        tokenAllocation.collectionSize = collectionSize;
        tokenAllocation.mintsPerTransaction = mintsPerTransaction;
    }

    /**
     * @dev Sets configuration for the flat mint.
     */
    function setFlatMintConfig(
        uint72 price,
        uint32 startTime,
        uint32 endTime
    ) external onlyOwner {
        require(startTime >= block.timestamp, "startTime must be >= block.timestamp");
        require(startTime < endTime, "startTime must be < endTime");

        emit FlatMintConfigChange(price, startTime, endTime, block.timestamp);

        flatMintConfig.price = price;
        flatMintConfig.startTime = startTime;
        flatMintConfig.endTime = endTime;

        flatMintConfig.isEnabled = true;
    }

    /**
     * @dev Mints tokens to given address at no cost.
     */
    function airdropMint(address to, uint256 quantity) external payable onlyOwner checkMintLimits(quantity) {
        emit AirdropMint(to, quantity, 0, _totalMinted() + quantity, block.timestamp);

        _mint(to, quantity);
    }

    /**
     * -----INTERNAL FUNCTIONS-----
     */

    /**
     * @dev Base URI for computing tokenURI() (from the 721A contract). If set, the resulting URI for each
     * token will be the concatenation of the `baseMetadataURI` and the token ID. Overridden from the 721A contract.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseMetadataURI;
    }

    /**
     * EXTERNAL FUNCTIONS
     */

    /**
     * @dev Mints `quantity` of tokens and transfers them to the sender.
     * If the sender sends more ETH than needed, it refunds them.
     *
     * Note that flatMint() has no reserve, so it has the potential to mint
     * out the whole collection if called before the other mint phases!
     */
    function flatMint(uint256 quantity) external payable whenNotPaused checkMintLimits(quantity) {
        require(flatMintConfig.isEnabled && block.timestamp >= flatMintConfig.startTime, "Flat mint has not started");
        require(block.timestamp < flatMintConfig.endTime, "Flat mint has ended");

        // We explicitly want to use tx.origin to check if the caller is a contract
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == msg.sender, "Caller must be user");

        uint256 cost = flatMintConfig.price * quantity;
        require(msg.value >= cost, "Insufficient payment");

        emit FlatMint(msg.sender, quantity, flatMintConfig.price, _totalMinted() + quantity, block.timestamp);

        // Contracts can't call this function so we don't need _safeMint()
        _mint(msg.sender, quantity);

        if (msg.value > cost) {
            (bool success, ) = msg.sender.call{value: msg.value - cost}("");
            require(success, "Refund transfer failed");
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

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
    function _toString(uint256 value) internal pure virtual returns (string memory ptr) {
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
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ArtOfChoice.sol";

contract ArtOfChoiceTestable is ArtOfChoice {
    constructor() ArtOfChoice() {}

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ArtOfChoice.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ArtOfChoiceCaller is IERC721Receiver {
    function mint(address contractAddress, uint256 quantity) external payable {
        ArtOfChoice aoc = ArtOfChoice(contractAddress);
        aoc.flatMint{value: msg.value}(quantity);
    }

    // Must be implemented so we can receive tokens via safeTransfer
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./PixelPigeons.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract PixelPigeonsCaller is IERC721Receiver {
    function claimPigeons(address contractAddress) external {
        PixelPigeons pp = PixelPigeons(contractAddress);
        pp.claimPigeons(contractAddress);
    }

    // Must be implemented so we can receive tokens via safeTransfer
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {RLEtoSVG} from "./RLEtoSVG.sol";

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/*
 *                            _¡░╠╠░_
 *         __.,,,,,,,,,,,,,,,,░░░╚╙Γ
 *         _]φ╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠▒░░
 *     __.░φ▒╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▒▒░░.
 *   ,,;φφ╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠░~
 *   ▓▓▓╬╬╩╚╠╬╬╬╬╬╬╣▓▓█▓╬╬╚╠╠╬╬╬╬╬╠░_
 *   ████╬▒░▒╠╬╬╬╬╬╣▓███╬▒░░╠╬╬╬╬╬╠▒░.__
 *   ████╬▒░▒╠╬╬╬╬╬╣▓███╬▒░░╠╬╬╬╬╬╬╠╠▒▒░_
 *   ███▓╬▒░▒╠╬╬╬╬╬╣▓███╬╠▒╠╠╬╬╬╬╬╬╬╬╬▒░_
 *   ╬╬╬╬╬▒▒▒▒╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▒░_
 *   ╬╬╬╬╬╬╬╬╬╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▒░_
 *   ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬░░__        ____
 *   ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╠▒φ░,_     _,φφφ
 *   ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╩╩╩╩▒░░,____'⌠╚╩╩
 *   ╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╩░Γ""""░░φ▒▒░░   '''
 *   ╬╬╬╬╬╬╬╬╠╩╩╩╩╩╠╠╬╬╬╬╬╬╬╠╩╚╚╚╚╚░'_ .░░░░░╚╚░└_
 *   ╬╬╬╬╬╬╬▒Γ░''''░╚╠╬╬╬╬╬╩Γ░' '' _  .░φ╠▒░░"''__
 *   ╚╚╚╚╚╚░░░_____'░░╚╚╚╚╚Γ░░.___ .░φφ░░╚Γ░'___
 *   ______________________'!░░┐__.░φ╠▒▒░_____
 *     _____________________''''.;░░Γ╚░░░░┌_   _
 *      __'''''________________''░░░░░░░""'
 *       _  __'______.___________'''''__    _
 *                 '░░φ░░_ _.░░░_
 *                _.░▒╠▒░ _ ;░▒░_
 *             __,φφ▒╠╬╠▒░░░░▒▒░_
 *             _░▒╬╬╬╬╬╬╠╠▒▒▒▒▒░_
 */

contract PixelPigeons is Ownable, Pausable, ERC721A {
    using Strings for uint256;

    struct EtcHolder {
        address holderAddress;
        uint256 numPigeons;
    }

    // We could have used a Merkle Tree here, but given the timing, we are fine with paying extra gas to use a map
    mapping(address => uint256) public holderMap;
    uint256 public immutable updateHoldersBatchMax;

    string[][] public palettes;
    bytes[] public pigeons;
    string[] public backgrounds;

    struct Seed {
        uint8 head;
        uint8 body;
        uint8 background;
    }

    mapping(uint256 => Seed) public _seeds;

    // If you hold more pigeons than this threshold, you get two PixelPigeons
    // Less than this, you get one
    uint256 public constant PIGEON_THRESHOLD = 16;

    error ExceedsUpdateHoldersBatchMax();
    error AirdroppedAllHolders();
    error AirdropQuantityZero();
    error NotInHolderSnapshot();
    error AlreadyClaimedPigeons();
    error CallerMustBeUser();
    error PalettesPigeonsMismatch(uint256 palettesLength, uint256 pigeonsLength);

    constructor(uint256 updateHoldersBatchMax_) ERC721A("PixelPigeons", "PP") {
        updateHoldersBatchMax = updateHoldersBatchMax_;

        _mintERC2309(owner(), 10);
    }

    /**
     * EVENTS
     */

    /**
     * @dev Emit on addHolders() after we add new holders.
     */
    event AddHolders(uint256 numHoldersAdded, uint256 timestamp);

    /**
     * @dev Emit on deleteHolders() after the holders map is reset;
     */
    event DeleteHolders(uint256 numHoldersDeleted, uint256 timestamp);

    /**
     * @dev Emit on addPalettes() after we add new color palettes.
     */
    event AddPalettes(uint256 numPalettesAdded, uint256 totalPalettes, uint256 timestamp);

    /**
     * @dev Emit on addPigeons() after we add new PixelPigeon RLE strings.
     */
    event AddPigeons(uint256 numPigeonsAdded, uint256 totalPigeons, uint256 timestamp);

    /**
     * @dev Emit on addBackgrounds() after we add new background colors.
     */
    event AddBackgrounds(uint256 numBackgroundsAdded, uint256 totalBackgrounds, uint256 timestamp);

    /**
     * @dev Emit on setSeeds() after we set the seeds.
     */
    event SetSeeds(uint256 startIndex, uint256 endIndex, uint256 timestamp);

    /**
     * @dev Emit on airdrop() after we mint the specified amount the receiver.
     */
    event Airdrop(address indexed to, uint256 quantity, uint256 timestamp);

    /**
     * @dev Emit on claimPigeons() after a user claims their allotted Pixel Pigeons.
     */
    event ClaimPigeons(address indexed to, uint256 quantity, uint256 timestamp);

    /**
     * OWNER FUNCTIONS
     */

    /**
     * @dev Allow pausing the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Allow unpausing the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Add holders to the holders map.
     */
    function addHolders(EtcHolder[] calldata holders_) external onlyOwner {
        if (holders_.length > updateHoldersBatchMax) revert ExceedsUpdateHoldersBatchMax();

        for (uint256 i = 0; i < holders_.length; i++) {
            holderMap[holders_[i].holderAddress] = holders_[i].numPigeons;
        }

        emit AddHolders(holders_.length, block.timestamp);
    }

    /**
     * @dev Resets a chunked portion of holders in the holders map.
     */
    function deleteHolders(EtcHolder[] calldata holders_) external onlyOwner {
        if (holders_.length > updateHoldersBatchMax) revert ExceedsUpdateHoldersBatchMax();

        for (uint256 i = 0; i < holders_.length; i++) {
            delete holderMap[holders_[i].holderAddress];
        }

        emit DeleteHolders(holders_.length, block.timestamp);
    }

    /**
     * @dev Airdrop `quantity` tokens to a given address.
     */
    function airdrop(address to, uint256 quantity) external onlyOwner {
        if (quantity == 0) revert AirdropQuantityZero();

        for (uint256 i = _nextTokenId(); i < quantity; i++) {
            _setSeed(i);
        }

        _mint(to, quantity);

        emit Airdrop(to, quantity, block.timestamp);
    }

    /**
     * @dev Add palettes to the string[][] palettes array.
     */
    function addPalettes(string[][] memory _palettes) external onlyOwner {
        for (uint256 i = 0; i < _palettes.length; i++) {
            palettes.push(_palettes[i]);
        }

        emit AddPalettes(_palettes.length, palettes.length, block.timestamp);
    }

    /**
     * @dev Add pigeonRLE strings to the bytes[] pigeons array.
     */
    function addPigeons(bytes[] calldata _pigeons) external onlyOwner {
        for (uint256 i = 0; i < _pigeons.length; i++) {
            pigeons.push(_pigeons[i]);
        }

        emit AddPigeons(_pigeons.length, pigeons.length, block.timestamp);
    }

    /**
     * @dev Add backgrounds strings to the string[] backgrounds array.
     */
    function addBackgrounds(string[] calldata _backgrounds) external onlyOwner {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            backgrounds.push(_backgrounds[i]);
        }

        emit AddBackgrounds(_backgrounds.length, backgrounds.length, block.timestamp);
    }

    /**
     * @dev Set the seeds (reveals?) the pigeons in the slice given from start to end.
     */
    function setSeeds(uint256 startIndex, uint256 endIndex) external onlyOwner {
        for (uint256 i = _startTokenId() + startIndex; i < endIndex; i++) {
            _setSeed(i);
        }

        emit SetSeeds(startIndex, endIndex, block.timestamp);
    }

    /**
     * VIEW FUNCTIONS
     */

    /**
     * @dev Returns number of PixelPigeons minted to a given address.
     */
    function numberMinted(address to) external view returns (uint256) {
        return _numberMinted(to);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    // Literally can't declare this external since we're overriding a public function.
    // Bad Slither.
    // slither-disable-next-line external-function
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return constructTokenURI(tokenId);
    }

    /**
     * @dev Builds the JSON metadata for a given token on-chain, including attributes & image.
     */
    function constructTokenURI(uint256 tokenId) public view returns (string memory) {
        // It's fine to overload ERC721.name() in this context,
        // since we are dealing with a single token.
        // slither-disable-next-line shadowing-local
        string memory name = string(abi.encodePacked("PixelPigeon ", tokenId.toString()));
        string memory description = string(
            abi.encodePacked("PixelPigeon ", tokenId.toString(), " thinks Everythings Coo")
        );

        uint256 headPaletteIndex = _seeds[tokenId].head;
        uint256 bodyPaletteIndex = _seeds[tokenId].body;
        uint256 backgroundIndex = _seeds[tokenId].background;

        // Note: The way we calculate the Pigeon RLE needs to be the same
        // as the way we calculate bodyPalette.
        //
        // So, if we were to randomize, pigeon[y] and bodyPalette[y]
        // would have to use the same random number y.
        //
        // This is due to the fact that different pigeons
        // have different RLEs, and thus palettes of different lengths,
        // and we need to ensure we use a palette of appropriate length for the RLE.

        bytes memory pigeon = pigeons[bodyPaletteIndex];
        string[] memory headPalette = palettes[headPaletteIndex];
        string[] memory bodyPalette = palettes[bodyPaletteIndex];
        string memory background = backgrounds[backgroundIndex];

        string memory image = RLEtoSVG.generateSVG(pigeon, headPalette, bodyPalette, background);

        RLEtoSVG.PigeonMetadata memory pigeonMetadata = RLEtoSVG._getPigeonMetadata(pigeon);

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                    Base64.encode((bytes.concat(
                        abi.encodePacked(
                        '{',
                            '"name":"', name,
                            '", "description":"', description,
                            '", "background_color":"', background,
                            '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)),
                            '", "attributes": [',
                                '{"trait_type": "Head", "value": "', headPalette[pigeonMetadata.headColorIndex], '"},'),
                            abi.encodePacked(
                                '{"trait_type": "Eyes", "value": "', headPalette[pigeonMetadata.eyeColorIndex], '"},',
                                '{"trait_type": "Beak", "value": "', headPalette[pigeonMetadata.beakColorIndex], '"},',
                                '{"trait_type": "Body", "value": "', bodyPalette[pigeonMetadata.bodyColorIndex], '"},',
                                '{"trait_type": "Background", "value": "', background, '"}',
                            ']',
                        '}')
                    )))
            )
        );
    }

    /**
     * EXTERNAL FUNCTIONS
     */

    /**
     * @dev Claim function for a whitelisted user to get their allotted PixelPigeons.
     */
    function claimPigeons(address to) external whenNotPaused {
        if (tx.origin != msg.sender) revert CallerMustBeUser();
        if (holderMap[to] == 0) revert NotInHolderSnapshot();
        if (_numberMinted(to) > 0) revert AlreadyClaimedPigeons();

        uint256 quantity = 1;
        _setSeed(_nextTokenId());
        if (holderMap[to] > PIGEON_THRESHOLD) {
            quantity = 2;
            _setSeed(_nextTokenId() + 1);
        }

        _mint(to, quantity);

        emit ClaimPigeons(to, quantity, block.timestamp);
    }

    /**
     * INTERNAL FUNCTIONS
     */

    /**
     * @dev Generates a pseudorandom number. Used for generating pigeon metadata.
     */
    function _generateRandomNumber(
        uint256 tokenId,
        uint256 max,
        uint256 seed
    ) internal pure returns (uint256) {
        // We're generating SVG images here, not dealing with money.
        // slither-disable-next-line weak-prng
        return uint256(keccak256(abi.encodePacked(tokenId, seed))) % max;
    }

    /**
     * @dev Generates the pigeon metadata and stores it in the `_seeds` mapping
     */
    function _setSeed(uint256 tokenId) internal {
        // Note: palettes.length SHOULD EQUAL pigeons.length.
        //
        // This is due to the fact that different pigeons
        // have different RLEs, and thus palettes of different lengths,
        // and we need to ensure we use a palette of appropriate length for the RLE.

        uint256 palettesLength = palettes.length;
        uint256 pigeonsLength = pigeons.length;

        if (palettesLength != pigeonsLength) revert PalettesPigeonsMismatch(palettesLength, pigeonsLength);

        _seeds[tokenId].head = uint8(_generateRandomNumber(tokenId, palettesLength, block.timestamp));
        _seeds[tokenId].body = uint8(tokenId % palettesLength);
        _seeds[tokenId].background = uint8(_generateRandomNumber(tokenId, backgrounds.length, block.timestamp + 1));
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

library RLEtoSVG {
    struct ContentBounds {
        uint8 top;
        uint8 right;
        uint8 bottom;
        uint8 left;
    }

    struct Rect {
        uint8 length;
        uint8 colorIndex;
    }

    struct DecodedImage {
        ContentBounds bounds;
        Rect[] rects;
    }

    struct PigeonMetadata {
        uint8 headColorIndex;
        uint8 eyeColorIndex;
        uint8 beakColorIndex;
        uint8 bodyColorIndex;
    }

    /**
     * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
     */
    function generateSVG(
        bytes memory pigeonRLE,
        string[] memory headPalette,
        string[] memory bodyPalette,
        string memory background
    ) internal pure returns (string memory svg) {
        // prettier-ignore
        return string(
            abi.encodePacked(
                // solhint-disable-next-line max-line-length
                '<svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<rect width="100%" height="100%" fill="#', background, '" />',
                '<g transform="translate(40, 25)">',
                _generateSVGRects(pigeonRLE, headPalette, bodyPalette),
                '</g>',
                '</svg>'
            )
        );
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     */
    function _generateSVGRects(
        bytes memory pigeonRLE,
        string[] memory headPalette,
        string[] memory bodyPalette
    ) private pure returns (string memory svg) {
        // prettier-ignore
        string[33] memory lookup = [
            '0', '10', '20', '30', '40', '50', '60', '70',
            '80', '90', '100', '110', '120', '130', '140', '150',
            '160', '170', '180', '190', '200', '210', '220', '230',
            '240', '250', '260', '270', '280', '290', '300', '310',
            '320'
        ];

        DecodedImage memory image = _decodeRLEImage(pigeonRLE);
        uint256 currentX = image.bounds.left;
        uint256 currentY = image.bounds.top;

        uint256 cursor;
        string[16] memory buffer;
        string memory part;
        string memory rects;

        for (uint256 i = 0; i < image.rects.length; i++) {
            Rect memory rect = image.rects[i];
            if (rect.colorIndex != 0) {
                buffer[cursor] = lookup[rect.length]; // width
                buffer[cursor + 1] = lookup[currentX]; // x
                buffer[cursor + 2] = lookup[currentY]; // y

                uint8 colorIndex = rect.colorIndex;
                buffer[cursor + 3] = bodyPalette[colorIndex]; // color

                if (colorIndex <= 6) {
                    buffer[cursor + 3] = headPalette[colorIndex]; // color
                }
                cursor += 4;

                if (cursor >= 16) {
                    part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
                    cursor = 0;
                }
            }

            currentX += rect.length;
            if (currentX == image.bounds.right) {
                currentX = image.bounds.left;
                currentY++;
            }
        }

        if (cursor != 0) {
            part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
        }
        rects = string(abi.encodePacked(rects, part));
        return rects;
    }

    /**
     * @notice Return a string that consists of all rects in the provided `buffer`.
     */
    // prettier-ignore
    function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
        string memory chunk;
        for (uint256 i = 0; i < cursor; i += 4) {
            chunk = string(
                abi.encodePacked(
                    chunk,
                    // solhint-disable-next-line max-line-length
                    '<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
                )
            );
        }
        return chunk;
    }

    /**
     * @notice Decode a single RLE compressed image into a `DecodedImage`.
     */
    function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
        ContentBounds memory bounds = ContentBounds({
            top: uint8(image[1]),
            right: uint8(image[2]),
            bottom: uint8(image[3]),
            left: uint8(image[4])
        });

        uint256 cursor;
        Rect[] memory rects = new Rect[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            rects[cursor] = Rect({length: uint8(image[i]), colorIndex: uint8(image[i + 1])});
            cursor++;
        }
        return DecodedImage({bounds: bounds, rects: rects});
    }

    function _getPigeonMetadata(bytes memory pigeon) internal pure returns (PigeonMetadata memory) {
        DecodedImage memory image = _decodeRLEImage(pigeon);

        // Literally counted pixels/rectangles in a PNG file to derive these.
        return
            PigeonMetadata({
                headColorIndex: image.rects[4].colorIndex,
                eyeColorIndex: image.rects[9].colorIndex,
                beakColorIndex: image.rects[24].colorIndex,
                bodyColorIndex: image.rects[35].colorIndex
            });
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/*     .                  .-.    .  _   *     _   .
//            *          /   \     ((       _/ \       *    .
//          _    .   .--'\/\_ \     `      /    \  *    ___
//      *  / \_    _/ ^      \/\'__        /\/\  /\  __/   \ *
//        /    \  /    .'   _/  /  \  *' /    \/  \/ .`'\_/\   .
//   .   /\/\  /\/ :' __  ^/  ^/    `--./.'  ^  `-.\ _    _:\ _
//      /    \/  \  _/  \-' __/.' ^ _   \_   .'\   _/ \ .  __/ \
//    /\  .-   `. \/     \ / -.   _/ \ -. `_/   \ /    `._/  ^  \
//   /  `-.__ ^   / .-'.--'    . /    `--./ .-'  `-.  `-. `.  -  `.
// @/        `.  / /      `-.   /  .-'   / .   .'   \    \  \  .-  \%
// @&[email protected]@%% @)&@&(88&@[email protected]% &@&&8(8%@%8)([email protected]%8 8%@)%
// @88:::&(&8&&8:::::%&`.~-_~~-~~_~-~_~-~~=.'@(&%::::%@8&8)::&#@8::::
// `::::::8%@@%:::::@%&8:`.=~~-.~~-.~~=..~'8::::::::&@8:::::&8:::::'
//  `::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.'
*/

contract TestLandscapes is Ownable, ERC721A {
    error InvalidRLE();

    constructor() ERC721A("TestLandscapes", "TL") {}

    function mintLandscape(bytes memory _rle) external {
        if (_rle.length == 0) revert InvalidRLE();
        _mint(msg.sender, 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Landscapes is Ownable, Pausable, ERC721A {
    constructor() ERC721A("Landscapes", "LDX") {}

    /**
     * ----CONSTANTS-----
     */

    // Free mint. Used for refunding accidental mint transactions with a balance.
    uint256 internal constant _MINT_COST = 0;

    // Only mint one NFT at a time, because they are seeded art pieces.
    uint256 internal constant _MINT_QUANTITY = 1;

    /**
     * -----ERRORS-----
     */

    // Raised on calls to mint() from a contract.
    error CallerMustBeUser();

    // Raised on refunds with extra value sent to mint()
    error RefundFailed(address to, uint256 amount);

    /**
     * -----EVENTS-----
     */

    // Emits on calls to mint().
    event Mint(address indexed to, uint256 totalMinted, uint256 timestamp);

    /**
     * -----OWNER FUNCTIONS-----
     */

    /**
     * @dev Allow pausing the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Allow unpausing the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * -----EXTERNAL FUNCTIONS-----
     */

    /**
     * @dev Allow minting a single Landscape NFT for free.
     */
    function mint() external payable whenNotPaused {
        if (tx.origin != msg.sender) revert CallerMustBeUser();

        emit Mint(msg.sender, _totalMinted() + _MINT_QUANTITY, block.timestamp);

        _mint(msg.sender, _MINT_QUANTITY);

        // Refund user if too much ETH was accidentally sent for minting.
        if (msg.value > _MINT_COST) {
            (bool success, ) = msg.sender.call{value: msg.value - _MINT_COST}("");
            if (!success) revert RefundFailed(msg.sender, msg.value - _MINT_COST);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/*
 *                                           ..
 *                                       ..,d0KOc.
 *                                     .cOKKKdc0N0OOkxdoc;..
 *                                     '0MWKl. 'cc::cloxO0KOdc'.
 *                                    .oXXOd'            .,cd0KOo;.
 *                                   ;OXx'                   .,lkK0o,
 *                                 .cXKc.    .;:c:,.             ;OWNx,
 *                                .oX0,  ..:kXKkxxO0x,         .cOXKOXK:
 *                               .dNO'  .oKXXXx.  .;OKc       .kXKXd.:XK,
 *                              .dNO'   ;XMO,..     ,K0'      lNx... .xWo
 *                             .dNO'    ;XMO.       ;KO'  ..  lNx.    lNk.
 *                            .oNO'     .oKXk,.   .:OKc .oKK0ockXx'.  cNO.
 *                            lX0,        .;x0OxxkO0d'  ,0WMNk,.ck0OkkKWO.
 *                           cXK;            .,::;'.     .;;'     .;:cOWx.
 *                          :XK:                                     .xWo
 *             .          .lXK:                                      '0N:
 *        .,;:d0Oo.      .dXO,                                       :X0'
 *       .kNXNWkkNk.   .:0Xd.                                       .dWx.
 *     .c0WNd:d,,0W0xooON0:                                         '0X:
 *     :XNkoc.. ,0kcodddxkocccoko.                                  lNk.
 *     .lKKxc,. ;0c      .,:c:;x0:. ..                             .ONl
 *       .cx0KKo;xk'           .cdddOKo.                           cNO'
 *          .:KXc'okl'.          .:O0xxxlccldkl.    .             .kNl
 *            lNO' 'lddolc::::ccodxo'  ';:::,:xxl::okx;.   'c:...,xNO'
 *            .dNk'   .';:ccccc:;..            ':cc:,cddooddooddONW0;
 *             .dXO,                                   ....    ,ONk'
 *              .cKXo.                                        ,ONx.
 *                'dK0o.                                    'oKKl.
 *                  'dKKx:.                              .:xKKo.
 *                    .:x0KOdc,..                   .':okKKkc.
 *                       .,lkXWX0o. ,c::::::;. ,ldx0KK0xo;.
 *                          lXXkxl..:c::x0Okd'.,:;lKWd.
 *                         .oW0c;::;.  .dOdl:cc;..cXX:
 *                          .cxO0O0K0OxkXX0OOkO000K0l.
 *                              ....,cll:..    .','.
 */

contract EverythingsCoo is Ownable, Pausable, ERC721A {
    string internal _baseMetadataURI;

    address public withdrawalAddress;

    struct TokenAllocation {
        uint32 collectionSize;
        uint32 mintsPerTransaction;
        uint32 mintsPerWallet;
    }

    TokenAllocation public tokenAllocation;

    struct AuctionConfig {
        uint72 startPrice;
        uint72 floorPrice;
        uint72 priceDelta;
        uint32 expectedStepMintRate;
        uint32 startTime;
        uint32 endTime;
        uint32 stepDurationInSeconds;
    }

    AuctionConfig public auctionConfig;

    struct AuctionState {
        bool isEnabled;
        uint32 step;
        uint32 stepMints;
        uint72 stepPrice;
    }

    AuctionState internal _auctionState;

    constructor() ERC721A("EverythingsCoo", "ETC") {}

    /**
     * -----EVENTS-----
     */

    /**
     * @dev Emit on calls to auctionMint().
     */
    event AuctionMint(
        address indexed to,
        uint256 quantity,
        uint256 price,
        uint256 totalMinted,
        uint256 timestamp,
        uint256 step
    );

    /**
     * @dev Emit on calls to airdropMint().
     */
    event AirdropMint(address indexed to, uint256 quantity, uint256 price, uint256 totalMinted, uint256 timestamp);

    /**
     * @dev Emits on calls to setBaseMetadataURI()
     */
    event BaseMetadataURIChange(string baseMetadataURI, uint256 timestamp);

    /**
     * @dev Emits on calls to setWithdrawalAddress()
     */
    event WithdrawalAddressChange(address withdrawalAddress, uint256 timestamp);

    /**
     * @dev Emits on calls to withdraw()
     */
    event Withdrawal(address indexed withdrawalAddress, uint256 amount, uint256 timestamp);

    /**
     * @dev Emits on calls to setTokenAllocation()
     */
    event TokenAllocationChange(
        uint256 collectionSize,
        uint256 mintsPerTransaction,
        uint256 mintsPerWallet,
        uint256 timestamp
    );

    /**
     * @dev Emits on calls to setAuctionConfig()
     */
    event AuctionConfigChange(
        uint256 startPrice,
        uint256 floorPrice,
        uint256 priceDelta,
        uint256 expectedStepMintRate,
        uint256 startTime,
        uint256 endTime,
        uint256 stepDurationInSeconds,
        uint256 timestamp
    );

    /**
     * @dev Emits on calls to setExpectedStepMintRate()
     */
    event ExpectedStepMintRateChange(uint256 expectedStepMintRate, uint256 timestamp);

    /**
     * -----MODIFIERS-----
     */

    /**
     * @dev Check that a given mint transaction follows guidelines,
     * like not putting us over our total supply or minting too many NFTs in a single transaction,
     * (which is bad for 721A NFTs).
     */
    modifier checkMintLimits(uint256 quantity) {
        require(quantity > 0, "Mint quantity must be > 0");
        require(_totalMinted() + quantity <= tokenAllocation.collectionSize, "Exceeds total supply");
        require(quantity <= tokenAllocation.mintsPerTransaction, "Cannot mint this many in a single transaction");
        _;
    }

    /**
     * -----OWNER FUNCTIONS-----
     */

    /**
     * @dev Wrap the _pause() function from OpenZeppelin/Pausable
     * To allow preventing any mint operations while the project is paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Allow unpausing the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets `baseMetadataURI` for computing tokenURI().
     */
    function setBaseMetadataURI(string calldata baseMetadataURI) external onlyOwner {
        emit BaseMetadataURIChange(baseMetadataURI, block.timestamp);

        _baseMetadataURI = baseMetadataURI;
    }

    /**
     * @dev Sets `withdrawalAddress` for withdrawal of funds from the contract.
     */
    function setWithdrawalAddress(address withdrawalAddress_) external onlyOwner {
        require(withdrawalAddress_ != address(0), "withdrawalAddress_ cannot be the zero address");

        emit WithdrawalAddressChange(withdrawalAddress_, block.timestamp);

        withdrawalAddress = withdrawalAddress_;
    }

    /**
     * @dev Sends all ETH from the contract to `withdrawalAddress`.
     */
    function withdraw() external onlyOwner {
        require(withdrawalAddress != address(0), "withdrawalAddress cannot be the zero address");

        emit Withdrawal(withdrawalAddress, address(this).balance, block.timestamp);

        (bool success, ) = withdrawalAddress.call{value: address(this).balance}("");
        require(success, "Withdrawal transfer failed");
    }

    /**
     * @dev Sets `tokenAllocation` for mint phases.
     */
    function setTokenAllocation(
        uint32 collectionSize,
        uint32 mintsPerTransaction,
        uint32 mintsPerWallet
    ) external onlyOwner {
        require(collectionSize > 0, "collectionSize must be > 0");
        require(mintsPerTransaction > 0, "mintsPerTransaction must be > 0");
        require(mintsPerTransaction <= collectionSize, "mintsPerTransaction must be <= collectionSize");
        require(mintsPerWallet > 0, "mintsPerWallet must be > 0");
        require(mintsPerWallet <= collectionSize, "mintsPerWallet must be <= collectionSize");

        emit TokenAllocationChange(collectionSize, mintsPerTransaction, mintsPerWallet, block.timestamp);

        tokenAllocation.collectionSize = collectionSize;
        tokenAllocation.mintsPerTransaction = mintsPerTransaction;
        tokenAllocation.mintsPerWallet = mintsPerWallet;
    }

    /**
     * @dev Sets configuration for the auction mint.
     */
    function setAuctionConfig(
        uint72 startPrice,
        uint72 floorPrice,
        uint72 priceDelta,
        uint32 expectedStepMintRate,
        uint32 startTime,
        uint32 endTime,
        uint32 stepDurationInSeconds
    ) external onlyOwner {
        require(startPrice >= floorPrice, "startPrice must be >= floorPrice");
        require(priceDelta > 0, "priceDelta must be > 0");
        require(startTime >= block.timestamp, "startTime must be >= block.timestamp");
        require(endTime > startTime, "endTime must be > startTime");
        // Require stepDurationInSeconds to be at least ~1 block (current average is 14.5s per block)
        require(stepDurationInSeconds >= 30, "stepDurationInSeconds must be >= 30");

        emit AuctionConfigChange(
            startPrice,
            floorPrice,
            priceDelta,
            expectedStepMintRate,
            startTime,
            endTime,
            stepDurationInSeconds,
            block.timestamp
        );

        auctionConfig.startPrice = startPrice;
        auctionConfig.floorPrice = floorPrice;
        auctionConfig.priceDelta = priceDelta;
        auctionConfig.expectedStepMintRate = expectedStepMintRate;

        auctionConfig.startTime = startTime;
        auctionConfig.endTime = endTime;
        auctionConfig.stepDurationInSeconds = stepDurationInSeconds;

        // Set the current price of the auction to the start price,
        // and enable the auction
        _auctionState.isEnabled = true;
        _auctionState.stepPrice = startPrice;
    }

    /**
     * @dev Sets `expectedStepMintRate` for calculating price deltas.
     */
    function setExpectedStepMintRate(uint32 expectedStepMintRate) external onlyOwner {
        emit ExpectedStepMintRateChange(expectedStepMintRate, block.timestamp);

        auctionConfig.expectedStepMintRate = expectedStepMintRate;
    }

    /**
     * @dev Mints tokens to given address at no cost.
     */
    function airdropMint(address to, uint256 quantity) external onlyOwner checkMintLimits(quantity) {
        emit AirdropMint(to, quantity, 0, _totalMinted() + quantity, block.timestamp);

        _mint(to, quantity);
    }

    /**
     * -----INTERNAL FUNCTIONS-----
     */

    /**
     * @dev Base URI for computing tokenURI() (from the 721A contract). If set, the resulting URI for each
     * token will be the concatenation of the `baseMetadataURI` and the token ID. Overridden from the 721A contract.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseMetadataURI;
    }

    /**
     * @dev Returns the current auction price given the current step.
     */
    function _getAuctionPrice(uint256 currStep) internal view returns (uint256) {
        require(currStep >= _auctionState.step, "currStep must be >= auctionState.step");

        // No danger of either currStep or _auctionState.step being manipulated by an attacker,
        // and we need to do a strict equality check here to return the current auction price.
        //
        // slither-disable-next-line incorrect-equality
        if (currStep == _auctionState.step) {
            return _auctionState.stepPrice;
        }

        // passedSteps will always be > 0, because of the require & if statement above
        uint256 passedSteps = currStep - _auctionState.step;
        uint256 price = _auctionState.stepPrice;
        uint256 numMinted = _auctionState.stepMints;
        uint256 floorPrice = auctionConfig.floorPrice;
        uint256 priceDelta = auctionConfig.priceDelta;

        if (numMinted >= auctionConfig.expectedStepMintRate) {
            price += 3 * priceDelta;
        } else {
            // If the `priceChange` would put the price below the floor, return the floor
            price = floorPrice + priceDelta < price ? price - priceDelta : floorPrice;
        }

        // If there were steps where nobody minted anything, then determine price change for nothing minted
        if (passedSteps > 1) {
            uint256 aggregatePriceChange = (passedSteps - 1) * priceDelta;

            // If the `aggregatePriceChange` would put the price below the floor, return the floor
            price = floorPrice + aggregatePriceChange < price ? price - aggregatePriceChange : floorPrice;
        }

        return price;
    }

    /**
     * -----VIEW FUNCTIONS-----
     */

    /**
     * @dev Returns a tuple of the current step and price.
     */
    function getCurrentStepAndPrice() public view returns (uint256, uint256) {
        uint256 currentStep = getCurrentStep();
        uint256 currentPrice = _getAuctionPrice(currentStep);

        return (currentStep, currentPrice);
    }

    /**
     * @dev Returns the current step of the auction based on the elapsed time.
     */
    function getCurrentStep() public view returns (uint256) {
        require(_auctionState.isEnabled && block.timestamp >= auctionConfig.startTime, "Auction has not started");

        uint256 elapsedTime = block.timestamp - auctionConfig.startTime;
        uint256 step = Math.min(
            elapsedTime / auctionConfig.stepDurationInSeconds,
            (auctionConfig.endTime - auctionConfig.startTime) / auctionConfig.stepDurationInSeconds
        );

        return step;
    }

    /**
     * @dev Returns the current auction price.
     */
    function getCurrentAuctionPrice() external view returns (uint256) {
        (, uint256 price) = getCurrentStepAndPrice();

        return price;
    }

    /**
     * -----EXTERNAL FUNCTIONS-----
     */

    /**
     * @dev Mints `quantity` of tokens at the current auction price and transfers them to the sender.
     * If the sender sends more ETH than needed, it refunds them.
     */
    function auctionMint(uint256 quantity) external payable whenNotPaused checkMintLimits(quantity) {
        // We explicitly want to use tx.origin to check if the caller is a contract
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == msg.sender, "Caller must be user");
        require(_auctionState.isEnabled && block.timestamp >= auctionConfig.startTime, "Auction has not started");
        require(block.timestamp < auctionConfig.endTime, "Auction has ended");
        require(
            _numberMinted(msg.sender) + quantity <= tokenAllocation.mintsPerWallet,
            "Cannot mint this many from a single wallet"
        );

        (uint256 auctionStep, uint256 auctionPrice) = getCurrentStepAndPrice();
        uint256 cost = auctionPrice * quantity;

        require(msg.value >= cost, "Insufficient payment");

        // Update auction state to the new step and new price
        if (auctionStep > _auctionState.step) {
            _auctionState.stepMints = 0;
            _auctionState.stepPrice = uint72(auctionPrice);
            _auctionState.step = uint32(auctionStep);
        }

        _auctionState.stepMints += uint32(quantity);
        emit AuctionMint(msg.sender, quantity, auctionPrice, _totalMinted() + quantity, block.timestamp, auctionStep);

        // Contracts can't call this function so we don't need _safeMint()
        _mint(msg.sender, quantity);

        if (msg.value > cost) {
            (bool success, ) = msg.sender.call{value: msg.value - cost}("");
            require(success, "Refund transfer failed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./EverythingsCoo.sol";

contract EverythingsCooTestable is EverythingsCoo {
    constructor() EverythingsCoo() {}

    function auctionState() external view returns (AuctionState memory) {
        return _auctionState;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function getAuctionPrice(uint256 currStep) external view returns (uint256) {
        return _getAuctionPrice(currStep);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./EverythingsCoo.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract EverythingsCooCaller is IERC721Receiver {
    function mint(address contractAddress, uint256 quantity) external payable {
        EverythingsCoo etc = EverythingsCoo(contractAddress);
        etc.auctionMint{value: msg.value}(quantity);
    }

    // Must be implemented so we can receive tokens via safeTransfer
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract CRA is Ownable, Pausable, ERC721A {
    string internal _baseMetadataURI;

    address public withdrawalAddress;

    struct TokenAllocation {
        uint256 collectionSize;
        uint256 mintsPerTransaction;
        uint256 mintsPerWallet;
    }

    TokenAllocation public tokenAllocation;

    struct AuctionConfig {
        uint256 startPrice;
        uint256 floorPrice;
        uint256 priceDelta;
        uint256 expectedStepMintRate;
        uint256 startBlock;
        uint256 stepDuration;
        uint256 lengthInSteps;
    }

    AuctionConfig public auctionConfig;

    struct AuctionState {
        bool isEnabled;
        uint256 step;
        uint256 stepMints;
        uint256 stepPrice;
    }

    AuctionState internal _auctionState;

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

    /**
     * -----EVENTS-----
     */

    /**
     * @dev Emit on calls to auctionMint().
     */
    event AuctionMint(
        address indexed to,
        uint256 quantity,
        uint256 price,
        uint256 totalMinted,
        uint256 timestamp,
        uint256 step
    );

    /**
     * @dev Emit on calls to auctionMint() when the price changes.
     */
    event AuctionPriceChange(uint256 price, uint256 step);

    /**
     * @dev Emit on calls to airdropMint().
     */
    event AirdropMint(address indexed to, uint256 quantity, uint256 price, uint256 totalMinted, uint256 timestamp);

    /**
     * -----MODIFIERS-----
     */

    /**
     * @dev Check that a given mint transaction follows guidelines,
     * like not putting us over our total supply or minting too many NFTs in a single transaction,
     * (which is bad for 721A NFTs).
     */
    modifier checkMintLimits(uint256 quantity) {
        require(quantity > 0, "Mint quantity must be > 0");
        require(_totalMinted() + quantity <= tokenAllocation.collectionSize, "Exceeds total supply");
        require(quantity <= tokenAllocation.mintsPerTransaction, "Cannot mint this many in a single transaction");
        _;
    }

    /**
     * -----OWNER FUNCTIONS-----
     */

    /**
     * @dev Wrap the _pause() function from OpenZeppelin/Pausable
     * To allow preventing any mint operations while the project is paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Allow unpausing the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets `baseMetadataURI` for computing tokenURI().
     */
    function setBaseMetadataURI(string calldata baseMetadataURI) external onlyOwner {
        _baseMetadataURI = baseMetadataURI;
    }

    /**
     * @dev Sets `withdrawalAddress` for withdrawal of funds from the contract.
     */
    function setWithdrawalAddress(address withdrawalAddress_) external onlyOwner {
        require(withdrawalAddress_ != address(0), "withdrawalAddress_ cannot be the zero address");

        withdrawalAddress = withdrawalAddress_;
    }

    /**
     * @dev Sends all ETH from the contract to `withdrawalAddress`.
     */
    function withdraw() external onlyOwner {
        require(withdrawalAddress != address(0), "withdrawalAddress cannot be the zero address");

        (bool success, ) = withdrawalAddress.call{value: address(this).balance}("");
        require(success, "Withdrawal transfer failed");
    }

    /**
     * @dev Sets `tokenAllocation` for mint phases.
     */
    function setTokenAllocation(
        uint256 collectionSize,
        uint256 mintsPerTransaction,
        uint256 mintsPerWallet
    ) external onlyOwner {
        require(collectionSize > 0, "collectionSize must be > 0");
        require(mintsPerTransaction > 0, "mintsPerTransaction must be > 0");
        require(mintsPerTransaction <= collectionSize, "mintsPerTransaction must be <= collectionSize");
        require(mintsPerWallet > 0, "mintsPerWallet must be > 0");
        require(mintsPerWallet <= collectionSize, "mintsPerWallet must be <= collectionSize");

        tokenAllocation.collectionSize = collectionSize;
        tokenAllocation.mintsPerTransaction = mintsPerTransaction;
        tokenAllocation.mintsPerWallet = mintsPerWallet;
    }

    /**
     * @dev Sets configuration for the auction mint.
     */
    function setAuctionConfig(
        uint256 startPrice,
        uint256 floorPrice,
        uint256 priceDelta,
        uint256 expectedStepMintRate,
        uint256 startBlock,
        uint256 stepDuration,
        uint256 lengthInSteps
    ) external onlyOwner {
        require(startPrice >= floorPrice, "startPrice must be >= floorPrice");
        require(priceDelta > 0, "priceDelta must be > 0");
        require(startBlock >= block.number, "startBlock must be >= block.number");
        require(stepDuration > 0, "stepDuration must be > 0");
        require(lengthInSteps > 0, "lengthInSteps must be > 0");

        _auctionState.isEnabled = true;

        auctionConfig.startPrice = startPrice;
        auctionConfig.floorPrice = floorPrice;
        auctionConfig.priceDelta = priceDelta;
        auctionConfig.expectedStepMintRate = expectedStepMintRate;

        auctionConfig.startBlock = startBlock;
        auctionConfig.stepDuration = stepDuration;
        auctionConfig.lengthInSteps = lengthInSteps;

        _auctionState.stepPrice = startPrice;
    }

    /**
     * @dev Sets `expectedStepMintRate` for calculating price deltas.
     */
    function setExpectedStepMintRate(uint256 expectedStepMintRate) external onlyOwner {
        auctionConfig.expectedStepMintRate = expectedStepMintRate;
    }

    /**
     * @dev Mints tokens to given address at no cost.
     */
    function airdropMint(address to, uint256 quantity) external onlyOwner checkMintLimits(quantity) {
        emit AirdropMint(to, quantity, 0, _totalMinted() + quantity, block.timestamp);

        _mint(to, quantity);
    }

    /**
     * -----INTERNAL FUNCTIONS-----
     */

    /**
     * @dev Base URI for computing tokenURI() (from the 721A contract). If set, the resulting URI for each
     * token will be the concatenation of the `baseMetadataURI` and the token ID. Overridden from the 721A contract.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseMetadataURI;
    }

    /**
     * @dev Calculates how the price should change for a given step.
     * Returns a tuple of the price change and whether the price should increase (true) or go down (false).
     */
    function _getStepPriceChange(uint256 numMinted) internal view virtual returns (uint256, bool) {
        if (numMinted >= auctionConfig.expectedStepMintRate) {
            return (auctionConfig.priceDelta, true);
        } else {
            return (auctionConfig.priceDelta, false);
        }
    }

    /**
     * @dev Returns the current auction price given the current step.
     */
    function _getAuctionPrice(uint256 currStep) internal view returns (uint256) {
        require(currStep > _auctionState.step, "currStep must be > auctionState.step");

        // This will always be > 0, because of the require statement above
        uint256 passedSteps = currStep - _auctionState.step;
        uint256 price = _auctionState.stepPrice;
        uint256 numMinted = _auctionState.stepMints;

        (uint256 priceChange, bool increasePrice) = _getStepPriceChange(numMinted);
        if (increasePrice) {
            price += priceChange;
        } else {
            // If the `priceChange` would put the price below the floor, return the floor
            price = auctionConfig.floorPrice + priceChange < price ? price - priceChange : auctionConfig.floorPrice;
        }

        // If there were steps where nobody minted anything,
        // Then decrease price by the relevant number of steps.
        if (passedSteps > 1) {
            // We know if passedSteps > 1, then numMinted === 0 for those steps,
            // so pass that to _getStepPriceChange() as a hardcoded value.
            (priceChange, increasePrice) = _getStepPriceChange(0);
            uint256 aggregatePriceChange = (passedSteps - 1) * priceChange;

            if (increasePrice) {
                price += aggregatePriceChange;
            } else {
                // If the `aggregatePriceChange` would put the price below the floor, return the floor
                price = auctionConfig.floorPrice + aggregatePriceChange < price
                    ? price - aggregatePriceChange
                    : auctionConfig.floorPrice;
            }
        }

        return price;
    }

    /**
     * -----VIEW FUNCTIONS-----
     */

    /**
     * @dev Returns the current auction price.
     */
    function getCurrentAuctionPrice() external view returns (uint256) {
        (, uint256 price) = getCurrentStepAndPrice();

        return price;
    }

    /**
     * @dev Returns the current step of the auction based on the elapsed time.
     */
    function getCurrentStep() public view returns (uint256) {
        require(_auctionState.isEnabled && block.number >= auctionConfig.startBlock, "Auction has not started");

        uint256 elapsedBlocks = block.number - auctionConfig.startBlock;
        uint256 step = Math.min(elapsedBlocks / auctionConfig.stepDuration, auctionConfig.lengthInSteps - 1);

        return step;
    }

    /**
     * @dev Returns a tuple of the current step and price.
     */
    function getCurrentStepAndPrice() public view returns (uint256, uint256) {
        uint256 currentStep = getCurrentStep();

        // False positive guarding against using strict equality checks
        // Shouldn't be a problem here because we check for > and < cases
        // slither-disable-next-line incorrect-equality
        if (currentStep == _auctionState.step) {
            return (_auctionState.step, _auctionState.stepPrice);
        } else if (currentStep > _auctionState.step) {
            return (currentStep, _getAuctionPrice(currentStep));
        } else {
            revert("Step is < _currentStep");
        }
    }

    /**
     * -----EXTERNAL FUNCTIONS-----
     */

    /**
     * @dev Mints `quantity` of tokens at the current auction price and transfers them to the sender.
     * If the sender sends more ETH than needed, it refunds them.
     */
    function auctionMint(uint256 quantity) external payable whenNotPaused checkMintLimits(quantity) {
        // We explicitly want to use tx.origin to check if the caller is a contract
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == msg.sender, "Caller must be user");
        require(_auctionState.isEnabled && block.number >= auctionConfig.startBlock, "Auction has not started");
        require(
            block.number < auctionConfig.startBlock + (auctionConfig.lengthInSteps * auctionConfig.stepDuration),
            "Auction has ended"
        );
        require(
            _numberMinted(msg.sender) + quantity <= tokenAllocation.mintsPerWallet,
            "Cannot mint this many from a single wallet"
        );

        (uint256 auctionStep, uint256 auctionPrice) = getCurrentStepAndPrice();
        uint256 cost = auctionPrice * quantity;

        require(msg.value >= cost, "Insufficient payment");

        // Update auction state to the new step and new price
        if (auctionStep > _auctionState.step) {
            if (_auctionState.stepPrice != auctionPrice) {
                emit AuctionPriceChange(auctionPrice, auctionStep);
            }

            _auctionState.stepMints = 0;
            _auctionState.stepPrice = auctionPrice;
            _auctionState.step = auctionStep;
        }

        _auctionState.stepMints += quantity;
        emit AuctionMint(msg.sender, quantity, auctionPrice, _totalMinted() + quantity, block.timestamp, auctionStep);

        // Contracts can't call this function so we don't need _safeMint()
        _mint(msg.sender, quantity);

        if (msg.value > cost) {
            (bool success, ) = msg.sender.call{value: msg.value - cost}("");
            require(success, "Refund transfer failed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CRA.sol";

contract CRATestable is CRA {
    constructor(string memory name_, string memory symbol_) CRA(name_, symbol_) {}

    function auctionState() external view returns (AuctionState memory) {
        return _auctionState;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function getStepPriceChange(uint256 numMinted) external view returns (uint256, bool) {
        return _getStepPriceChange(numMinted);
    }

    function getAuctionPrice(uint256 currStep) external view returns (uint256) {
        return _getAuctionPrice(currStep);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CRATestable.sol";
import "./CRADifferentialPricing.sol";

contract CRADifferentialPricingTestable is CRADifferentialPricing {
    constructor(string memory name_, string memory symbol_) CRADifferentialPricing(name_, symbol_) {}

    function getAuctionPrice(uint256 currStep) external view returns (uint256) {
        return _getAuctionPrice(currStep);
    }

    function getStepPriceChange(uint256 numMinted) external view returns (uint256, bool) {
        return _getStepPriceChange(numMinted);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CRA.sol";

contract CRADifferentialPricing is CRA {
    constructor(string memory name_, string memory symbol_) CRA(name_, symbol_) {}

    function _getStepPriceChange(uint256 numMinted) internal view override returns (uint256, bool) {
        if (numMinted >= auctionConfig.expectedStepMintRate) {
            return (3 * auctionConfig.priceDelta, true);
        } else {
            return (auctionConfig.priceDelta, false);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CRA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract CRACaller is IERC721Receiver {
    function mint(address contractAddress, uint256 quantity) external payable {
        CRA cra = CRA(contractAddress);
        cra.auctionMint{value: msg.value}(quantity);
    }

    // Must be implemented so we can receive tokens via safeTransfer
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}