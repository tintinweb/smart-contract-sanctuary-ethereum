// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {ERC721A} from "./token/ERC721A.sol";
import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BoundLayerable} from "./utils/BoundLayerable.sol";
import {OnChainLayerable} from "./utils/OnChainLayerable.sol";
import {RandomTraits} from "./utils/RandomTraits.sol";
import {json} from "./utils/JSON.sol";
import "./utils/Errors.sol";

contract Token is ERC721A, Ownable, ReentrancyGuard, OnChainLayerable {
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant MINT_PRICE = 0 ether;
    bool private tradingActive = true;

    // EIP-2309
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );

    // TODO: disable transferring to someone who does not own a base layer?
    constructor(
        string memory _name,
        string memory _symbol,
        string memory defaultURI
    ) ERC721A(_name, _symbol) OnChainLayerable(defaultURI) {}

    modifier includesCorrectPayment(uint256 _numSets) {
        if (msg.value != _numSets * MINT_PRICE) {
            revert IncorrectPayment();
        }
        _;
    }

    function disableTrading() external onlyOwner {
        if (!tradingActive) {
            revert TradingAlreadyDisabled();
        }
        // todo: break this out if it will hit gas limit
        _burnLayers();
        // this will free up some gas!
        tradingActive = false;
    }

    function _burnLayers() private {
        // iterate over all token ids
        for (uint256 i; i < MAX_SUPPLY; ) {
            if (i % 7 != 0) {
                // get owner of layer
                address owner_ = super.ownerOf(i);
                // "burn" layer by emitting transfer event to null address
                // note: can't use bulktransfer bc no guarantee that all layers are owned by same address
                emit Transfer(owner_, address(0), i);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _burnLayers(uint256 _start, uint256 _end) public onlyOwner {}

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        // if trading layers is no longer active, report owner as null address
        // TODO: might be able to optimize this with two separate if statements
        if (_tokenId % 7 != 0 && !tradingActive) {
            return address(0);
        }
        return super.ownerOf(_tokenId);
    }

    function mintSet() public payable includesCorrectPayment(1) nonReentrant {
        super._safeMint(msg.sender, 7);
    }

    function mintSets(uint256 _numSets)
        public
        payable
        includesCorrectPayment(_numSets)
        nonReentrant
    {
        super._safeMint(msg.sender, 7 * _numSets);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return getTokenURI(_tokenId);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "./IERC721A.sol";

/**
 * @dev ERC721 token receiver interface.
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
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        if (_addressToUint256(owner) == 0) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return
            (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) &
            BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return
            (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) &
            BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        assembly {
            // Cast aux without masking.
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId)
        private
        view
        returns (uint256)
    {
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
    function _unpackedOwnership(uint256 packed)
        private
        pure
        returns (TokenOwnership memory ownership)
    {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index)
        internal
        view
        returns (TokenOwnership memory)
    {
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
    function _ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
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
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev Casts the address to uint256 without masking.
     */
    function _addressToUint256(address value)
        private
        pure
        returns (uint256 result)
    {
        assembly {
            result := value
        }
    }

    /**
     * @dev Casts the boolean to uint256 without branching.
     */
    function _boolToUint256(bool value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = address(uint160(_packedOwnershipOf(tokenId)));
        if (to == owner) revert ApprovalToCurrentOwner();

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
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
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
        _safeMint(to, quantity, "");
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
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (_addressToUint256(to) == 0) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] +=
                quantity *
                ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.code.length != 0) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (
                        !_checkContractOnERC721Received(
                            address(0),
                            to,
                            updatedIndex++,
                            _data
                        )
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
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
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (_addressToUint256(to) == 0) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] +=
                quantity *
                ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

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
    ) private {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from)
            revert TransferFromIncorrectOwner();

        address approvedAddress = _tokenApprovals[tokenId];

        bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
            isApprovedForAll(from, _msgSenderERC721A()) ||
            approvedAddress == _msgSenderERC721A());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (_addressToUint256(to) == 0) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        if (_addressToUint256(approvedAddress) != 0) {
            delete _tokenApprovals[tokenId];
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
            _packedOwnerships[tokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_NEXT_INITIALIZED;

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
        address approvedAddress = _tokenApprovals[tokenId];

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
                isApprovedForAll(from, _msgSenderERC721A()) ||
                approvedAddress == _msgSenderERC721A());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        if (_addressToUint256(approvedAddress) != 0) {
            delete _tokenApprovals[tokenId];
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
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
            _packedOwnerships[tokenId] =
                _addressToUint256(from) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_BURNED |
                BITMASK_NEXT_INITIALIZED;

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
        try
            ERC721A__IERC721Receiver(to).onERC721Received(
                _msgSenderERC721A(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return
                retval ==
                ERC721A__IERC721Receiver(to).onERC721Received.selector;
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
    function _toString(uint256 value)
        internal
        pure
        returns (string memory ptr)
    {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PackedByteUtility} from "./PackedByteUtility.sol";
import {BitFieldUtility} from "./BitFieldUtility.sol";
import {LayerVariation} from "./Structs.sol";
import "./Errors.sol";

contract BoundLayerable is Ownable {
    string baseLayerURI;

    // TODO: potentially initialize at mint by setting leftmost bit; will quarter gas cost of binding layers
    mapping(uint256 => uint256) internal _tokenIdToBoundLayers;
    mapping(uint256 => uint256[]) internal _tokenIdToPackedActiveLayers;
    LayerVariation[] public layerVariations;

    /////////////
    // SETTERS //
    /////////////

    function setBaseLayerURI(string calldata _baseLayerURI) external onlyOwner {
        baseLayerURI = _baseLayerURI;
    }

    function bindLayersBulk(
        uint256[] calldata _tokenId,
        uint256[] calldata _layers
    ) public onlyOwner {
        // TODO: check tokenIds are valid?
        uint256 tokenIdLength = _tokenId.length;
        if (tokenIdLength != _layers.length) {
            revert ArrayLengthMismatch(tokenIdLength, _layers.length);
        }
        for (uint256 i; i < tokenIdLength; ) {
            _tokenIdToBoundLayers[_tokenId[i]] = _layers[i] & ~uint256(1);
            unchecked {
                ++i;
            }
        }
    }

    function bindLayers(uint256 _tokenId, uint256 _layers) public onlyOwner {
        // 0th bit is not a valid layer; make sure it is set to 0 with a bitmask
        _tokenIdToBoundLayers[_tokenId] = _layers & ~uint256(1);
    }

    function setActiveLayers(uint256 _tokenId, uint256[] calldata _packedLayers)
        external
    {
        // TODO: check tokenId is owned or authorized for msg.sender

        // unpack layers into a single bitfield and check there are no duplicates
        uint256 unpackedLayers = _unpackLayersAndCheckForDuplicates(
            _packedLayers
        );
        uint256 boundLayers = _tokenIdToBoundLayers[_tokenId];
        // check new active layers are all bound to tokenId
        _checkUnpackedIsSubsetOfBound(unpackedLayers, boundLayers);
        // check active layers do not include multiple variations of the same trait
        _checkForMultipleVariations(boundLayers, unpackedLayers);

        _tokenIdToPackedActiveLayers[_tokenId] = _packedLayers;
    }

    // CHECK //

    function _unpackLayersAndCheckForDuplicates(
        uint256[] calldata _packedLayersArr
    ) internal virtual returns (uint256) {
        uint256 unpackedLayers;
        uint256 packedLayersArrLength = _packedLayersArr.length;
        for (uint256 i; i < packedLayersArrLength; ++i) {
            uint256 packedLayers = _packedLayersArr[i];
            // emit log_named_uint('packed layers', packedLayers);
            for (uint256 j; j < 32; ++j) {
                // uint8
                uint256 layer = PackedByteUtility.getPackedByteFromLeft(
                    j,
                    packedLayers
                );
                // emit log_named_uint('unpacked layer', layer);
                if (layer == 0) {
                    break;
                }
                // todo: see if assembly dropping least significant 1's is more efficient here
                if (_layerIsBoundToTokenId(unpackedLayers, layer)) {
                    revert DuplicateActiveLayers();
                }
                unpackedLayers |= (1 << layer);
            }
        }
        return unpackedLayers;
    }

    function packedLayersToBitField(uint256[] calldata _packedLayersArr)
        public
        pure
        returns (uint256)
    {
        uint256 unpackedLayers;
        uint256 packedLayersArrLength = _packedLayersArr.length;
        for (uint256 i; i < packedLayersArrLength; ++i) {
            uint256 packedLayers = _packedLayersArr[i];
            for (uint256 j; j < 32; ++j) {
                uint256 layer = PackedByteUtility.getPackedByteFromLeft(
                    j,
                    packedLayers
                );
                if (layer == 0) {
                    break;
                }
                unpackedLayers |= (1 << layer);
            }
        }
        return unpackedLayers;
    }

    function layersToBitField(uint8[] calldata layers)
        public
        pure
        returns (uint256)
    {
        uint256 unpackedLayers;
        uint256 layersLength = layers.length;
        for (uint256 i; i < layersLength; ++i) {
            uint8 layer = layers[i];
            if (layer == 0) {
                break;
            }
            unpackedLayers |= (1 << layer);
        }
        return unpackedLayers;
    }

    function _checkUnpackedIsSubsetOfBound(
        uint256 _unpackedLayers,
        uint256 _boundLayers
    ) internal pure virtual {
        // boundLayers should be superset of unpackedLayers
        uint256 unionSetLayers = (_boundLayers | _unpackedLayers);
        if (unionSetLayers != _boundLayers) {
            revert LayerNotBoundToTokenId();
        }
    }

    function _checkForMultipleVariations(
        uint256 _boundLayers,
        uint256 _unpackedLayers
    ) internal view {
        uint256 variationsLength = layerVariations.length;
        for (uint256 i; i < variationsLength; ++i) {
            LayerVariation memory variation = layerVariations[i];
            if (_layerIsBoundToTokenId(_boundLayers, variation.layerId)) {
                int256 activeVariations = int256(
                    // put variation bytes at the end of the number
                    (_unpackedLayers >> variation.layerId) &
                        // drop bits above numVariations by &'ing with the same number of 1s
                        ((1 << variation.numVariations) - 1)
                );
                // n&(n-1) drops least significant 1
                // valid active variation sets are powers of 2 (a single 1) or 0
                uint256 zeroIfOneOrNoneActive = uint256(
                    activeVariations & (activeVariations - 1)
                );
                if (zeroIfOneOrNoneActive != 0) {
                    revert MultipleVariationsEnabled();
                }
            }
        }
    }

    /////////////
    // GETTERS //
    /////////////

    function getBoundLayers(uint256 _tokenId)
        public
        view
        returns (uint256[] memory)
    {
        return BitFieldUtility.unpackBitField(_tokenIdToBoundLayers[_tokenId]);
    }

    function getActiveLayers(uint256 _tokenId)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory activePackedLayers = _tokenIdToPackedActiveLayers[
            _tokenId
        ];
        uint256[] memory unpacked = PackedByteUtility.unpackByteArrays(
            activePackedLayers
        );
        uint256 length = unpacked.length;
        uint256 realLength;
        for (uint256 i; i < length; i++) {
            if (unpacked[i] == 0) {
                break;
            }
            unchecked {
                ++realLength;
            }
        }
        uint256[] memory layers = new uint256[](realLength);
        for (uint256 i; i < realLength; ++i) {
            layers[i] = unpacked[i];
        }
        return layers;
    }

    /////////////
    // HELPERS //
    /////////////

    function _layerIsBoundToTokenId(uint256 _boundLayers, uint256 _layer)
        internal
        pure
        virtual
        returns (bool isBound)
    {
        assembly {
            isBound := and(shr(_layer, _boundLayers), 1)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {BoundLayerable} from "./BoundLayerable.sol";
import {OnChainTraits} from "./OnChainTraits.sol";
import {svg, utils} from "../SVG.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {RandomTraits} from "./RandomTraits.sol";
import {json} from "./JSON.sol";

// import {DSTestPlusPlus} from 'src/test/utils/DSTestPlusPlus.sol';

contract OnChainLayerable is OnChainTraits, RandomTraits, BoundLayerable {
    using Strings for uint256;

    string defaultURI;

    constructor(string memory _defaultURI) RandomTraits(7) {
        defaultURI = _defaultURI;
    }

    function setDefaultURI(string calldata _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function getLayerURI(uint256 _layerId) public view returns (string memory) {
        return string.concat(baseLayerURI, _layerId.toString(), ".png");
    }

    function getTokenSVG(uint256 _tokenId) public view returns (string memory) {
        uint256[] memory activeLayers = getActiveLayers(_tokenId);
        string memory layerImages = "";
        for (uint256 i; i < activeLayers.length; ++i) {
            string memory layerUri = getLayerURI(activeLayers[i]);
            // emit log(layerUri);
            layerImages = string.concat(
                layerImages,
                svg.image(layerUri, svg.prop("height", "100%"))
            );
        }

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg">',
                layerImages,
                "</svg>"
            );
    }

    function getTokenTraits(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        uint256[] memory boundLayers = getBoundLayers(_tokenId);
        string[] memory layerTraits = new string[](boundLayers.length);
        for (uint256 i; i < boundLayers.length; ++i) {
            layerTraits[i] = getTraitJson(boundLayers[i]);
        }
        return json.arrayOf(layerTraits);
    }

    function getTokenURI(uint256 _tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        string[] memory properties = new string[](2);

        // return default uri
        if (traitGenerationSeed == 0) {
            return defaultURI;
        }
        uint256 bindings = _tokenIdToBoundLayers[_tokenId];

        // if no bindings, format metadata as an individual NFT
        if (bindings == 0) {
            uint256 layerId = getLayerId(_tokenId);
            properties[0] = json.property("image", getLayerURI(layerId));
            properties[1] = json.property(
                "attributes",
                json.array(getTraitJson(layerId))
            );
        } else {
            properties[0] = json.property("image", getTokenSVG(_tokenId));
            properties[1] = json.property(
                "attributes",
                getTokenTraits(_tokenId)
            );
        }
        return json.objectOf(properties);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PackedByteUtility} from "./PackedByteUtility.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {LayerType} from "./Enums.sol";
import {BadDistributions} from "./Errors.sol";

contract RandomTraits is Ownable {
    using Strings for uint256;

    bytes32 public traitGenerationSeed;

    // 32 possible traits per layerType  given uint8 distributions
    // getLayerId will check if traitValue is less than the distribution
    // so traits distribution cutoffs should be sorted left-to-right
    // ie smallest packed 8-bit segment should be the leftmost 8 bits
    mapping(LayerType => uint256) layerTypeToDistributions;
    // TODO: investigate more granular rarity distributions by packing shorts into 2 uint256's
    // mapping(LayerType => uint256[2]) layerTypeToShortDistributions;
    // mapping(uint256 => uint256[]) layerTypeToTraitIds;
    uint256 immutable NUM_TOKENS_PER_SET;

    constructor(uint256 _numTraitTypes) {
        NUM_TOKENS_PER_SET = _numTraitTypes;
    }

    /////////////
    // SETTERS //
    /////////////

    function setTraitGenerationSeed(bytes32 _traitGenerationSeed)
        public
        onlyOwner
    {
        traitGenerationSeed = _traitGenerationSeed;
    }

    /**
     * @notice Set the probability distribution for up to 32 different layer traitIds
     * @param _layerType layer type to set distribution for
     * @param _distribution a uint256 comprised of sorted, packed bytes
     *  that will be compared against a random byte to determine the layerId
     *  for a given tokenId
     */
    function setLayerTypeDistribution(
        LayerType _layerType,
        uint256 _distribution
    ) public onlyOwner {
        layerTypeToDistributions[_layerType] = _distribution;
    }

    /// @notice Get the random seed for a given tokenId by hashing it with the traitGenerationSeed
    function getLayerSeed(uint256 _tokenId, LayerType _layerType)
        public
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(abi.encode(traitGenerationSeed, _tokenId, _layerType))
            );
    }

    /**
     * @notice Determine layer type by its token ID
     */
    function getLayerType(uint256 _tokenId) public view returns (LayerType) {
        // might break tests but could move objects and borders to front:
        // LayerType((_tokenId % NUM_TOKENS_PER_SET) % 5);
        uint256 layerTypeValue = _tokenId % NUM_TOKENS_PER_SET;
        if (layerTypeValue == 4) {
            // objects
            return LayerType(3);
        } else if (layerTypeValue == 5 || layerTypeValue == 6) {
            // borders
            return LayerType(4);
        }
        // portraits, backgrounds, textures
        return LayerType(layerTypeValue);
    }

    /**
     * @notice Get the layerId for a given tokenId by hashing tokenId with the random seed
     * and comparing the final byte against the appropriate distributions
     */
    function getLayerId(uint256 _tokenId) public view returns (uint256) {
        LayerType layerType = getLayerType(_tokenId);
        uint256 layerSeed = getLayerSeed(_tokenId, layerType) & 0xff;
        uint256 distributions = layerTypeToDistributions[layerType];
        // iterate over distributions until we find one that our layer seed is *less than*
        uint256 i;
        for (; i < 32; ) {
            uint8 distribution = PackedByteUtility.getPackedByteFromLeft(
                i,
                distributions
            );
            // if distribution is 0, we've reached the end of the list
            if (distribution == 0) {
                if (i > 0) {
                    return (i + 1) + 32 * uint256(layerType);
                } else {
                    // first distribution should not be 0
                    revert BadDistributions();
                }
            }
            // note: for layers with multiple variations, the same value should be packed multiple times
            if (layerSeed < distribution) {
                return (i + 1) + 32 * uint256(layerType);
            }
            unchecked {
                ++i;
            }
        }
        // in the case that there are 32 distributions, default to the last id
        return (i) + 32 * uint256(layerType);
    }

    // function getLayerId2(uint256 _tokenId) public view returns (uint256) {
    //     LayerType layerType = getLayerType(_tokenId);
    //     uint256 layerSeed = getLayerSeed(_tokenId, layerType) & 0xffff;
    //     // uint256 distributions = layerTypeToDistributions[layerType];
    //     // iterate over distributions until we find one that our layer seed is *less than*
    //     uint256 i;
    //     uint256[2] memory distributions16Bit = layerTypeTo16BitDistributions[
    //         layerType
    //     ];
    //     for (uint256 j; j < 2; ) {
    //         uint256 distribution = PackedByteUtility.getPackedByteFromLeft(
    //             i,
    //             distributions16Bit[j]
    //         );
    //         for (; i < 16; ) {
    //             uint16 distributions = PackedByteUtility.getPackedShortFromLeft(
    //                 i,
    //                 distributions
    //             );
    //             // if distribution is 0, we've reached the end of the list
    //             if (distribution == 0) {
    //                 if (i > 0) {
    //                     return i + 32 * uint256(layerType);
    //                 } else {
    //                     // first distribution should not be 0
    //                     revert BadDistributions();
    //                 }
    //             }
    //             // note: for layers with multiple variations, the same value should be packed multiple times
    //             if (layerSeed < distribution) {
    //                 return i + 32 * uint256(layerType);
    //             }
    //             unchecked {
    //                 ++i;
    //             }
    //         }
    //     }
    //     // in the case that there are 32 distributions, default to the last id
    //     return (i - 1) + 32 * uint256(layerType);

    //     // revert("Something went wrong getting Trait ID");
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library json {
    using Strings for uint256;

    function object(string memory _value)
        internal
        pure
        returns (string memory)
    {
        return string.concat("{", _value, "}");
    }

    function objectOf(string[] memory properties)
        internal
        pure
        returns (string memory)
    {
        if (properties.length == 0) {
            return object("");
        }
        string memory result = properties[0];
        for (uint256 i = 1; i < properties.length; ++i) {
            result = string.concat(result, ",", properties[i]);
        }
        return object(result);
    }

    function array(string memory _value) internal pure returns (string memory) {
        return string.concat("[", _value, "]");
    }

    function arrayOf(string[] memory _values)
        internal
        pure
        returns (string memory)
    {
        if (_values.length == 0) {
            return array("");
        }
        string memory _result = _values[0];
        for (uint256 i = 1; i < _values.length; ++i) {
            _result = string.concat(_result, ",", _values[i]);
        }
        return array(_result);
    }

    function property(string memory _name, string memory _value)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', _name, '":"', _value, '"');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

error TradingAlreadyDisabled();
error IncorrectPayment();
error ArrayLengthMismatch(uint256 length1, uint256 length2);
error LayerNotBoundToTokenId();
error DuplicateActiveLayers();
error MultipleVariationsEnabled();
error InvalidLayer(uint256 layer);
error BadDistributions();

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
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
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

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

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
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
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
pragma solidity >=0.8.4;

library PackedByteUtility {
    // TODO: return uint256s with bitmasking
    function getPackedByteFromRight(uint256 _index, uint256 _packedBytes)
        internal
        pure
        returns (uint8 result)
    {
        assembly {
            result := byte(sub(31, _index), _packedBytes)
        }
    }

    function getPackedByteFromLeft(uint256 _index, uint256 _packedBytes)
        internal
        pure
        returns (uint8 result)
    {
        assembly {
            result := byte(_index, _packedBytes)
        }
    }

    function getPackedShortFromRight(uint256 _index, uint256 _packedShorts)
        internal
        pure
        returns (uint256 result)
    {
        // TODO: investigate structs
        // 9 gas
        assembly {
            result := and(shr(mul(_index, 16), _packedShorts), 0xffff)
        }
    }

    function getPackedShortFromLeft(uint256 _index, uint256 _packedShorts)
        internal
        pure
        returns (uint256 result)
    {
        // 12 gas
        assembly {
            result := and(shr(mul(sub(16, _index), 16), _packedShorts), 0xffff)
        }
    }

    function unpackBytesToBitField(uint256 _packedBytes)
        internal
        pure
        returns (uint256 unpacked)
    {
        assembly {
            for {
                let i := 0
            } lt(i, 32) {
                i := add(i, 1)
            } {
                // this is the ID of the layer, eg, 1, 5, 253
                let layerId := byte(i, _packedBytes)
                if iszero(layerId) {
                    break
                }
                // layerIds are 1-indexed because we're shifting 1 by the value of the byte
                unpacked := or(unpacked, shl(layerId, 1))
            }
        }
    }

    // note: this was accidentally marked public, which was causing panics in foundry debugger?
    function packBytearray(uint8[] memory bytearray)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 bytearrayLength = bytearray.length;
        uint256[] memory packed = new uint256[]((bytearrayLength - 1) / 32 + 1);
        uint256 workingWord = 0;
        for (uint256 i = 0; i < bytearrayLength; ) {
            // OR workingWord with this byte shifted by byte within the word
            workingWord |= uint256(bytearray[i]) << (8 * (31 - (i % 32)));

            // if we're on the last byte of the word, store in array
            if (i % 32 == 31) {
                uint256 j = i / 32;
                packed[j] = workingWord;
                workingWord = 0;
            }
            unchecked {
                ++i;
            }
        }
        if (bytearrayLength % 32 != 0) {
            packed[packed.length - 1] = workingWord;
        }

        return packed;
    }

    // TODO: test
    function unpackByteArrays(uint256[] memory packedByteArrays)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 packedByteArraysLength = packedByteArrays.length;
        // TODO: is uint8 more efficient in memory?
        uint256[] memory unpacked = new uint256[](packedByteArraysLength * 32);
        for (uint256 i = 0; i < packedByteArraysLength; ) {
            uint256 packedByteArray = packedByteArrays[i];
            uint256 j = 0;
            for (; j < 32; ) {
                uint256 unpackedByte = getPackedByteFromLeft(
                    j,
                    packedByteArray
                );
                if (unpackedByte == 0) {
                    break;
                }
                unpacked[i * 32 + j] = unpackedByte;
                unchecked {
                    ++j;
                }
            }
            if (j < 32) {
                break;
            }
            unchecked {
                ++i;
            }
        }
        return unpacked;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library BitFieldUtility {
    function unpackBitField(uint256 bitField)
        internal
        pure
        returns (uint256[] memory unpacked)
    {
        if (bitField == 0) {
            return new uint256[](0);
        }
        uint256 numLayers = 0;
        uint256 bitFieldTemp = bitField;
        // count the number of 1's in the bit field to get the number of layers
        while (bitFieldTemp != 0) {
            bitFieldTemp = bitFieldTemp & (bitFieldTemp - 1);
            numLayers++;
        }
        // use that number to allocate a memory array
        // todo: look into assigning length of 255 and then modifying in-memory, if gas is ever a concern
        unpacked = new uint256[](numLayers);
        bitFieldTemp = bitField;
        unchecked {
            for (uint256 i = 0; i < numLayers; ++i) {
                bitFieldTemp = bitFieldTemp & (bitFieldTemp - 1);
                unpacked[i] = mostSignificantBit(bitField - bitFieldTemp);
                bitField = bitFieldTemp;
            }
        }
    }

    function uint8sToBitField(uint8[] memory uints)
        internal
        pure
        returns (uint256)
    {
        uint256 bitField;
        uint256 layersLength = uints.length;
        for (uint256 i; i < layersLength; ++i) {
            uint8 bit = uints[i];
            bitField |= (1 << bit);
        }
        return bitField;
    }

    /// from: https://github.com/paulrberg/prb-math/blob/main/contracts/PRBMath.sol
    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {DisplayType} from "./Enums.sol";

struct Attribute {
    string traitType;
    string value;
    DisplayType displayType;
}

struct LayerVariation {
    uint8 layerId;
    uint8 numVariations;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PackedByteUtility} from "./PackedByteUtility.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {json} from "./JSON.sol";
import {ArrayLengthMismatch} from "./Errors.sol";
import {DisplayType} from "./Enums.sol";
import {Attribute} from "./Structs.sol";

contract OnChainTraits is Ownable {
    using Strings for uint256;

    mapping(uint256 => Attribute) public traitAttributes;

    function setAttribute(uint256 traitId, Attribute memory attribute)
        public
        onlyOwner
    {
        traitAttributes[traitId] = attribute;
    }

    function setAttributes(
        uint256[] memory traitIds,
        Attribute[] memory attributes
    ) public onlyOwner {
        if (traitIds.length != attributes.length) {
            revert ArrayLengthMismatch(traitIds.length, attributes.length);
        }
        for (uint256 i; i < traitIds.length; ++i) {
            traitAttributes[traitIds[i]] = attributes[i];
        }
    }

    function displayTypeJson(string memory displayTypeString)
        internal
        pure
        returns (string memory)
    {
        return json.property("display_type", displayTypeString);
    }

    function getTraitJson(uint256 _traitId)
        public
        view
        returns (string memory)
    {
        Attribute memory attribute = traitAttributes[_traitId];
        string memory properties = string.concat(
            json.property("trait_type", attribute.traitType),
            ","
        );
        // todo: probably don't need this for layers, but good for generic
        DisplayType displayType = attribute.displayType;
        if (displayType != DisplayType.String) {
            string memory displayTypeString;
            if (displayType == DisplayType.Number) {
                displayTypeString = displayTypeJson("number");
            } else if (attribute.displayType == DisplayType.Date) {
                displayTypeString = displayTypeJson("date");
            } else if (attribute.displayType == DisplayType.BoostPercent) {
                displayTypeString = displayTypeJson("boost_percent");
            } else if (attribute.displayType == DisplayType.BoostNumber) {
                displayTypeString = displayTypeJson("boost_number");
            }
            properties = string.concat(properties, displayTypeString, ",");
        }
        properties = string.concat(
            properties,
            json.property("value", attribute.value)
        );
        return json.object(properties);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import {utils} from "./Utils.sol";

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("g", _props, _children);
    }

    function path(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("path", _props, _children);
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("text", _props, _children);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("line", _props, _children);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("circle", _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("circle", _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("rect", _props, _children);
    }

    function rect(string memory _props) internal pure returns (string memory) {
        return el("rect", _props);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("filter", _props, _children);
    }

    function cdata(string memory _content)
        internal
        pure
        returns (string memory)
    {
        return string.concat("<![CDATA[", _content, "]]>");
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("radialGradient", _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("linearGradient", _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                "stop",
                string.concat(
                    prop("stop-color", stopColor),
                    " ",
                    prop("offset", string.concat(utils.uint2str(offset), "%")),
                    " ",
                    _props
                )
            );
    }

    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("animateTransform", _props);
    }

    function image(string memory _href, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("image", string.concat(prop("href", _href), " ", _props));
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                "<",
                _tag,
                " ",
                _props,
                ">",
                _children,
                "</",
                _tag,
                ">"
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(string memory _tag, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return string.concat("<", _tag, " ", _props, "/>");
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, "=", '"', _val, '" ');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
pragma solidity >=0.8.4;

enum DisplayType {
    String,
    Number,
    Date,
    BoostPercent,
    BoostNumber
}

enum LayerType {
    PORTRAIT,
    BACKGROUND,
    TEXTURE,
    OBJECT,
    BORDER
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = "";

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat("--", _key, ":", _val, ";");
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat("var(--", _key, ")");
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat("url(#", _id, ")");
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
            ? string.concat("0.", utils.uint2str(_a))
            : "1";
        return
            string.concat(
                "rgba(",
                utils.uint2str(_r),
                ",",
                utils.uint2str(_g),
                ",",
                utils.uint2str(_b),
                ",",
                formattedA,
                ")"
            );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}