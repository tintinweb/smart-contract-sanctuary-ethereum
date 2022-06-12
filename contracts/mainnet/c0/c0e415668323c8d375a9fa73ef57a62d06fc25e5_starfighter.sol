/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

//  _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _                         
// |   ____  _          ____                 |
// |  / ___|(_) _   _  |  _ \   ___ __   __  |
// | | |  _ | || | | | | | | | / _ \\ \ / /  |
// | | |_| || || |_| | | |_| ||  __/ \ V /   |
// |  \____||_| \__,_| |____/  \___|  \_/    |
// | _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ |    
                                  
interface IERC721A {

    // The caller must own the token or be an approved operator
    error ApprovalCallerNotOwnerNorApproved();

    //The token does not exist
    error ApprovalQueryForNonexistentToken();

    //The caller cannot approve to their own address
    error ApproveToCaller();

    //The caller cannot approve to the current owner
    error ApprovalToCurrentOwner();

    //Cannot query the balance for the zero address
    error BalanceQueryForZeroAddress();

    //Cannot mint to the zero address
    error MintToZeroAddress();

    //The quantity of tokens minted must be more than zero
    error MintZeroQuantity();

    //The token does not exist
    error OwnerQueryForNonexistentToken();

    //The caller must own the token or be an approved operator.
    error TransferCallerNotOwnerNorApproved();

    ///The token must be owned by `from`
    error TransferFromIncorrectOwner();

    //Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
    error TransferToNonERC721ReceiverImplementer();

    //Cannot transfer to the zero address
    error TransferToZeroAddress();

    //The token does not exist
    error URIQueryForNonexistentToken();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;}

    //Returns the total amount of tokens stored by the contract
    //Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens
    function totalSupply() external view returns (uint256);

    //Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    //Emitted when `tokenId` token is transferred from `from` to `to`
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    //Emitted when `owner` enables `approved` to manage the `tokenId` token
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    //Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    //Returns the number of tokens in `owner` account
    function balanceOf(address owner) external view returns (uint256 balance);

    //Returns the owner of the `tokenId` token
    function ownerOf(uint256 tokenId) external view returns (address owner);

    //Safely transfers `tokenId` token from `from` to `to`
    //Requirements: `from` cannot be the zero address
    //              `to` cannot be the zero address
    //              `tokenId` token must exist and be owned by `from`
    //              If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}
    //              If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    //Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients are aware of the ERC721 protocol to prevent tokens from being forever locked.
    //Requirements: `from` cannot be the zero address.
    //              `to` cannot be the zero address.
    //              `tokenId` token must exist and be owned by `from`
    //              If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}
    //              If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    //Transfers `tokenId` token from `from` to `to`
    //Requirements: `from` cannot be the zero address
    //              `to` cannot be the zero address
    //              `tokenId` token must be owned by `from`
    //              If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}
    function transferFrom(address from, address to, uint256 tokenId) external;

    //Gives permission to `to` to transfer `tokenId` token to another account
    function approve(address to, uint256 tokenId) external;

    //Approve or remove `operator` as an operator for the caller
    //Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller
    //Requirements: The `operator` cannot be the caller.
    function setApprovalForAll(address operator, bool _approved) external;

    //Returns the account approved for `tokenId` token.
    //Requirements: `tokenId` must exist
    function getApproved(uint256 tokenId) external view returns (address operator);

    //Returns if the `operator` is allowed to manage all of the assets of `owner`
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    //Returns the token collection name
    function name() external view returns (string memory);

    //Returns the token collection symbol
    function symbol() external view returns (string memory);

    //Returns the Uniform Resource Identifier (URI) for `tokenId` token
    function tokenURI(uint256 tokenId) external view returns (string memory);}

interface ERC721A__IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);}

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
        _currentIndex = _startTokenId();}

    //Returns the starting token ID
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;}

    //Returns the next token ID to be minted
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;}

    //Returns the total number of tokens in existence
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {return _currentIndex - _burnCounter - _startTokenId();}}

    //Returns the total amount of tokens minted in the contract
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();}}

    //Returns the total number of tokens burned
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;}

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;}

    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;}

    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;}

    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);}

    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        assembly { // Cast aux without masking.
            auxCasted := aux}
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;}

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
                            packed = _packedOwnerships[--curr];}
                        return packed;}}}
        revert OwnerQueryForNonexistentToken();}

    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;}

    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);}

    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);}}

    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));}

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));}

    function name() public view virtual override returns (string memory) {
        return _name;}

    function symbol() public view virtual override returns (string memory) {
        return _symbol;}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';}

    //Base URI for computing {tokenURI}. 
    function _baseURI() internal view virtual returns (string memory) {
        return '';}

    function _addressToUint256(address value) private pure returns (uint256 result) {
        assembly {
            result := value}}

    function _boolToUint256(bool value) private pure returns (uint256 result) {
        assembly {
            result := value}}

    function approve(address to, uint256 tokenId) public override {
        address owner = address(uint160(_packedOwnershipOf(tokenId)));
        if (to == owner) revert ApprovalToCurrentOwner();
        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();}
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);}

    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();
        return _tokenApprovals[tokenId];}

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);}

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];}

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        _transfer(from, to, tokenId);}

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, '');}

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        _transfer(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();}}

    //Returns whether `tokenId` exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && _packedOwnerships[tokenId] & BITMASK_BURNED == 0;}

    //Equivalent to `_safeMint(to, quantity, '')`
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');}

    //Safely mints `quantity` tokens and transfers them to `to`
    function _safeMint(address to, uint256 quantity, bytes memory _data) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
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
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();}} 
                while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();} 
                else {
                do {emit Transfer(address(0), to, updatedIndex++);} while (updatedIndex < end);}
            _currentIndex = updatedIndex;}
        _afterTokenTransfers(address(0), to, startTokenId, quantity);}

    //Mints `quantity` tokens and transfers them to `to`
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
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
            do {emit Transfer(address(0), to, updatedIndex++);} while (updatedIndex < end);
            _currentIndex = updatedIndex;}
        _afterTokenTransfers(address(0), to, startTokenId, quantity);}

    //Transfers `tokenId` from `from` to `to`
    function _transfer(address from, address to, uint256 tokenId) private {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();
        bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
            isApprovedForAll(from, _msgSenderERC721A()) ||
            getApproved(tokenId) == _msgSenderERC721A());
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();
        _beforeTokenTransfers(from, to, tokenId, 1);
        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];
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
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;}}}}
        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);}

    //Equivalent to `_burn(tokenId, false)`
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);}

    //Destroys `tokenId`
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
        address from = address(uint160(prevOwnershipPacked));
        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSenderERC721A() == from || isApprovedForAll(from, _msgSenderERC721A()) || getApproved(tokenId) == _msgSenderERC721A());
            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();}
        _beforeTokenTransfers(from, address(0), tokenId, 1);
        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];
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
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;}}}}
        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);
        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {_burnCounter++;}}

    //Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract
    function _checkContractOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;} 
            catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();} 
            else {
                assembly {revert(add(32, reason), mload(reason))}}}}

    //Hook that is called before a set of serially-ordered token ids are about to be transferred
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}

    //Hook that is called after a set of serially-ordered token ids have been transferred
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}

    //Returns the message sender (defaults to `msg.sender`)
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;}

    //Converts a `uint256` to its ASCII `string` decimal representation
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
                temp := div(temp, 10)} 
            temp { 
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)} { // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))}
            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)}}}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;}

    //Prevents a contract from calling itself, directly or indirectly.
    //Calling a `nonReentrant` function from another `nonReentrant`function is not supported. 
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;}}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;}

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;}}

abstract contract Ownable is Context {

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        //dev Initializes the contract setting the deployer as the initial owner
        _transferOwnership(_msgSender());}

    function owner() public view virtual returns (address) {
        //Returns the address of the current owner
        return _owner;}

    modifier onlyOwner() {
        //Throws if called by any account other than the owner
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;}

    function renounceOwnership() public virtual onlyOwner {
        //Leaves the contract without owner
        _transferOwnership(address(0));}

    function transferOwnership(address newOwner) public virtual onlyOwner {
        //Transfers ownership of the contract to a new account (`newOwner`)
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);}

    function _transferOwnership(address newOwner) internal virtual {
        //Transfers ownership of the contract to a new account (`newOwner`)
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);}}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";}
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;}
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;}
        return string(buffer);}
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";}
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;}
        return toHexString(value, length);}
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;}
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);}
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);}}

contract starfighter is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public costWhitelist = 0.05 ether;
    uint256 public costNormal = 0.06 ether;
    uint256 public NFTminted;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    //mapping(address => bool) public whitelistClaimed;
    mapping (address => bool) public whitelisted;
    mapping(address => uint) public minted;

    string public tokenName = "STARFIGHTER CLUB";
    string public tokenSymbol = "SFC";
    uint256 public maxSupply = 333;
    uint256 public maxMintAmountPerTx = 12;
    string public hiddenMetadataUri = "ipfs://QmVUr53zcyrXr7VfBg7PLjmMcL17N5Xej8bKSBbRAro8tQ/hidden.json";
    
    constructor() ERC721A(tokenName, tokenSymbol) {
            maxSupply = maxSupply;
            setMaxMintAmountPerTx(maxMintAmountPerTx);
            setHiddenMetadataUri(hiddenMetadataUri);}

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        _;}

    modifier mintPriceCompliance(uint256 _mintAmount) {
        if(whitelistMintEnabled == true && paused == true){
            require(msg.value >= costWhitelist * _mintAmount, 'Insufficient funds!');}
        if(paused == false){
            require(msg.value >= costNormal * _mintAmount, 'Insufficient funds!');}
        _;}

    function setCostWhitelist(uint256 _cost) public onlyOwner {
        //Ether cost
        costWhitelist = _cost;}

    function setCostNormal(uint256 _cost) public onlyOwner {
        //Ether cost
        costNormal = _cost;}

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!paused, 'The contract is paused!');
        minted[_msgSender()] = minted[_msgSender()] + _mintAmount;//CHECK
        require(minted[_msgSender()] <= maxMintAmountPerTx, "Max quantity reached");
        NFTminted += _mintAmount;
            _safeMint(_msgSender(), _mintAmount);}

    function burn(uint256 tokenId) public {
        _burn(tokenId, true); }

    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        //Minted by Owner without any cost, doesn't count on minted quantity
        NFTminted += _mintAmount;
        _safeMint(_receiver, _mintAmount);}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;}

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (revealed == false) {
            return hiddenMetadataUri;}
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)): '';}
    
    function setRevealed(bool _state) public onlyOwner {
        //Reveal the token URI of the NFTs
        revealed = _state;}

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;}

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;}

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;}

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;}

    function setPaused(bool _state) public onlyOwner {
        paused = _state;}

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;}

    function whitelist(address _addr) public onlyOwner() {
        require(!whitelisted[_addr], "Account is already Whitlisted");
        whitelisted[_addr] = true;}

    function blacklist_A_whitelisted(address _addr) external onlyOwner() {
        require(whitelisted[_addr], "Account is already Blacklisted");
        whitelisted[_addr] = false;}

    function whitelistMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        // Verify whitelist requirements
        require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
        //require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
        require(whitelisted[_msgSender()], "Account is not in whitelist");
        minted[_msgSender()] = minted[_msgSender()] + _mintAmount;//CHECK
        require(minted[_msgSender()] <= maxMintAmountPerTx, "Max quantity reached");
        NFTminted += _mintAmount;
        //whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);}

    function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);}
        
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;}}