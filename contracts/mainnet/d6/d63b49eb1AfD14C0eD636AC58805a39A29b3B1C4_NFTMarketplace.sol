/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
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
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "OZ:1");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "OZ:2");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "OZ:3");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "OZ:4");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "OZ:5");
        require(isContract(target), "OZ:6");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "OZ:7");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "OZ:8");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "OZ:9");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "OZ:10");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
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
        require(value == 0, "OZ:11");
        return string(buffer);
    }
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "OZ:12");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "OZ:13");
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "OZ:14");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "OZ:15"
        );
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "OZ:16");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "OZ:17");
        _safeTransfer(from, to, tokenId, data);
    }
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "OZ:18");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "OZ:19"
        );
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "OZ:20");
        require(!_exists(tokenId), "OZ:21");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId);
    }
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "OZ:22");
        require(to != address(0), "OZ:23");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "OZ:24");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "OZ:25");
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("OZ:26");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
}

library Counters {
    struct Counter {
        uint256 _value;
    }
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }
    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "OZ:27");
        unchecked {
            counter._value = value - 1;
        }
    }
    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "OZ:28");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(tokenId);
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "OZ:29");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "OZ:30");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "OZ:31");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract NFTMarketplace is ReentrancyGuard, ERC721URIStorage, Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter public _bidIds;
    address _scAddress;
    string public _tokenName;
    string public _tokenSymbol;
    uint256 private _maxTokenSupply;
    address payable marketOwner;
    mapping (uint256 => string) _tokenIDURI;
    uint256 totalUserMPWalletFunds;
    mapping(address => uint256) private mpWallets;
    struct MarketItem {
        uint256 tokenId;
        address nftContract;
        string uri;
        address payable nftCreator;
        address payable nftOwner;
        uint256 price;
        bool forSale;
    }
    mapping(uint256 => MarketItem) private MarketItemDatabase;
    event MarketItemCreated(
        uint256 indexed tokenId,
        address indexed nftContract,
        string uri,
        address creator,
        address owner,
        uint256 price,
        bool forSale
    );
    constructor(string memory tokenName, string memory tokenSymbol, uint256 gotMaxTokenSupply) ERC721(tokenName, tokenSymbol){
        marketOwner = payable(msg.sender);
        require(gotMaxTokenSupply > 0, "ERR:1");
        _maxTokenSupply = gotMaxTokenSupply;
        _tokenName = tokenName;
        _tokenSymbol = tokenSymbol;
    }
    function marketSetup(address scAddress) public onlyOwner{
        _scAddress = scAddress;
    }
    function totalSupply() public view returns (uint256){
        return (_maxTokenSupply);
    }
    function getNewTokenID() public view returns (uint256){
        return _tokenIds.current();
    }
    function addTokens(uint256 gotNewMaxTokenSupply) public onlyOwner{
        require(msg.sender == marketOwner, "ERR:2");
        require(gotNewMaxTokenSupply > _maxTokenSupply, "ERR:3");
        _maxTokenSupply = gotNewMaxTokenSupply;
    }
    function fetchTokenIDURI(uint256 tokenID) public view returns (string memory){
        bytes memory tempTokenURI = bytes(_tokenIDURI[tokenID]);
        require(tempTokenURI.length > 0, "ERR:4");
        return _tokenIDURI[tokenID];
    }
    function mintNFT(string memory uri) public payable nonReentrant{
        require(_tokenIds.current() != _maxTokenSupply, "ERR:5");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, uri);
        _tokenIDURI[newTokenId] = uri;
        MarketItemDatabase[newTokenId] = MarketItem(newTokenId, _scAddress, uri, payable(msg.sender), payable(address(0)), 0, false);
        emit MarketItemCreated(newTokenId, _scAddress, uri, msg.sender, address(0), 0, false);
    }
    function listNFT(uint256 tokenId, uint256 price) public {
        require((msg.sender == MarketItemDatabase[tokenId].nftCreator && MarketItemDatabase[tokenId].nftOwner == address(0)) || msg.sender == MarketItemDatabase[tokenId].nftOwner, "ERR:6");
        setApprovalForAll(_scAddress, true);
        MarketItemDatabase[tokenId].forSale = true;
        MarketItemDatabase[tokenId].price = price;
        IERC721(_scAddress).transferFrom(msg.sender, address(this), tokenId);
    }
    function unlistNFT(uint256 tokenId) public {
        require((msg.sender == MarketItemDatabase[tokenId].nftCreator && MarketItemDatabase[tokenId].nftOwner == address(0)) || msg.sender == MarketItemDatabase[tokenId].nftOwner || msg.sender == marketOwner, "ERR:7");
        require(MarketItemDatabase[tokenId].forSale == true, "ERR:8");
        setApprovalForAll(_scAddress, true);
        MarketItemDatabase[tokenId].forSale = false;
        MarketItemDatabase[tokenId].price = 0;
        if(MarketItemDatabase[tokenId].nftOwner == address(0)){
            IERC721(_scAddress).transferFrom(address(this), MarketItemDatabase[tokenId].nftCreator, tokenId);
        } else{
            IERC721(_scAddress).transferFrom(address(this), MarketItemDatabase[tokenId].nftOwner, tokenId);
        }
    }
    function sellNFT(uint256 tokenId, uint256 marketItemPrice, uint256 sellerGets, uint256 marketOwnerGets) public payable nonReentrant{
        require(msg.sender != marketOwner, "ERR:9");
        require(MarketItemDatabase[tokenId].forSale == true, "ERR:10");
        require(msg.value == marketItemPrice, "ERR:11");
        if(MarketItemDatabase[tokenId].nftOwner == address(0)){
            MarketItemDatabase[tokenId].nftCreator.transfer(sellerGets);
        } else{
            MarketItemDatabase[tokenId].nftOwner.transfer(sellerGets);
        }
        IERC721(_scAddress).transferFrom(address(this), msg.sender, tokenId);
        MarketItemDatabase[tokenId].nftOwner = payable(msg.sender);
        MarketItemDatabase[tokenId].forSale = false;
        MarketItemDatabase[tokenId].price = 0;
        payable(marketOwner).transfer(marketOwnerGets);
    }
    function transferNFT(address recieverAddress, uint256 tokenId, uint256 gotTransferFee) public payable nonReentrant{
        require((msg.sender == MarketItemDatabase[tokenId].nftCreator && MarketItemDatabase[tokenId].nftOwner == address(0)) || msg.sender == MarketItemDatabase[tokenId].nftOwner, "ERR:12");
        require(MarketItemDatabase[tokenId].forSale == false, "ERR:13");
        require(msg.value == gotTransferFee, "ERR:14");
        setApprovalForAll(_scAddress, true);
        MarketItemDatabase[tokenId].nftOwner = payable(recieverAddress);
        payable(marketOwner).transfer(gotTransferFee);
        IERC721(_scAddress).transferFrom(msg.sender, recieverAddress, tokenId);
    }
    function bidWalletIN() public payable nonReentrant returns(bool){
        require(msg.sender != marketOwner, "ERR:15");
        mpWallets[msg.sender] = mpWallets[msg.sender] + msg.value;
        payable(marketOwner).transfer(msg.value);
        totalUserMPWalletFunds = totalUserMPWalletFunds + msg.value;
        return true;
    }
    function bidWalletOUT(address sendTo, uint256 withdrawAmount) public payable nonReentrant onlyOwner{
        require(msg.value == withdrawAmount, "ERR:18");
        require(mpWallets[sendTo] >= withdrawAmount, "ERR:19");
        mpWallets[sendTo] = mpWallets[sendTo] - withdrawAmount;
        totalUserMPWalletFunds = totalUserMPWalletFunds - withdrawAmount;
        payable(sendTo).transfer(withdrawAmount);
    }
    function bidPassCheck(address userWallet, uint256 currBid, uint256 tokenID) public view returns(bool){
        require(mpWallets[userWallet] > 0, "ERR:20");
        require((userWallet == MarketItemDatabase[tokenID].nftCreator && MarketItemDatabase[tokenID].nftOwner != address(0)) || userWallet != MarketItemDatabase[tokenID].nftOwner, "ERR:21");
        if(mpWallets[userWallet] >= currBid){
            return true;
        } else{
            return false;
        }
    }
    function soldBidNFT(address winner, uint256 bidAmount, uint256 nftOwnerGets, uint256 ownerGets, uint256 tokenId) public payable nonReentrant{
        require(MarketItemDatabase[tokenId].forSale == true, "ERR:22");
        require(msg.value == bidAmount, "ERR:23");
        setApprovalForAll(_scAddress, true);
        if(MarketItemDatabase[tokenId].nftOwner == address(0)){
            payable(MarketItemDatabase[tokenId].nftCreator).transfer(nftOwnerGets);
        }
        else {
            payable(MarketItemDatabase[tokenId].nftOwner).transfer(nftOwnerGets);
        }
        IERC721(_scAddress).transferFrom(address(this), winner, tokenId);
        payable(marketOwner).transfer(ownerGets);
        MarketItemDatabase[tokenId].nftOwner = payable(winner);
        MarketItemDatabase[tokenId].forSale == false;
        MarketItemDatabase[tokenId].price = 0;
        totalUserMPWalletFunds-=msg.value;
        mpWallets[winner] = mpWallets[winner] - msg.value;
    }
    function actualOwnerWallet(uint256 altOwnerFund) public view returns (uint256){
        return altOwnerFund-totalUserMPWalletFunds;
    }
    function bidderWallet(address bidderAddress) public view returns (uint256){
            return mpWallets[bidderAddress];
    }
}