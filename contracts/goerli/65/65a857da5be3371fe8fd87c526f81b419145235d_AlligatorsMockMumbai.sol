// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// ______     __         __         __     ______     ______     ______   ______     ______     ______    
// /\  __ \   /\ \       /\ \       /\ \   /\  ___\   /\  __ \   /\__  _\ /\  __ \   /\  == \   /\  ___\   
// \ \  __ \  \ \ \____  \ \ \____  \ \ \  \ \ \__ \  \ \  __ \  \/_/\ \/ \ \ \/\ \  \ \  __<   \ \___  \  
//  \ \_\ \_\  \ \_____\  \ \_____\  \ \_\  \ \_____\  \ \_\ \_\    \ \_\  \ \_____\  \ \_\ \_\  \/\_____\ 
//   \/_/\/_/   \/_____/   \/_____/   \/_/   \/_____/   \/_/\/_/     \/_/   \/_____/   \/_/ /_/   \/_____/ 

import './IAlligators.sol';
import './extension/Royalty.sol';
import './extension/Ownable.sol';
import './extension/ERC165.sol';
import './interfaces/IERC721Receiver.sol';
import './chainlink/VRFConsumerBaseV2.sol';
import './chainlink/VRFCoordinatorV2Interface.sol';
import './utils/Strings.sol';
import './utils/Counters.sol';
import './utils/Address.sol';

contract Alligators is
    IAlligators,
    ERC165,
    Ownable,
    Royalty,
    VRFConsumerBaseV2 {

    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private MergeIds;
    Counters.Counter private AlligatorIds;
    Counters.Counter private JokerIds;
    Counters.Counter private WLCounter;

    //COLLECTION SIZES
    uint constant ALLIGATORS_LIMIT = 10000;
    uint constant JOKER_LIMIT = 1000;
    
    address public mergeGator;
    //LIMITS
    uint public perPublic = 6;
    uint public perWhitelisted = 33;
    uint public perPublicTransaction = 3;
    uint public perWhitelistTransaction = 9;
    uint public whitelistLimit = 999;


    // =============================================================
    //                            STORAGE
    // =============================================================

    uint256 internal _currentIndex;
    uint256 internal _burnCounter;

    uint256 public mintPay = 0;

    string private _name;
    string private _symbol;
    string private _baseMetaDataURL;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;
    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    // 0 for off - 1 for on
    mapping(address => uint) public isWhitelisted;
    mapping(address => uint) private _whitelistMintedCount;
    mapping(address => uint) private _publicMintedCount;
    mapping(uint256 => RequestStatus) private vrf_requests; /* requestId --> requestStatus */
    mapping(uint256 => uint8) private tokenIdType;
    mapping(uint256 => NFTAnatomy) internal _anatomy;
    mapping(uint256 => NFTLevel) internal _lvl;
    mapping(uint256 => uint8) private jokerLvl;
    mapping(uint256 => string) private _tokenURIs;

    // ========================== VRF ===================================

    VRFCoordinatorV2Interface private immutable vrfCoordinatorG;
    uint64 private immutable subscriptionId;
    uint32 private immutable callbackGasLimit = 2_000_000;
    uint32 private constant NUM_WORDS = 20;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    bytes32 private immutable gasLane;
    uint256 internal constant MAX_CHANCE_VALUE = 10000;
    uint256 internal MIN_CHANCE_VALUE = 8888;

    SaleStatus public saleStatus = SaleStatus.PRESALE;

    modifier onlyMerger() {
        if (msg.sender != mergeGator) {
            revert("Not authorized");
        }
        _;
    }

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    
    constructor(
        string memory name_,
        string memory symbol_,
        uint64 subscriptionId_,
        address vrfCoordinatorV2_,
        bytes32 gasLane_,
        address payable royaltyRecipient_,
        uint256 royaltyBPS_
    )VRFConsumerBaseV2(vrfCoordinatorV2_)
    {
        _name = name_;
        _symbol = symbol_;

        _currentIndex = _startTokenId();

        _setupOwner(msg.sender);
        _setupDefaultRoyaltyInfo(royaltyRecipient_, royaltyBPS_);

        subscriptionId = subscriptionId_;
        vrfCoordinatorG = VRFCoordinatorV2Interface(vrfCoordinatorV2_);
        gasLane = gasLane_;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external {}

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

   /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
     function totalSupply() public view override returns (uint256) {
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

    // =============================================================
    //                            IERC165
    // =============================================================

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner_) public view override returns (uint256) {
        if (owner_ == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner_].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner_) internal view returns (uint256) {
        return uint256(_addressData[owner_].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner_) internal view returns (uint256) {
        return uint256(_addressData[owner_].numberBurned);
    }

    // =============================================================
    //                      OWNERSHIP OPERATIONS
    // =============================================================

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
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
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
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
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        if (!_exists(tokenId)) revert callErr();
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual returns (string memory) {
        // Our servers URL
        return "https://www.our.server/";
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev See {IERC721-approve}.
     */
     function approve(address to, uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId);
        if (to == owner_) revert ApprovalToCurrentOwner();

        if (_msgSenderIn() != owner_)
            if (!isApprovedForAll(owner_, _msgSenderIn())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _approve(to, tokenId, owner_);
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
        if (operator == _msgSenderIn()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderIn()][operator] = approved;
        emit ApprovalForAll(_msgSenderIn(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner_, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner_][operator];
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
        if (to.isContract())
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
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
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

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection.
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
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSenderIn() == from ||
            isApprovedForAll(from, _msgSenderIn()) ||
            getApproved(tokenId) == _msgSenderIn());

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

    // /**
    //  * @dev Equivalent to `_burn(tokenId, true)`.
    //  */
    // function _burn(uint256 tokenId) internal virtual {
    //     _burn(tokenId, true);
    // }

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
            bool isApprovedOrOwner = (_msgSenderIn() == from ||
                isApprovedForAll(from, _msgSenderIn()) ||
                _msgSenderIn() == mergeGator);

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
        address owner_
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSenderIn(), from, tokenId, data) returns (bytes4 retval) {
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
    ) internal virtual {
        if (saleStatus == SaleStatus.PAUSED) revert callErr();
    }

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


    function _msgSenderIn() internal view virtual returns (address) {
        return msg.sender;
    }

    // =============================================================
    //                          Public
    // =============================================================

    function publicMint(uint256 _quantity) public payable {
        require(msg.value >= mintPay, "unfulfilled pay");
        if (saleStatus == SaleStatus.PAUSED) revert callErr();
        if (saleStatus == SaleStatus.PRESALE) revert callErr();
        uint mintedTillNow = _publicMintedCount[msg.sender];
        if (_quantity > perPublicTransaction) revert callErr();
        if (mintedTillNow + _quantity > perPublic) revert callErr();
        _publicMintedCount[msg.sender] = _quantity + mintedTillNow;
        if (mintPay > 0) {
            payable(address(this)).transfer(msg.value);
        }
        VRFMint(msg.sender, _quantity);
    }

    function whitelistMint(uint256 _quantity) public {  
        if (saleStatus == SaleStatus.PAUSED) revert callErr();
        if (WLCounter.current() >= whitelistLimit) revert callErr();
        if (_quantity > perWhitelistTransaction) revert callErr();
        require(isWhitelisted[msg.sender] == 1, "Invalid signer" );
        uint mintedTillNow = _whitelistMintedCount[msg.sender];
        if (mintedTillNow + _quantity > perWhitelisted) revert callErr();

        _whitelistMintedCount[msg.sender] = _quantity + mintedTillNow;
        WLCounter.increment(_quantity);
        VRFMint(msg.sender, _quantity);
    }

    /*
        <<By MergeGators>>
    */

    
    function merge3alligators(uint256 _1st, uint256 _2nd, uint256 _3rd, address owner_) external onlyMerger() {
        require(tokenIdType[_1st] == 1 && tokenIdType[_2nd] == 1 && tokenIdType[_3rd] == 1, "typeCheckFailed");
        require(ownerOf(_1st) == owner_ && ownerOf(_2nd) == owner_ && ownerOf(_3rd) == owner_, "ownershipFailed");
        (uint8[] memory pullData, bool state) = _decide(_1st, _2nd, _3rd);
        require(state, "decideFailed");
        uint8[] memory pullDataTraits = _compareTrait(_1st, _2nd, _3rd);
        _anatomy[_currentIndex] = NFTAnatomy(
            {
                trait1: Trait1(pullDataTraits[0]), 
                trait2: Trait2(pullDataTraits[1]), 
                trait3: Trait3(pullDataTraits[2]), 
                trait4: Trait4(pullDataTraits[3]), 
                trait5: Trait5(pullDataTraits[4]), 
                trait6: Trait6(pullDataTraits[5]), 
                trait7: Trait7(pullDataTraits[6])
            });
        _lvl[_currentIndex] = NFTLevel(
            {
                trait1Lvl: pullData[0],
                trait2Lvl: pullData[1],
                trait3Lvl: pullData[2],
                trait4Lvl: pullData[3],
                trait5Lvl: pullData[4],
                trait6Lvl: pullData[5],
                trait7Lvl: pullData[6]
            });
        tokenIdType[_currentIndex] = 1;
        MergeIds.increment(1);
        _mint(owner_, 1);
        _setTokenURI(_currentIndex-1, Strings.toString(_currentIndex-1));
        _burn(_1st, true);
        _burn(_2nd, true);
        _burn(_3rd, true);
    }

    function mergeWjoker(uint256 _1st, uint256 _2nd, uint256 _3rd, address owner_) external onlyMerger() {
        require(tokenIdType[_1st] == 2 && tokenIdType[_2nd] == 1 && tokenIdType[_3rd] == 1, "typeCheckFailed");
        require(ownerOf(_1st) == owner_ && ownerOf(_2nd) == owner_ && ownerOf(_3rd) == owner_, "ownershipFailed");
        (uint8[] memory pullData, bool state) = _decideWjoker(_1st, _2nd, _3rd);
        require(state, "decideFailed");
        uint8[] memory pullDataTraits = _compareTraitJoker(_2nd, _3rd);
        //createMerged(pullDataTraits,pullData);
        _anatomy[_currentIndex] = NFTAnatomy(
            {
                trait1: Trait1(pullDataTraits[0]), 
                trait2: Trait2(pullDataTraits[1]), 
                trait3: Trait3(pullDataTraits[2]), 
                trait4: Trait4(pullDataTraits[3]), 
                trait5: Trait5(pullDataTraits[4]), 
                trait6: Trait6(pullDataTraits[5]), 
                trait7: Trait7(pullDataTraits[6])
            });
        _lvl[_currentIndex] = NFTLevel(
            {
                trait1Lvl: pullData[0],
                trait2Lvl: pullData[1],
                trait3Lvl: pullData[2],
                trait4Lvl: pullData[3],
                trait5Lvl: pullData[4],
                trait6Lvl: pullData[5],
                trait7Lvl: pullData[6]
            });
        tokenIdType[_currentIndex] = 1;
        MergeIds.increment(1);
        _mint(owner_, 1);
        _setTokenURI(_currentIndex-1, Strings.toString(_currentIndex-1));
        _burn(_2nd, true);
        _burn(_3rd, true);
    }

    /*
        <<PUBLIC GETTERS>>
    */

    function mergeCounter() external view returns (uint256) {
        return MergeIds.current();
    }

    function jokerCounter() external view returns (uint256) {
        return JokerIds.current();
    }

    function alligatorCounter() external view returns (uint256) {
        return AlligatorIds.current();
    }

    function numberAddrBurned(address target_) external view returns (uint256) {
        return _numberBurned(target_);
    }

    function totalMintedCounter() external view returns (uint256) {
        return _totalMinted();
    }


    function alligatorsTotalSupply() public view virtual returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return AlligatorIds.current() - _burnCounter;
        }
    }

    function traitTypes(uint256 _tokenId) public view returns (uint8[7] memory _traits) {
        return anatomy(_tokenId);
    }

    function jokerLevel(uint256 _tokenId) public view returns (uint8 lvl_) {
        return joker_level(_tokenId);
    }
    function traitLevels(uint256 _tokenId) public view returns (uint8[7] memory _traits) {
        return alligator_level(_tokenId);
    }

    function nftType(uint256 _tokenId) public view returns (uint8 type_) {
        return tokenType(_tokenId);
    }
    
    function chanceArray() public view returns (uint256[2] memory) {
        return [MIN_CHANCE_VALUE, MAX_CHANCE_VALUE];
    }
    /* OWNER METHODS
    Setters
    */

    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    function setMergeGator(address mergeHub_) external onlyOwner {
        if (mergeHub_ == address(0)) revert callErr();
        mergeGator = mergeHub_;
        emit MergeIsSet(mergeHub_);
    }

    function setWhitelistedLimit(uint size) external onlyOwner {
        if (size > 1200) revert callErr();
        whitelistLimit = size;
        emit MintLimitIsSet(size);
    }

    function setPerWhitelisted(uint size) external onlyOwner {
        if (size > 50) revert callErr();
        perWhitelisted = size;
        emit MintLimitIsSet(size);
    }

    function setPerPublic(uint size) external onlyOwner {
        if (size > 10) revert callErr();
        perPublic = size;
        emit MintLimitIsSet(size);
    }

    function setPerTxWhitelisted(uint size) external onlyOwner {
        if (size > 10) revert callErr();
        perWhitelistTransaction = size;
        emit MintLimitIsSet(size);
    }

    function setPerTxPublic(uint size) external onlyOwner {
        if (size > 10) revert callErr();
        perPublicTransaction = size;
        emit MintLimitIsSet(size);
    }

    function setChanceArray(uint256 _min) external onlyOwner {
        if (_min > MAX_CHANCE_VALUE) revert callErr();
        MIN_CHANCE_VALUE = _min;
        emit ChanceIsSet(_min);
    }

    function addWLAddress(address[] memory _whitelisted) external onlyOwner {
        for (uint index = 0; index < _whitelisted.length; index++) {
            address added = _whitelisted[index];
            isWhitelisted[added] = 1;
        }
    }

    function setBaseURI(string memory _base) external onlyOwner {
        _baseMetaDataURL = _base;
    }

    function setMintPay(uint256 _mintPay) external onlyOwner {
        mintPay = _mintPay;
    }

    function rescueFunds(uint256 _amount, address payable _rescueTo) external onlyOwner {
        if (_rescueTo == address(0)) revert callErr();
        _rescueTo.transfer(_amount);
    }

    /*
        <<INTERNAL>>
    */

    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    function VRFMint(address to, uint256 _quantity) internal returns (uint256 requestId) {
        requestId = vrfCoordinatorG.requestRandomWords(
            gasLane,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );
        vrf_requests[requestId] = RequestStatus(
            {
                randomWords: new uint256[](0),
                jokerMint: 0, jokerMintPrize: 0,
                sender: to, quantity: _quantity
            });
        emit RequestSent(requestId, NUM_WORDS);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        vrf_requests[_requestId].randomWords = _randomWords;
        address publicMinter = vrf_requests[_requestId].sender;
        uint256 perTx = vrf_requests[_requestId].quantity;
        uint256 moddedRng = _randomWords[0] % MAX_CHANCE_VALUE;
        uint256[2] memory chanceArracy = chanceArray();
        if (saleStatus == SaleStatus.PUBLIC || saleStatus == SaleStatus.PRESALE) {
            if (moddedRng < chanceArracy[0]) {
                vrf_requests[_requestId].jokerMint = 0;
                alligatorMint(publicMinter, perTx, _requestId);
            } else {
                vrf_requests[_requestId].jokerMint = 1;
                jokerMint(publicMinter, _requestId);
                if (perTx > 1) {
                    alligatorMint(publicMinter, perTx -1, _requestId);
                }
            }
        }
        if (saleStatus == SaleStatus.COMMON_SUPPLIED) {
            vrf_requests[_requestId].jokerMint = 1;
            jokerMint(publicMinter, _requestId);
        }
        if (saleStatus == SaleStatus.JOKER_SUPPLIED) {
            vrf_requests[_requestId].jokerMint = 0;
            alligatorMint(publicMinter, perTx, _requestId);
        }        
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function alligatorMint(address to,uint256 _quantity, uint256 _requestId) private {
        if (AlligatorIds.current() > ALLIGATORS_LIMIT) revert callErr();
        uint256[] memory _randomWords = vrf_requests[_requestId].randomWords;
            for (uint i = 1; i <= _quantity; i++) {
                uint8 type1 = uint8(_randomWords[1+i] % 3);
                uint8 type2 = uint8(_randomWords[2+i] % 3);
                uint8 type3 = uint8(_randomWords[3+i] % 3);
                uint8 type4 = uint8(_randomWords[4+i] % 3);
                uint8 type5 = uint8(_randomWords[5+i] % 3);
                uint8 type6 = uint8(_randomWords[6+i] % 3);
                uint8 type7 = uint8(_randomWords[7+i] % 3);
                _anatomy[_currentIndex] = NFTAnatomy(
                    {
                        trait1: Trait1(type1), 
                        trait2: Trait2(type2),
                        trait3: Trait3(type3),
                        trait4: Trait4(type4),
                        trait5: Trait5(type5),
                        trait6: Trait6(type6),
                        trait7: Trait7(type7)
                    });
                _lvl[_currentIndex] = NFTLevel(
                    {
                        trait1Lvl: 1,
                        trait2Lvl: 1,
                        trait3Lvl: 1,
                        trait4Lvl: 1,
                        trait5Lvl: 1,
                        trait6Lvl: 1,
                        trait7Lvl: 1
                    });
                // 1 for alligators, 1 for generated from merge and 2 for JOKERs
                tokenIdType[_currentIndex] = 1;
                _mint(to, 1);
                _setTokenURI(_currentIndex - 1, Strings.toString(_currentIndex - 1));
                AlligatorIds.increment(1);
        }
    }

    function jokerMint(address to, uint256 _requestId) private {
        if (JokerIds.current() > JOKER_LIMIT) revert callErr();
        uint256[] memory _randomWords = vrf_requests[_requestId].randomWords;
        // JOKER's level will be randomize from 1 to 4;
        uint8 randomize = uint8(_randomWords[9] % 4);
        if (randomize == 0) {randomize++;}
        jokerLvl[_currentIndex] = randomize;
        // 1 for alligators, 1 for generated from merge and 2 for JOKERs
        tokenIdType[_currentIndex] = 2;
        _mint(to, 1);
        _setTokenURI(_currentIndex - 1, Strings.toString(_currentIndex - 1));
        JokerIds.increment(1);
    }

    function _compareTraitJoker(uint256 _2nd, uint256 _3rd) internal view returns (uint8[] memory data_) {
        uint8[] memory data = new uint8[](7);
        for (uint256 i = 0; i < 7; i++ ) {
            if (alligator_level(_2nd)[i] >= alligator_level(_3rd)[i]) {
                data[i] = anatomy(_2nd)[i];
            } else {
                data[i] = anatomy(_3rd)[i];
            }
        }
        return data;
    }

    function _compareLvlJoker(uint256 _2nd, uint256 _3rd) internal view returns (uint8[] memory data_) {
        uint8[] memory data = new uint8[](7);
        for (uint256 i = 0; i < 7; i++ ) {
            if (alligator_level(_2nd)[i] >= alligator_level(_3rd)[i]) {
                data[i] = alligator_level(_2nd)[i];
            } else {
                data[i] = alligator_level(_3rd)[i];
            }
        }
        return data;
    }
    
    function _compareTrait(uint256 _1st, uint256 _2nd, uint256 _3rd) internal view returns (uint8[] memory data_) {
        uint8[] memory data = new uint8[](7);
        for (uint256 i = 0; i < 7; i++ ) {
            if (alligator_level(_1st)[i] >= alligator_level(_2nd)[i]) {
                if (alligator_level(_1st)[i] >= alligator_level(_3rd)[i]) {
                    // first value is Type index, second one is Level Index
                    data[i] = anatomy(_1st)[i];
                } else {
                    data[i] = anatomy(_3rd)[i];
                }
            } else {
                if (alligator_level(_2nd)[i] >= alligator_level(_3rd)[i]) {
                    data[i] = anatomy(_2nd)[i];
                } else {
                    data[i] = anatomy(_3rd)[i];
                }
            }
        }
        return data;
    }

    function _compareLvl(uint256 _1st, uint256 _2nd, uint256 _3rd) internal view returns (uint8[] memory data_) {
        uint8[] memory data = new uint8[](7);
        for (uint256 i = 0; i < 7; i++ ) {
            if (alligator_level(_1st)[i] >= alligator_level(_2nd)[i]) {
                if (alligator_level(_1st)[i] >= alligator_level(_3rd)[i]) {
                    // first value is Type index, second one is Level Index
                    data[i] = alligator_level(_1st)[i];
                } else {
                    data[i] = alligator_level(_3rd)[i];
                }
            } else {
                if (alligator_level(_2nd)[i] >= alligator_level(_3rd)[i]) {
                    data[i] = alligator_level(_2nd)[i];
                } else {
                    data[i] = alligator_level(_3rd)[i];
                }
            }
        }
        return data;
    }

    function _decide(uint256 _1st, uint256 _2nd, uint256 _3rd) internal returns (uint8[] memory _collapse, bool _state) {
        uint8[] memory pullData = _compareLvl(_1st, _2nd, _3rd);
        bool state_ = false;
        for (uint256 i = 0; i < 7; i++ ) {
            if (anatomy(_1st)[i] == anatomy(_2nd)[i] 
            && anatomy(_1st)[i] == anatomy(_3rd)[i]) {
                if (alligator_level(_1st)[i] == alligator_level(_2nd)[i] 
                && alligator_level(_1st)[i] == alligator_level(_3rd)[i]) {
                    if (alligator_level(_1st)[i] < 5) {
                        pullData[i]++;
                        state_ = true;
                    }
                }
            }
        }
        return (pullData, state_);
    }

    function _decideWjoker(uint256 _1st, uint256 _2nd, uint256 _3rd) internal returns (uint8[] memory _collapse, bool _state) {
        uint8[] memory pullData = _compareLvlJoker(_2nd, _3rd);
        bool state_ = false;
        uint8 lvl_ = jokerLvl[_1st];
        for (uint256 i = 0; i < 7; i++ ) {
            if (lvl_ == alligator_level(_2nd)[i] && lvl_ == alligator_level(_3rd)[i]) {
                if (Alligators.alligator_level(_2nd)[i] < i) {
                    pullData[i]++;
                    state_ = true;
                }
            }
        }
        return (pullData, state_);
    }

    function anatomy(uint256 _tokenId) internal view returns (uint8[7] memory _traits) {
        if (_tokenId >= _currentIndex) revert callErr();
        if (tokenIdType[_tokenId] == 2) revert callErr();
        NFTAnatomy memory skeleton = _anatomy[_tokenId];
        return [uint8(skeleton.trait1), uint8(skeleton.trait2),
             uint8(skeleton.trait3), uint8(skeleton.trait4), uint8(skeleton.trait5), uint8(skeleton.trait6), uint8(skeleton.trait7)];
    }

    function alligator_level(uint256 _tokenId) internal view returns (uint8[7] memory _traits) {
        if (_tokenId >= _currentIndex) revert callErr();
        if (tokenIdType[_tokenId] == 2) revert callErr();
        if (tokenIdType[_tokenId] == 1) {
            NFTLevel memory lvls = _lvl[_tokenId];
            return [uint8(lvls.trait1Lvl), uint8(lvls.trait2Lvl), uint8(lvls.trait3Lvl), uint8(lvls.trait4Lvl), uint8(lvls.trait5Lvl), uint8(lvls.trait6Lvl), uint8(lvls.trait7Lvl)];
        }
    }

    function tokenType(uint256 _tokenId) internal view returns (uint8) {
        if (_tokenId >= _currentIndex) revert callErr();
        uint8 _type = tokenIdType[_tokenId];
        return _type;
    }

    function joker_level(uint256 _tokenId) internal view returns (uint8) {
        if (_tokenId >= _currentIndex) revert callErr();
        if (tokenIdType[_tokenId] != 2) revert callErr();
        uint8 _level = jokerLvl[_tokenId];
        return _level;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Metadata.sol";

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IAlligators is IERC721, IERC721Metadata {

    event Received(address, uint);

    function merge3alligators(uint256 _1st, uint256 _2nd, uint256 _3rd, address merger) external;

    function mergeWjoker(uint256 _1st, uint256 _2nd, uint256 _3rd, address merger) external;

    enum LvlUp {
        TRUE,
        FALSE
    }

    enum Trait1 {
        X1,
        Y1,
        Z1
    }

    enum Trait2 {
        X2,
        Y2,
        Z2
    }

    enum Trait3 {
        X3,
        Y3,
        Z3
    }

    enum Trait4 {
        X4,
        Y4,
        Z4
    }

    enum Trait5 {
        X5,
        Y5,
        Z5
    }

    enum Trait6 {
        X6,
        Y6,
        Z6
    }

    enum Trait7 {
        X7,
        Y7,
        Z7
    }

    enum SaleStatus {
        PAUSED,
        PRESALE,
        PUBLIC,
        JOKER_SUPPLIED,
        COMMON_SUPPLIED,
        ALL_SUPPLIED
    }

   struct NFTAnatomy {
        Trait1 trait1;
        Trait2 trait2;
        Trait3 trait3;
        Trait4 trait4;
        Trait5 trait5;
        Trait6 trait6;
        Trait7 trait7;
    }

    struct NFTLevel {
        uint8 trait1Lvl;
        uint8 trait2Lvl;
        uint8 trait3Lvl;
        uint8 trait4Lvl;
        uint8 trait5Lvl;
        uint8 trait6Lvl;
        uint8 trait7Lvl;
    }

    struct RequestStatus {
        uint256[] randomWords;
        // 0 for off || 1 for on
        uint jokerMint;
        // 0 for off || 1 for on
        uint jokerMintPrize;
        address sender;
        uint256 quantity;
    }

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

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    //function merge(uint256 _1st, uint256 _2nd, uint256 _3rd, address _ownenr) external onlyMerger;
    
    event NftRequested(uint256 indexed requestId, address requester);
    event NftFullfilled(uint256 indexed requestId, address requester, uint256[] randomWords,  bool jokerMint,bool jokerMintPrize, uint256 quantity);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event Verified(address indexed user);
    event MergeIsSet(address mergeHub);
    event ChanceIsSet(uint256 value);
    event MintLimitIsSet(uint value);
    event WLAddrIsSet(address[] _whitelisted);
    error InvalidSigner();
    error RangeOutOfBounds();
    error callErr();
    error Mergefailed();
    error invalidSigner();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.17;

import "../interfaces/IERC165.sol";

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "../interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "../interfaces/IRoyalty.sol";


// The `Royalty` contract is ERC2981 compliant.

abstract contract Royalty is IRoyalty {
    /// @dev The (default) address that receives all royalty value.
    address private royaltyRecipient;

    /// @dev The (default) % of a sale to take as royalty (in basis points).
    uint16 private royaltyBps;

    /// @dev Token ID => royalty recipient and bps for token
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    /**
     *  @notice   View royalty info for a given token and sale price.
     *  @dev      Returns royalty amount and recipient for `tokenId` and `salePrice`.
     *  @param tokenId          The tokenID of the NFT for which to query royalty info.
     *  @param salePrice        Sale price of the token.
     *
     *  @return receiver        Address of royalty recipient account.
     *  @return royaltyAmount   Royalty amount calculated at current royaltyBps value.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / 10_000;
    }

    /**
     *  @notice          View royalty info for a given token.
     *  @dev             Returns royalty recipient and bps for `_tokenId`.
     *  @param _tokenId  The tokenID of the NFT for which to query royalty info.
     */
    function getRoyaltyInfoForToken(uint256 _tokenId) public view override returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /**
     *  @notice Returns the defualt royalty recipient and BPS for this contract's NFTs.
     */
    function getDefaultRoyaltyInfo() external view override returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /**
     *  @notice         Updates default royalty recipient and bps.
     *  @dev            Caller should be authorized to set royalty info.
     *                  See {_canSetRoyaltyInfo}.
     *                  Emits {DefaultRoyalty Event}; See {_setupDefaultRoyaltyInfo}.
     *
     *  @param _royaltyRecipient   Address to be set as default royalty recipient.
     *  @param _royaltyBps         Updated royalty bps.
     */
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external override {
        if (!_canSetRoyaltyInfo()) {
            revert("Not authorized");
        }

        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function _setupDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) internal {
        if (_royaltyBps > 10_000) {
            revert("Exceeds max bps");
        }

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint16(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /**
     *  @notice         Updates default royalty recipient and bps for a particular token.
     *  @dev            Sets royalty info for `_tokenId`. Caller should be authorized to set royalty info.
     *                  See {_canSetRoyaltyInfo}.
     *                  Emits {RoyaltyForToken Event}; See {_setupRoyaltyInfoForToken}.
     *
     *  @param _recipient   Address to be set as royalty recipient for given token Id.
     *  @param _bps         Updated royalty bps for the token Id.
     */
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external override {
        if (!_canSetRoyaltyInfo()) {
            revert("Not authorized");
        }

        _setupRoyaltyInfoForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function _setupRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) internal {
        if (_bps > 10_000) {
            revert("Exceeds max bps");
        }

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({ recipient: _recipient, bps: _bps });

        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.17;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
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
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.17;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.17;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
/* is ERC721 */
interface IERC721Metadata {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.17;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "./IERC2981.sol";

interface IRoyalty is IERC2981 {
    struct RoyaltyInfo {
        address recipient;
        uint256 bps;
    }

    /// @dev Returns the royalty recipient and fee bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 tokenId,
        address recipient,
        uint256 bps
    ) external;

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 tokenId) external view returns (address, uint16);

    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);

    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address indexed royaltyRecipient, uint256 royaltyBps);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
pragma solidity ^0.8.17;
library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.17;

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
    function increment(Counter storage counter, uint256 _quantity) internal {
        unchecked {
            counter._value += _quantity;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.17;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
    // function toHexString(uint256 value) internal pure returns (string memory) {
    //     if (value == 0) {
    //         return "0x00";
    //     }
    //     uint256 temp = value;
    //     uint256 length = 0;
    //     while (temp != 0) {
    //         length++;
    //         temp >>= 8;
    //     }
    //     return toHexString(value, length);
    // }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    // function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    //     bytes memory buffer = new bytes(2 * length + 2);
    //     buffer[0] = "0";
    //     buffer[1] = "x";
    //     for (uint256 i = 2 * length + 1; i > 1; --i) {
    //         buffer[i] = _HEX_SYMBOLS[value & 0xf];
    //         value >>= 4;
    //     }
    //     require(value == 0, "Strings: hex length insufficient");
    //     return string(buffer);
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../src/Alligators.sol";

contract AlligatorsMockMumbai is Alligators {

    string constant collection_ = "Alligators";
    string constant symbol_ = "AGT";
    address payable constant royaltyRecipient = payable(0x4100b92dDbA84A467ab08A821F154997193E1D7B);
    uint256 constant royaltyBps_ = 10;

    constructor(
        uint64 subscriptionId,
        address vrfCoordinatorV2,
        bytes32 gasLane
        )
        Alligators(collection_,
                    symbol_,
                    subscriptionId,
                    vrfCoordinatorV2,
                    gasLane,
                    royaltyRecipient,
                    royaltyBps_)
    {}

}