/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;
            

/*

    Required functions for iNFToken implementation

        function totalSupply() public view override returns(uint tkn, uint nftkn) { }
        function balanceOf(address _owner) public view override returns(uint tkn, uint nftkn) { }
        function transferFrom(address from, address to, uint256 tokenId) public override returns(bool tkn) { }
        function transfer(address _to, uint256 _value) public override returns (bool success) { }
        function isProtectedNFToken(uint tokenId) public view override returns(bool is_protected) { }
        function ERCtransferFrom(address _from, address _to, uint256 _value) public override onlyContract returns (bool success) { }
        function ERCbalanceOf(address _owner) public override view returns (uint256 balance) { }
        function allowance(address _owner, address _spender) public override view returns (uint256 remaining) { }
        function ERCapprove(address _spender, uint256 _value) public override returns (bool success) { }
        function decimals() public pure override returns (uint) { }
    

*/


/* ********************+******** 

ERC721E Definition

****************************** */

/**
 * @dev Interface of an ERC721E compliant contract.
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
    function NFTtotalSupply() external view returns (uint256);

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
    event NftTransfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event NftApproval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the list of transferred tokens in a transfer
     */
    event TransferredNFTs(address indexed origin, address indexed destination, uint[] tokens);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function NFTbalanceOf(address owner) external view returns (uint256 balance);

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
    function NFTtransferFrom(
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
    function NFTapprove(address to, uint256 tokenId) external;

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
    function NFTname() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function NFTsymbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}



/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721E__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721E {

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
contract ERC721E is IERC721A, IERC721E {

    string public baseURI;
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

    // TODO CHECK array of ownerships
    mapping(address => uint[]) public owned;

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
    function NFTtotalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() public view returns (uint256) {
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
    function NFTbalanceOf(address owner) public view override returns (uint256) {
        if (_addressToUint256(owner) == 0) revert BalanceQueryForZeroAddress();
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
        assembly { // Cast aux without masking.
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) internal view returns (uint256) {
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
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function NFTname() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function NFTsymbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".png")) : '';
    }


    /**
     * @dev Casts the address to uint256 without masking.
     */
    function _addressToUint256(address value) private pure returns (uint256 result) {
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
    function NFTapprove(address to, uint256 tokenId) public override {
        address owner = ownerOf((tokenId));
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSenderERC721E() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721E())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit NftApproval(owner, to, tokenId);
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
        if (operator == _msgSenderERC721E()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721E()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721E(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    modifier onlyContract() {
      require(msg.sender==address(this));
      _;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function NFTtransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyContract {
        _NFT_transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual onlyContract override {
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
    ) public virtual onlyContract override {
        _NFT_transfer(from, to, tokenId);
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
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

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
                    emit NftTransfer(address(0), to, updatedIndex);

                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit NftTransfer(address(0), to, updatedIndex++);
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
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

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
                // TODO CHECK adding to the actor array
                owned[to].push(updatedIndex);

                emit NftTransfer(address(0), to, updatedIndex++);
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
    function _NFT_transfer(
         address from,
        address to,
        uint256 tokenId
        ) internal {
        
            address Dead = 0x000000000000000000000000000000000000dEaD;
            if(!(from==Dead)) {
                _packedAddressData[to] -= 1 * ((1 << BITPOS_NUMBER_MINTED) | 1);
            }

            _packedAddressData[to] += 1 * ((1 << BITPOS_NUMBER_MINTED) | 1);

            uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
            if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

            address approvedAddress = _tokenApprovals[tokenId];

            bool isApprovedOrOwner = (_msgSenderERC721E() == from ||
                isApprovedForAll(from, _msgSenderERC721E()) ||
                approvedAddress == _msgSenderERC721E());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
            if (_addressToUint256(to) == 0) revert TransferToZeroAddress();


            // Clear approvals from the previous owner.
            if (_addressToUint256(approvedAddress) != 0) {
                delete _tokenApprovals[tokenId];
            }

            // Underflow of the sender's balance is impossible because we check for
            // ownership above and the recipient's balance can't realistically overflow.
            // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
            unchecked {
                // We can directly increment and decrement the _balances.
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

        emit NftTransfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Transfers N tokens from `from` to `to`.
     *
     * Emits N {Transfer} event.
     */
    function _NFT_derive_transfer(
        address from,
        address to,
        uint256 amount
        ) internal {
        
            address Dead = 0x000000000000000000000000000000000000dEaD;
            if(!(from==Dead)) {
                _packedAddressData[to] -= amount * ((1 << BITPOS_NUMBER_MINTED) | 1); //1 * ((1 << BITPOS_NUMBER_MINTED) | 1);
            }

            _packedAddressData[to] += amount * ((1 << BITPOS_NUMBER_MINTED) | 1);// 1 * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // TODO CHECK deriving owned array and iterating

            // Deriving owned from array
            uint[] memory _owned = new uint[](owned[from].length);

            // Preparing the editable array for sender
            uint[] memory _new_sender_owned = _owned;
            // And for receiver
            uint old_receiver_length = owned[to].length;

            // Deriving receiver owned array
            uint[] memory _new_receiver_owned = new uint[]( old_receiver_length + amount);

            // Checking safety
            require(_owned.length >= amount, "Not enough tokens");

            uint256 prevOwnershipPacked;

            // Preparing step
            uint step = 0;

            for(uint i = _owned.length; i > (_owned.length-amount); i--) {

                // Increasing step to expand the receiver array
                step += 1;

                prevOwnershipPacked = _packedOwnershipOf(_owned[i]);
                if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

                address approvedAddress = _tokenApprovals[_owned[i]];

                bool isApprovedOrOwner = (_msgSenderERC721E() == from ||
                    isApprovedForAll(from, _msgSenderERC721E()) ||
                    approvedAddress == _msgSenderERC721E());

                if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
                if (_addressToUint256(to) == 0) revert TransferToZeroAddress();


                // Clear approvals from the previous owner.
                if (_addressToUint256(approvedAddress) != 0) {
                    delete _tokenApprovals[_owned[i]];
                }

                // Updates:
                // - `address` to the next owner.
                // - `startTimestamp` to the timestamp of transfering.
                // - `burned` to `false`.
                // - `nextInitialized` to `true`.
                _packedOwnerships[_owned[i]] =
                    _addressToUint256(to) |
                    (block.timestamp << BITPOS_START_TIMESTAMP) |
                    BITMASK_NEXT_INITIALIZED;

                // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
                if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                    uint256 nextTokenId = _owned[i] + 1;
                    // If the next slot's address is zero and not burned (i.e. packed value is zero).
                    if (_packedOwnerships[nextTokenId] == 0) {
                        // If the next slot is within bounds.
                        if (nextTokenId != _currentIndex) {
                            // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                            _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                        }
                    }
                }

                delete _new_sender_owned[i];
                _new_receiver_owned[old_receiver_length + step] = _owned[i]; // Expanding the receiver array

                emit NftTransfer(from, to, _owned[i]);
                _afterTokenTransfers(from, to, _owned[i], 1);

            }

            // Updating storage arrays 
            owned[from] = _new_sender_owned;
            owned[to] = _new_receiver_owned;

            // TODO END CHECK

            // Underflow of the sender's balance is impossible because we check for
            // ownership above and the recipient's balance can't realistically overflow.
            // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
            unchecked {
                // We can directly increment and decrement the _balances.
                _packedAddressData[from] -= amount; // Updates: `balance -= 1`.
                _packedAddressData[to] += amount; // Updates: `balance += 1`.
            }

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
            bool isApprovedOrOwner = (_msgSenderERC721E() == from ||
                isApprovedForAll(from, _msgSenderERC721E()) ||
                approvedAddress == _msgSenderERC721E());

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

        emit NftTransfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    function _checkOwnedArrayOf(address actor) public view returns(uint[] memory _owned_) {
        return owned[actor];
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
        try ERC721E__IERC721Receiver(to).onERC721Received(_msgSenderERC721E(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721E__IERC721Receiver(to).onERC721Received.selector;
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
    function _msgSenderERC721E() internal view virtual returns (address) {
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
            } { // Body of the for loop.
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



/* ********************+******** 

Uniswap Interfaces

****************************** */


interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function addLiquidity(
      address tokenA,
      address tokenB,
      uint amountADesired,
      uint amountBDesired,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);
  
  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

/* ********************+******** 

ERC20 Definitions

****************************** */


interface ERC20 {

    function decimals() external view returns (uint);
    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function ERCbalanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value)  external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function ERCtransferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function ERCapprove(address _spender  , uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/* ********************+******** 

Safety extension

****************************** */

contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

/* ********************+******** 

iNFToken Definition

****************************** */


/// @dev Including functions having the same name in both interfaces to remain compliant while not
/// having confusion and shadow them

abstract contract iNFToken is ERC20, ERC721E, protected {
    function totalSupply() external virtual view returns(uint, uint){}
    function balanceOf(address _owner) external virtual view returns(uint, uint) {}
    function transferFrom(
        address from,
        address to,
        uint256 tokenId) public virtual returns(bool) {}
}

library ArrayDegas {
    function remove(uint16[] memory array, uint index) internal pure  returns(uint16[] memory _array, uint length) {
        // Copy the last element into the index spot to clean
        array[index] = array[array.length - 1];
        // Delete the last element as is unused
        delete array[array.length - 1];
        return(array, array.length);
    }
}


/* CUT HERE - You can cut the above part to use your own implementation
   including it in a file like iNFToken.sol if you are that kind of dev */


/** 
 *  SourceUnit: /Users/tcsenpai/Dropbox/Coding/blockchain-related/Fluid/liquidProtocol/LiquidToken.sol
*/


/*
                                                               
                                  .+...../////////////,.......                                      
                            .....+//////////////////////////////,....,                              
                        ...,/////////// //  /#/////  (//    //////////...                           
                    ,..////////  (//   ,//  #(//// #( //    (/  /(/  ,///+..                        
                  ../////   /// /  // (( /(  #///((//# / ////% ////  /////...                       
                ..//// , / ( #/ (////////   ////  //   %// (//////    ////+..                       
                ..///// &/ (/////% /// #./ %///(.( / / ,/ / /% /  /(///////...                      
               ...////////(#/+ ( /+/// /(,//////////////%// / //  % ///////./..                     
               .../////// /& (( ////+......,++////////+,.......//( ////////.//..                    
               .,./////////  //....//////////////////////////////....//////.+/...,                  
              ../.,////////...///////,........................,///////...//+.//.....+               
              +.//.////,..//////....................................//////...//..#,.....            
              ..//./.../////............................................/////..+.      ,..          
       ....(  ..//..,////..................................................////..........%..        
    ..,   .../..+.+///,...............         +/  #..+......................,/........... ..       
   .. ...........///,............,(/,     /+   .+(,            ...........................  ..      
   ., .....+ .................                                     .....................     .      
  (.. ..    .......,.......  #.         .  .  %    ..+.........  #   +................./     .      
   ..      +......+.......     .........................................................    #.,     
   ...   ................   .............../ + ........................................,    ..      
   ,../  .....   ........ , ....... ..#..       .....,....++.,.......................,    ,..       
    ,../  .....  ........  . .,      ,.+    /.......      ..(//  /+ .,................,,..(         
      ..(    ,# #........    ,         ( %       ...,#.          . /.+.+...............             
       ...      ........./             . ,     +      .+  .+(...+    .................              
          ................        +.. //     .           ...+#..  .++...............+               
             ,,...........(    .,#..//   #..        ..     ............+.......+.,..                
                .......,....    ./ .(    (...,++,....,    . +..........,,......, ...                
                  ......(..       ..            ...,  , (#    ...........#.....,...                 
                  +......#.,.  .                                #............,.....                 
                   ,......,......                                ........,........                  
                    +.......,...                                  ................                  
                     +..........                                 .,..............                   
                       .........    ,,           +(,.........(    ..............                    
                       ..........+       +.........,(.           . ..........,+                     
                       (........,.                               +,.........                        
                          ........                           +, .........+                          
                           .......                           ...........,                           
                              .......   #          ., %../...........+                              
                                 ,....(.. , .   +  +,. ..(,......+                                  
                                     ,..../  +. /............,..                                    
                                           (.............


                                     
                                      S e e   N o   E v i l 

*/


/* ********************+******** 

Actual Implementation

****************************** */



contract LiquidToken is iNFToken {
                              
    /// @dev Library using fast array manipulation methods for unsorted arrays
    using ArrayDegas for uint16[];

    bool SetRarityAtMint = false;
    uint MaxNftMintable;

   constructor(string memory _name_, string memory _symbol,  uint max__) 
    ERC721E(NFTName, NFTicker) {  
        owner = msg.sender;
        MaxNftMintable = max__;
        is_auth[owner] == true;
        router = IUniswapV2Router02(router_address);
        factory_address  = router.factory();
        factory = IUniswapV2Factory(factory_address);
        ERC_Liquidity_Address = factory.createPair(address(this), router.WETH());
        pair = IUniswapV2Pair(ERC_Liquidity_Address);
        
        name = _name_;
        symbol = _symbol;
        
        NFTName = name;
        NFTicker = symbol;
        mint(1);
        _setBaseURI("https://tcsenpai.mypinata.cloud/ipfs/Qmd6UvKHVjphJdj6JvgFdgt6nEQfAxwvk2kRMZiZf3Rwnh/");
    }

  

  /* ==================================================================================================== */
  /* ==================================================================================================== */
  /* ========================================= Mixed Functions ========================================== */
  /* ==================================================================================================== */
  /* ==================================================================================================== */


    /*
    This first part defines the functions having the same name in both the standards
    so to avoid shadowing and to execute necessary functions together in any case.
    Also contains functions that applies to both the ERC20 and the ERC721 token sides.
    */

    function totalSupply() public view override returns(uint tkn, uint nftkn){
        uint _tkn = ERCtotalSupply;
        uint _nftkn = NFTtotalSupply();

        return(_tkn, _nftkn);
    }

    function balanceOf(address _owner) public view override returns(uint tkn, uint nftkn) {
        uint _tkn = ERCbalanceOf(_owner);
        uint _nftkn = NFTbalanceOf(_owner);
        return(_tkn, _nftkn);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId) public override returns(bool tkn) {

            bool success = ERCtransferFrom(from, to, 1);
            NFTtransferFrom(from, to, tokenId);
            return(success);
    }


    function owner_of_nft(uint id) public view returns (address ownerOfTokenId) {
        return address(uint160(_packedOwnershipOf(id)));
    }

    function transfer(address _to, uint256 _value) public override safe returns (bool success) {
      // Standard ERC transfer
      bool _success = ERC_transfer(_to, _value);
      require(_success, "transfer failed");
       
      // TODO CHECK Transfer a corresponding number of NFTs
      _NFT_derive_transfer(msg.sender, _to, _value);

      return _success;
    }

    /* Admin Functions */


    /// @dev Native token paired price for target
    function getTokenPrice(uint amount) public view returns(uint)
    {
            
                (uint Res0, uint Res1,uint timestamp) = pair.getReserves();
                if(Res0==0 && Res1==0) {
                  return 0;
                }
                uint res0 = Res0;
                delete timestamp;
                return((amount*res0)/Res1); // return amount of token0 needed to buy token1
    }

    uint coinPrice;


  /* ==================================================================================================== */
  /* ==================================================================================================== */
  /* ============================================ ERC20 Part ============================================ */
  /* ==================================================================================================== */
  /* ==================================================================================================== */

    /*
    This part defines all the ERC20 standard properties
    */

  address Dead = 0x000000000000000000000000000000000000dEaD;

  uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public ERCtotalSupply;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name; // "The Altairian Dollar";                   //fancy name: eg Simon Bucks
    string public symbol; // "$AD";                 //An identifier: eg SBX

    string public NFTName;
    string public NFTicker;

    address router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 router;
    address factory_address;
    IUniswapV2Factory factory;
    address ERC_Liquidity_Address;
    IUniswapV2Pair pair;

    function ERC_transfer(address _to, uint256 _value) internal returns (bool success) {
        require(_balances[msg.sender] >= _value, "token balance is lower than the value requested");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    /// @dev Internal minting to allow NFT and ERC20 sync
    function mintToken(address _to, uint256 _value) internal {
      _balances[_to] += _value;
      ERCtotalSupply += _value;
      emit Transfer(Dead, _to, _value);
    }

    /// @dev Internal burning to allow NFT and ERC20 sync
   function burnToken(address _from, uint256 _value) internal {
      require((_balances[_from] >= _value) && (ERCtotalSupply >= _value), "Insufficient availability");
      _balances[_from] -= _value;
      ERCtotalSupply -= _value;
      emit Transfer(_from, Dead, _value);
    }

    function ERCtransferFrom(address _from, address _to, uint256 _value) public override onlyContract returns (bool success) {
        uint256 _allowance = allowed[_from][msg.sender];
        require(_balances[_from] >= _value && _allowance >= _value, "token balance or allowance is lower than amount requested");
        _balances[_to] += _value;
        _balances[_from] -= _value;
        if (_allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function ERCbalanceOf(address _owner) public override view returns (uint256 balance) {
        return _balances[_owner];
    }


    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function ERCapprove(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    /// @dev Decimals must be 0 in this case, as every token is an NFT and so is not divisible
    /// WIP: Can be done in the opposite way, maybe. NFT can always represent 1*decimals but
    ///      how to manage transfers of half tokens?
    function decimals() public pure override returns (uint) {
        return 0;
    }

  /* ================================================================================================== */
  /* ================================================================================================== */
  /* ============================================ NFT Part ============================================ */
  /* ================================================================================================== */
  /* ================================================================================================== */

    /*
    NFT Properties are defined here and are compliant with ERC721 standard
    */

  function _setBaseURI(string memory newURI) public onlyAuth {
      baseURI = newURI;
  }

  function _baseURI() internal view returns (string memory) {
        return baseURI;
   }

  function NFT_mint(uint256 quantity) internal {
    coinPrice = getTokenPrice(1);
    // _safeMint's second argument now takes in a quantity, not a tokenId.
    if(!(coinPrice==0)) {
      require(msg.value==coinPrice, "Price not reached");
    }
    if(!(MaxNftMintable==0)) {
      require((NFTtotalSupply()+quantity) <= MaxNftMintable, "Max emission reached");
    }
    _mint(msg.sender, quantity);

  }


  /* ==================================================================================================== */
  /* ==================================================================================================== */
  /* ======================================== Machine Functions ========================================= */
  /* ==================================================================================================== */
  /* ==================================================================================================== */

    
    struct LIQUID_STAKE {
        uint[] staked_ids;
    }

    mapping(address => LIQUID_STAKE) Liquid_Stakes;
    
    mapping(uint => uint8) token_rarities;

    /// @dev Set max number of mintable Liquid Tokens
    // @param max Max number of mintable Liquid Tokens
    function setMaxMintable(uint max) public onlyAuth {
      MaxNftMintable = max;
    }

    ///@dev Set rarity at mint
    //@param Boolean
    function SetRarityAtMintControl(bool setter) public onlyAuth {
      SetRarityAtMint = setter;
    }

   /// @dev Manual rarity assign for an array of tokens
   // @param tokens A list of tokens to assign rarity to 
   function setRarityBatch(uint[] calldata tokens) public onlyAuth returns(bool success) {
     assign_rarity_batch(tokens);
     return true;
   }

   /// @dev Linking NFT mint and token creation
    function mint(uint256 quantity) public payable {
        if (SetRarityAtMint) {
          assign_rarity(quantity);
        }
        NFT_mint(quantity);
        mintToken(msg.sender, quantity);
    }

    /// @dev Very near to random function (supports up to 8 bit)
    function random_8bit(uint8 max) private view returns (uint8) {
        // sha3 and now have been deprecated
        uint r_uint = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _totalMinted())));
        while (r_uint > max) {
            r_uint -= max;
        }
        uint8 result = uint8(r_uint);
        return result;
        // convert hash to integer
        // players is an array of entrants
    
    }

    function calculate_luck(address target) public view returns(uint16 luck) {
        uint16 target_luck = 0;
        /// To catch all the NFTs of an user, i will increase only when ownership is asserted through 
        //  bitwise operations (to be more efficient than bool).
        /// In the same case, with just another operation on 8 bit, we automatically increase the luck
        /// value through rarity retrieving
        for(uint8 i; i < (NFTbalanceOf(target)); i) {
                address owner_of = owner_of_nft(i);
                i += ((owner_of==msg.sender) ? 1 : 0);
                target_luck += ((owner_of==msg.sender) ? get_rarity(i) : 0);
        }
        return target_luck;
    } 


    /// Assigning rarity is lightened by:
    /// - Using a 8 bit random generated fully in memory
    /// - Assigning to the 8 bit mapping (so saving on packed gas) 
    ///     the random value without evaluations
    /// We are doing this because we let to get_rarity the evaluation task 
    /// of returning the rarity without even storing it through bitwise operations


    /// @dev Assigning rarity 
    // @param tokens Number of tokens to assign to 
    function assign_rarity(uint quantity) internal {
        uint starting_point = _totalMinted()+1;
        uint8 rand;

        for(uint i = starting_point; i < quantity; i++) {
            rand = random_8bit(100);
            token_rarities[i] = rand;
        } 
    }

    /// @dev Assigning rarity in batch 
    // @param tokens A list of tokens to assign rarity to 
    function assign_rarity_batch(uint[] calldata tokens) internal {
        uint8 rand;

        for(uint i = 0; i < tokens.length; i++) {
            rand = random_8bit(100);
            token_rarities[tokens[i]] = rand;
        } 
    }

    /// Rarity isn't statically stored but is obtained with almost no effort from
    /// in-memory variables and constants through bitwise operations adding 1 or 0
    /// to the rarity based on boundaries defining N types of rarity
    function get_rarity(uint id) public view returns(uint8 rarity) {
        /// Adding 0 for every boundary crossed (ex. if out of rare range, add 0), otherwise is 1
        uint8 _rarity = token_rarities[id];
        uint16 luck = calculate_luck(msg.sender);
        return ( ((_rarity < (3+luck)) ? 1 : 0) + 
                 ((_rarity < (7+luck)) ? 1 : 0) + 
                 ((_rarity < (10+luck)) ? 1 : 0) );  /// Ex.: _rarity = 8
                                              ///      rarity = 0 (common) +
                                              ///               1 (as is < 10) +
                                              ///               0 (as is >= 7) +
                                              ///               0 (as is >= 3) =
                                              ///
                                              ///               1 (meaning Uncommon 1)
                                              ///                                    
                                              /// Ex.: _rarity = 2
                                              ///      rarity = 0 (common) +
                                              ///               1 (as is < 10) +
                                              ///               1 (as is < 7) +
                                              ///               1 (as is < 3) =
                                              ///
                                              ///               3 (meaning Rare)
                                        
    }

    function stake_common_liquids(uint amount) public payable safe {

    }

    function stake_special_liquids(uint[] calldata ids) public payable safe {
    
    }

  
}

contract FluidFactory {

    mapping(address => bool) public owner;
    bool public PrivateDeploy = true;
    string public MakerIdentifier;
    uint public DeployPrice;
    address initialDeploy;

    constructor(string memory name__, string memory ticker__, uint max__, 
                string memory identifier, uint price) {
        owner[msg.sender] = true;
        DeployPrice = price;
        MakerIdentifier = identifier;
        name__ = string.concat(name__, " - ", MakerIdentifier);
        initialDeploy = emit_a_different_token(name__, ticker__, max__);
    }

    function set_private_deploy(bool is_private) public {
        require(owner[msg.sender], "403");
        PrivateDeploy = is_private;
    }

    function address_is_owner(bool is_it) public {
        require(owner[msg.sender], "403");
        owner[msg.sender] = is_it;
    }

    function change_deploy_price(uint price) public {
        require(owner[msg.sender], "403");
        DeployPrice = price;
    }

    function emit_a_different_token(string memory _name, string memory _ticker,  uint max__) 
    public payable returns(address deployed) {
        if(PrivateDeploy) {
            require(owner[msg.sender], "403");
        }
        if(DeployPrice > 0) {
            require(msg.value>=DeployPrice);
        }
        address new_address = address(new LiquidToken(_name, _ticker, max__));
        return new_address;
    }

}