/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
    
    abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}}

// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
    pragma solidity ^0.8.0;
    abstract contract Ownable is Context {address private _owner; event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {_transferOwnership(_msgSender());}
    function owner() public view virtual returns (address) {return _owner;}
    modifier onlyOwner() {require(owner() == _msgSender(), "Ownable: caller is not the owner"); _;}
    function renounceOwnership() public virtual onlyOwner {_transferOwnership(address(0));}
    function transferOwnership(address newOwner) public virtual onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address"); _transferOwnership(newOwner);}
    function _transferOwnership(address newOwner) internal virtual {address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner);}}

// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
    library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0";} uint256 temp = value; uint256 digits; while (temp != 0) {digits++; temp /= 10;} bytes memory buffer = new bytes(digits);
        while (value != 0) {digits -= 1; buffer[digits] = bytes1(uint8(48 + uint256(value % 10))); value /= 10;} return string(buffer);}
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0x00";} uint256 temp = value; uint256 length = 0; while (temp != 0) {length++; temp >>= 8;} return toHexString(value, length);}
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {bytes memory buffer = new bytes(2 * length + 2); buffer[0] = "0"; buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {buffer[i] = _HEX_SYMBOLS[value & 0xf]; value >>= 4;} require(value == 0, "Strings: hex length insufficient"); return string(buffer);}}

// File: erc721a/contracts/IERC721A.sol
// ERC721A Contracts v4.0.0
    pragma solidity ^0.8.4;
    interface IERC721A {error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApproveToCaller();
    error ApprovalToCurrentOwner();
    error BalanceQueryForZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerQueryForNonexistentToken();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();
    struct TokenOwnership {address addr; uint64 startTimestamp; bool burned;}
    function totalSupply() external view returns (uint256);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);}

// File: erc721a/contracts/ERC721A.sol
// ERC721A Contracts v4.0.0
    pragma solidity ^0.8.4; interface ERC721A__IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);}

    contract ERC721A is IERC721A {
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;
    uint256 private constant BITPOS_NUMBER_MINTED = 64;
    uint256 private constant BITPOS_NUMBER_BURNED = 128;
    uint256 private constant BITPOS_AUX = 192;
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;
    uint256 private constant BITPOS_START_TIMESTAMP = 160;
    uint256 private constant BITMASK_BURNED = 1 << 224;
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;
    uint256 private _currentIndex;
    uint256 private _burnCounter;
    string private _name;
    string private _symbol;
    mapping(uint256 => uint256) private _packedOwnerships;
    mapping(address => uint256) private _packedAddressData;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {_name = name_; _symbol = symbol_; _currentIndex = _startTokenId();}
    function _startTokenId() internal view virtual returns (uint256) {return 1;}
    function _nextTokenId() internal view returns (uint256) {return _currentIndex;}
    function totalSupply() public view override returns (uint256) {unchecked {return _currentIndex - _burnCounter - _startTokenId();}}
    function _totalMinted() internal view returns (uint256) {unchecked {return _currentIndex - _startTokenId();}}
    function _totalBurned() internal view returns (uint256) {return _burnCounter;}
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {return interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;}
    function balanceOf(address owner) public view override returns (uint256) {if (owner == address(0)) revert BalanceQueryForZeroAddress(); return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;}
    function _numberMinted(address owner) internal view returns (uint256) {return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;}
    function _numberBurned(address owner) internal view returns (uint256) {return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;}
    function _getAux(address owner) internal view returns (uint64) {return uint64(_packedAddressData[owner] >> BITPOS_AUX);}
    function _setAux(address owner, uint64 aux) internal {uint256 packed = _packedAddressData[owner]; uint256 auxCasted; assembly {auxCasted := aux}
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);_packedAddressData[owner] = packed;}
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {uint256 curr = tokenId; unchecked {
        if (_startTokenId() <= curr) 
        if (curr < _currentIndex) {uint256 packed = _packedOwnerships[curr]; 
        if (packed & BITMASK_BURNED == 0) {while (packed == 0) {packed = _packedOwnerships[--curr];} return packed; }}} revert OwnerQueryForNonexistentToken();}
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed)); ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP); ownership.burned = packed & BITMASK_BURNED != 0;}
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {return _unpackedOwnership(_packedOwnerships[index]);}
    function _initializeOwnershipAt(uint256 index) internal {if (_packedOwnerships[index] == 0) {_packedOwnerships[index] = _packedOwnershipOf(index);}}
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {return _unpackedOwnership(_packedOwnershipOf(tokenId));}
    function ownerOf(uint256 tokenId) public view override returns (address) {return address(uint160(_packedOwnershipOf(tokenId)));}
    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken(); string memory baseURI = _baseURI(); return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';}
    function _baseURI() internal view virtual returns (string memory) {return '';}
    function _addressToUint256(address value) private pure returns (uint256 result) {assembly {result := value}}
    function _boolToUint256(bool value) private pure returns (uint256 result) {assembly {result := value}}
    function approve(address to, uint256 tokenId) public override {address owner = address(uint160(_packedOwnershipOf(tokenId)));
        if (to == owner) revert ApprovalToCurrentOwner();
        if (_msgSenderERC721A() != owner)
        if (!isApprovedForAll(owner, _msgSenderERC721A())) {revert ApprovalCallerNotOwnerNorApproved();}_tokenApprovals[tokenId] = to;emit Approval(owner, to, tokenId);}
    function getApproved(uint256 tokenId) public view override returns (address) {if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken(); return _tokenApprovals[tokenId];}
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller(); _operatorApprovals[_msgSenderERC721A()][operator] = approved; emit ApprovalForAll(_msgSenderERC721A(), operator, approved);}
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {return _operatorApprovals[owner][operator];}
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {_transfer(from, to, tokenId);}
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {safeTransferFrom(from, to, tokenId, '');}
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {_transfer(from, to, tokenId);
        if (to.code.length != 0)
        if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {revert TransferToNonERC721ReceiverImplementer();}}
    function _exists(uint256 tokenId) internal view returns (bool) {return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex &&
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0;}
    function _safeMint(address to, uint256 quantity) internal {_safeMint(to, quantity, '');}
    function _safeMint(address to, uint256 quantity, bytes memory _data) internal {uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity(); _beforeTokenTransfers(address(0), to, startTokenId, quantity); unchecked {_packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1); _packedOwnerships[startTokenId] = _addressToUint256(to) | (block.timestamp << BITPOS_START_TIMESTAMP) | (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED); uint256 updatedIndex = startTokenId; uint256 end = updatedIndex + quantity;
        if (to.code.length != 0) {do {emit Transfer(address(0), to, updatedIndex);
        if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {revert TransferToNonERC721ReceiverImplementer();}} while (updatedIndex < end);
        if (_currentIndex != startTokenId) revert();} else {do {emit Transfer(address(0), to, updatedIndex++);} while (updatedIndex < end);} _currentIndex = updatedIndex;} _afterTokenTransfers(address(0), to, startTokenId, quantity);}
    function _mint(address to, uint256 quantity) internal {uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity(); _beforeTokenTransfers(address(0), to, startTokenId, quantity); unchecked {_packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);
            _packedOwnerships[startTokenId] = _addressToUint256(to) | (block.timestamp << BITPOS_START_TIMESTAMP) | (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);
            uint256 updatedIndex = startTokenId; uint256 end = updatedIndex + quantity;
            do {emit Transfer(address(0), to, updatedIndex++); } while (updatedIndex < end); _currentIndex = updatedIndex;} _afterTokenTransfers(address(0), to, startTokenId, quantity);}
    function _transfer(address from, address to, uint256 tokenId) private {uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner(); bool isApprovedOrOwner = (_msgSenderERC721A() == from || isApprovedForAll(from, _msgSenderERC721A()) || getApproved(tokenId) == _msgSenderERC721A());
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress(); _beforeTokenTransfers(from, to, tokenId, 1); delete _tokenApprovals[tokenId];
        unchecked { --_packedAddressData[from]; ++_packedAddressData[to]; _packedOwnerships[tokenId] = _addressToUint256(to) | (block.timestamp << BITPOS_START_TIMESTAMP) | BITMASK_NEXT_INITIALIZED;
        if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {uint256 nextTokenId = tokenId + 1;
        if (_packedOwnerships[nextTokenId] == 0) {
        if (nextTokenId != _currentIndex) {_packedOwnerships[nextTokenId] = prevOwnershipPacked;}}}} emit Transfer(from, to, tokenId); _afterTokenTransfers(from, to, tokenId, 1);}
    function _burn(uint256 tokenId) internal virtual {_burn(tokenId, false);}
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId); address from = address(uint160(prevOwnershipPacked));
        if (approvalCheck) {bool isApprovedOrOwner = (_msgSenderERC721A() == from || isApprovedForAll(from, _msgSenderERC721A()) || getApproved(tokenId) == _msgSenderERC721A());
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();} _beforeTokenTransfers(from, address(0), tokenId, 1); delete _tokenApprovals[tokenId];
            unchecked {_packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1; _packedOwnerships[tokenId] = _addressToUint256(from) | (block.timestamp << BITPOS_START_TIMESTAMP) | BITMASK_BURNED |  BITMASK_NEXT_INITIALIZED;
        if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {uint256 nextTokenId = tokenId + 1;
        if (_packedOwnerships[nextTokenId] == 0) {
        if (nextTokenId != _currentIndex) {_packedOwnerships[nextTokenId] = prevOwnershipPacked;}}}} emit Transfer(from, address(0), tokenId); _afterTokenTransfers(from, address(0), tokenId, 1); unchecked {_burnCounter++;}}
    function _checkContractOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (bytes4 retval) {return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;} catch (bytes memory reason) {
        if (reason.length == 0) {revert TransferToNonERC721ReceiverImplementer();} else {assembly {revert(add(32, reason), mload(reason))}}}}
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}
    function _msgSenderERC721A() internal view virtual returns (address) {return msg.sender;}
    function _toString(uint256 value) internal pure returns (string memory ptr) {assembly {ptr := add(mload(0x40), 128) mstore(0x40, ptr) let end := ptr
        for {let temp := value ptr := sub(ptr, 1) mstore8(ptr, add(48, mod(temp, 10))) temp := div(temp, 10)} temp {temp := div(temp, 10)} 
            {ptr := sub(ptr, 1) mstore8(ptr, add(48, mod(temp, 10)))} let length := sub(end, ptr) ptr := sub(ptr, 32) mstore(ptr, length)}}}

    pragma solidity ^0.8.13;
    contract SpacePepes is Ownable, ERC721A {
    uint256 public maxSupply                    = 3333;
    uint256 public maxFreeSupply                = 3333;
    uint256 public maxPerTxDuringMint           = 10;
    uint256 public maxPerAddressDuringMint      = 11;
    uint256 public maxPerAddressDuringFreeMint  = 1;
    uint256 public price                        = 0.002 ether;
    bool    public saleIsActive                 = true;
    bool    public revealed                     = true;

    address constant internal TEAM_ADDRESS = 0x16d948CD51EADeaaE061f0F28bd177D19ec6ccbC;
    string public baseURI = "ipfs://QmTaJm2agDv3mQpSC1w7i2fsKX8BFhNbn7m8CGEF713mhS/";
    string public constant baseExtension = ".json";
    string public hiddenMetadataUri;
    mapping(address => uint256) public freeMintedAmount;
    mapping(address => uint256) public mintedAmount;
    constructor() ERC721A("Space Pepes", "SP") {_safeMint(msg.sender, 100); setHiddenMetadataUri("");}
    
    modifier mintCompliance() {require(saleIsActive, "Sale is not active yet."); require(tx.origin == msg.sender, "Wrong Caller"); _;}
    function mint(uint256 _quantity) external payable mintCompliance() {require (msg.value >= price * _quantity, "Insufficient Funds");
        require(maxSupply >= totalSupply() + _quantity, "Exceeds max supply."); uint256 _mintedAmount = mintedAmount[msg.sender];
        require(_mintedAmount + _quantity <= maxPerAddressDuringMint, "Exceeds max mints per address!");
        require(_quantity > 0 && _quantity <= maxPerTxDuringMint, "Invalid mint amount."); mintedAmount[msg.sender] = _mintedAmount + _quantity; _safeMint(msg.sender, _quantity);}
    function freeMint(uint256 _quantity) external mintCompliance() {
        require(maxFreeSupply >= totalSupply() + _quantity, "Exceeds max supply."); uint256 _freeMintedAmount = freeMintedAmount[msg.sender];
        require(_freeMintedAmount + _quantity <= maxPerAddressDuringFreeMint, "Exceeds max free mints per address!"); freeMintedAmount[msg.sender] = _freeMintedAmount + _quantity; _safeMint(msg.sender, _quantity);}
    function setPrice(uint256 _price) external onlyOwner {price = _price;}
    function setMaxPerTx(uint256 _amount) external onlyOwner {maxPerTxDuringMint = _amount;}
    function setMaxPerAddress(uint256 _amount) external onlyOwner {maxPerAddressDuringMint = _amount;}
    function setMaxFreePerAddress(uint256 _amount) external onlyOwner {maxPerAddressDuringFreeMint = _amount;}
    function flipSale() public onlyOwner {saleIsActive = !saleIsActive;}
    function setMaxSupply(uint256 newSupply) public onlyOwner {maxSupply = newSupply;}
    function cutMaxSupply(uint256 _amount) public onlyOwner {require(maxSupply - _amount >= totalSupply(), "Supply cannot fall below minted tokens."); maxSupply -= _amount;}
    function setRevealed(bool _state) public onlyOwner {revealed = _state;}
    function setBaseURI(string memory baseURI_) external onlyOwner {baseURI = baseURI_;}
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {hiddenMetadataUri = _hiddenMetadataUri;}
    function _baseURI() internal view virtual override returns (string memory) {return baseURI;}
    function tokenURI(uint256 _tokenId) public view override returns (string memory) 
        {require(_exists(_tokenId), "Token does not exist."); if (revealed == false) {return hiddenMetadataUri;} 
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId), baseExtension)) : "";}
    function withdrawBalance() external payable onlyOwner {(bool success, ) = payable(TEAM_ADDRESS).call{value: address(this).balance} (""); require(success, "transfer failed.");}}