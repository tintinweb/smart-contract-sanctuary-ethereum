/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721Metadata { 
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface ERC721Enumerable { 
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC721 { 
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

library AddressUtils {
    function isContract(address _addr) internal view returns (bool addressCheck) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(_addr) } 
        addressCheck = (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {
    string private constant NOT_CURRENT_OWNER = "018001";
    string private constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";
    address internal owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_CURRENT_OWNER");
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "CANNOT_TRANSFER_TO_ZERO_ADDRESS");
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract SupportsInterface is ERC165 {
    mapping(bytes4 => bool) internal supportedInterfaces;
    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
    }
    function supportsInterface(bytes4 _interfaceID) external override view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }
}

contract NFToken is ERC721, SupportsInterface {

    using AddressUtils for address;

    string internal constant ZERO_ADDRESS = "003001";
    string internal constant NOT_VALID_NFT = "003002";
    string internal constant NOT_OWNER_OR_OPERATOR = "003003";
    string internal constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
    string internal constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
    string internal constant NFT_ALREADY_EXISTS = "003006";
    string internal constant NOT_OWNER = "003007";
    string internal constant IS_OWNER = "003008";
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    mapping (uint256 => address) internal idToOwner;
    mapping (uint256 => address) internal idToApproval;
    mapping (address => uint256) internal ownerToNFTokenCount;
    mapping (address => mapping (address => bool)) internal ownerToOperators;

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], "NOT_OWNER_OR_OPERATOR");
        _;
    }
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || idToApproval[_tokenId] == msg.sender || ownerToOperators[tokenOwner][msg.sender], "NOT_OWNER_APPROVED_OR_OPERATOR");
        _;
    }
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), "NOT_VALID_NFT");
        _;
    }
    constructor() {
        supportedInterfaces[0x80ac58cd] = true; // ERC721
    }
    function balanceOf(address _owner) external override view returns (uint256) {
        require(_owner != address(0), "ZERO_ADDRESS");
        return _getOwnerNFTCount(_owner);
    }
    function ownerOf(uint256 _tokenId) external override view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0), "NOT_VALID_NFT");
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) external override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "NOT_OWNER");
        require(_to != address(0), "ZERO_ADDRESS");
        _transfer(_to, _tokenId);
    }
    function approve(address _approved, uint256 _tokenId) external override canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner, "IS_OWNER");
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }
    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    function getApproved(uint256 _tokenId) external override view validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }
    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) internal canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "NOT_OWNER");
        require(_to != address(0), "ZERO_ADDRESS");
        _transfer(_to, _tokenId);
        if (_to.isContract()) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED, "NOT_ABLE_TO_RECEIVE_NFT");
        }
    }
    function _transfer(address _to, uint256 _tokenId) internal virtual {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);
        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);
        emit Transfer(from, _to, _tokenId);
    }
    function _mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0), "ZERO_ADDRESS");
        require(idToOwner[_tokenId] == address(0), "NFT_ALREADY_EXISTS");
        _addNFToken(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }
    function _burn(uint256 _tokenId) internal virtual validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        _clearApproval(_tokenId);
        _removeNFToken(tokenOwner, _tokenId);
        emit Transfer(tokenOwner, address(0), _tokenId);
    }
    function _addNFToken(address _to, uint256 _tokenId) internal virtual {
        require(idToOwner[_tokenId] == address(0), "NFT_ALREADY_EXISTS");
        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to] += 1;
    }
    function _removeNFToken(address _from, uint256 _tokenId) internal virtual {
        require(idToOwner[_tokenId] == _from, "NOT_OWNER");
        ownerToNFTokenCount[_from] -= 1;
        delete idToOwner[_tokenId];
    }
    function _getOwnerNFTCount(address _owner) internal virtual view returns (uint256) {
        return ownerToNFTokenCount[_owner];
    }
    function _clearApproval(uint256 _tokenId) private {
        delete idToApproval[_tokenId];
    }
}

contract NFTokenMetadata is NFToken, ERC721Metadata {

    string internal nftName;
    string internal nftSymbol;
    mapping (uint256 => string) internal idToUri;

    constructor() {
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
    }
    function name() external override view returns (string memory _name) {
        _name = nftName;
    }
    function symbol() external override view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }
    function tokenURI(uint256 _tokenId) external override view validNFToken(_tokenId) returns (string memory) {
        return _tokenURI(_tokenId);
    }
    function _tokenURI(uint256 _tokenId) internal virtual view returns (string memory) {
        return idToUri[_tokenId];
    }
    function _burn(uint256 _tokenId) internal override virtual {
        super._burn(_tokenId);
        delete idToUri[_tokenId];
    }
    function _setTokenUri(uint256 _tokenId, string memory _uri) internal validNFToken(_tokenId) {
        idToUri[_tokenId] = _uri;
    }
}

contract NFTokenEnumerable is NFTokenMetadata, ERC721Enumerable {

    string internal constant INVALID_INDEX = "005007";
    uint256[] internal tokens;
    mapping(uint256 => uint256) internal idToIndex;
    mapping(address => uint256[]) internal ownerToIds;
    mapping(uint256 => uint256) internal idToOwnerIndex;

    constructor() {
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
    }
    function totalSupply() external override view returns (uint256) {
        return tokens.length;
    }
    function tokenByIndex(uint256 _index) external override view returns (uint256) {
        require(_index < tokens.length, "INVALID_INDEX");
        return tokens[_index];
    }
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external override view returns (uint256) {
        require(_index < ownerToIds[_owner].length, "INVALID_INDEX");
        return ownerToIds[_owner][_index];
    }
    function _mint(address _to, uint256 _tokenId) internal override virtual {
        super._mint(_to, _tokenId);
        tokens.push(_tokenId);
        idToIndex[_tokenId] = tokens.length - 1;
    }
    function _burn(uint256 _tokenId) internal override virtual {
        super._burn(_tokenId);
        uint256 tokenIndex = idToIndex[_tokenId];
        uint256 lastTokenIndex = tokens.length - 1;
        uint256 lastToken = tokens[lastTokenIndex];
        tokens[tokenIndex] = lastToken;
        tokens.pop();
        idToIndex[lastToken] = tokenIndex;
        idToIndex[_tokenId] = 0;
    }
    function _removeNFToken(address _from, uint256 _tokenId) internal override virtual {
        require(idToOwner[_tokenId] == _from, "NOT_OWNER");
        delete idToOwner[_tokenId];
        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;
        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }
        ownerToIds[_from].pop();
    }
    function _addNFToken(address _to, uint256 _tokenId) internal override virtual {
        require(idToOwner[_tokenId] == address(0), "NFT_ALREADY_EXISTS");
        idToOwner[_tokenId] = _to;
        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
    }
    function _getOwnerNFTCount(address _owner) internal override virtual view returns (uint256) {
        return ownerToIds[_owner].length;
    }
}

contract ActiveNFToken is NFTokenEnumerable, Ownable {

    using SafeMath for uint256;

    uint256 public totalOnSaleNum;
    uint256[] public totalOnSaleIds;
    mapping(uint256 => uint256) public idTotalOnSaleIndex;

    mapping(uint256 => bool) public idToIsOnSale;
    mapping(uint256 => uint256) public idToLastBuyTime;
    mapping(uint256 => uint256) public idToCurrentPrice;
    mapping(uint256 => uint256) public idToTradeTimes;
    
    mapping(address => address[]) public membersOf;
    mapping(address => address) public inviterOf;
    mapping(address => uint256) public inviteTotalOf;
    mapping(address => uint256) public tradeTimesOf;
    mapping(address => uint256) public tradeVolumeOf;
    mapping(address => uint256) public TeamsVolumeOf;
    
    uint256 public totalPlayer;
    uint256 public activePlayer;
    uint256 public totalTradeTimes;
    uint256 public totalTradeVolume;

    uint256 public lockedTime = 60;
    uint256 public maxHolding = 1;
    uint256 public activeTrade = 1;
    uint256 public permillSeller = 15;
    uint256 public permillReferrer = 5;
    uint256 public permillBonusPool = 5;
    uint256 public permillTechnology = 5;
    
    address public technologyAddress = 0xEe377D775C09B46A3a5Cb154a3DBD8a4e108D41e;
    address public usdtContractAddress = 0x28B38989E5a213801d86a60649D3BAF9abb05141; // Goerli Testnet USDT

    event Register(address indexed _newPlayer, address indexed _inviter);
    event Buy(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Sell(address indexed _from, uint256 indexed _tokenId);
    event Mint(address indexed _to, uint256 indexed _tokenId, uint256 _price, string _uri);
    event Burn(address indexed _from, uint256 indexed _tokenId);
    
    constructor() {
        nftName = "APE NFT CLUB";
        nftSymbol = "ANC";
        inviterOf[owner] = address(this);
    }
    function totalOnSale() external view returns (uint256) {
        return totalOnSaleIds.length;
    }
    function totalInviteOf(address inviter) external view returns (uint256) {
        return membersOf[inviter].length;
    }
    function register(address _inviter) external {
        require(inviterOf[_inviter] != address(0), "INVITER_NOT_EXISTS");
        require(inviterOf[msg.sender] == address(0), "PLAYER_ALREADY_EXISTS");
        totalPlayer += 1;
        inviteTotalOf[_inviter] += 1;
        inviterOf[msg.sender] = _inviter;
        membersOf[_inviter].push(msg.sender);
        emit Register(msg.sender, _inviter);
    }
    function buy(uint256 _tokenId) external {

        require(inviterOf[msg.sender] != address(0), "PLAYER_NOT_EXISTS");
        require(idToIsOnSale[_tokenId] == true, "CAN_NOT_TO_SALE");
        require(idToLastBuyTime[_tokenId] < block.timestamp, "NOT_TIME_TO_SALE");

        uint256 oldPrice = idToCurrentPrice[_tokenId];
        uint256 wadReferrer = oldPrice.div(1000).mul(permillReferrer);
        uint256 wadBonusPool = oldPrice.div(1000).mul(permillBonusPool);
        uint256 wadTechnology = oldPrice.div(1000).mul(permillTechnology);
        uint256 wadSellPlayer = oldPrice.sub(wadReferrer).sub(wadBonusPool).sub(wadTechnology);

        ERC20 usdtContract = ERC20(address(usdtContractAddress));

        usdtContract.transferFrom(msg.sender, tradeTimesOf[inviterOf[msg.sender]] >= activeTrade ? inviterOf[msg.sender] : technologyAddress, wadReferrer);
        usdtContract.transferFrom(msg.sender, address(this), wadBonusPool);
        usdtContract.transferFrom(msg.sender, technologyAddress, wadTechnology);
        usdtContract.transferFrom(msg.sender, idToOwner[_tokenId], wadSellPlayer);

        uint256 permillTotal = permillSeller.add(permillReferrer).add(permillBonusPool).add(permillTechnology);

        uint256 lastTokenId = idTotalOnSaleIndex[totalOnSaleIds.length - 1];
        uint256 thisTokenIndex = idTotalOnSaleIndex[_tokenId];
        totalOnSaleIds[thisTokenIndex] = lastTokenId;
        idTotalOnSaleIndex[_tokenId] = thisTokenIndex;
        totalOnSaleIds.pop();
        totalOnSaleNum -= 1;

        idToIsOnSale[_tokenId] = false;
        idToLastBuyTime[_tokenId] = block.timestamp + lockedTime;
        idToCurrentPrice[_tokenId] = oldPrice.add(oldPrice.div(1000).mul(permillTotal));
        idToTradeTimes[_tokenId] += 1;

        ERC721 thisContract = ERC721(address(this));
        thisContract.safeTransferFrom(idToOwner[_tokenId], msg.sender, _tokenId);

        tradeTimesOf[msg.sender] += 1;
        tradeVolumeOf[msg.sender] += oldPrice;
        TeamsVolumeOf[inviterOf[msg.sender]] += oldPrice;

        activePlayer += 1;
        totalTradeTimes += 1;
        totalTradeVolume += oldPrice;

        emit Buy(idToOwner[_tokenId], msg.sender, _tokenId);
    }
    function sell(uint256 _tokenId) external {
        require(inviterOf[msg.sender] != address(0), "PLAYER_NOT_EXISTS");
        require(idToIsOnSale[_tokenId] == false, "ALREADY_ON_SALE");
        require(idToLastBuyTime[_tokenId] < block.timestamp, "NOT_TIME_TO_SALE");
        totalOnSaleIds.push(_tokenId);
        totalOnSaleNum += 1;
        idTotalOnSaleIndex[_tokenId] = totalOnSaleIds.length - 1;
        idToIsOnSale[_tokenId] = true;
        emit Sell(msg.sender, _tokenId);
    }
    function _transfer(address _to, uint256 _tokenId) internal override {
        require(ownerToNFTokenCount[_to] < maxHolding, "OVER_TO_MAX_HOLDING");
        require(idToIsOnSale[_tokenId] == false, "CAN_NOT_TRANSFER_ON_SALE");
        super._transfer(_to, _tokenId);
    }
    function _removeNFToken(address _from, uint256 _tokenId) internal override {
        super._removeNFToken(_from,_tokenId);
        ownerToNFTokenCount[_from] -= 1;
    }
    function _addNFToken(address _to, uint256 _tokenId) internal override {
        super._addNFToken(_to, _tokenId);
        ownerToNFTokenCount[_to] += 1;
    }
    function mint(address _to, uint256 _tokenId, uint256 _price, string calldata _uri) external onlyOwner {
        idToIsOnSale[_tokenId] = false;
        idToLastBuyTime[_tokenId] = block.timestamp + lockedTime;
        idToCurrentPrice[_tokenId] = _price;
        idToTradeTimes[_tokenId] = 0;
        super._mint(_to, _tokenId);
        super._setTokenUri(_tokenId, _uri);
        emit Mint(_to, _tokenId, _price, _uri);
    }
    function burn(uint256 _tokenId) external onlyOwner {
        super._burn(_tokenId);
        emit Burn(idToOwner[_tokenId] , _tokenId);
    }
    function awardUSDT(address _to, uint256 _value) external onlyOwner {
        ERC20 usdtContract = ERC20(address(usdtContractAddress));
        usdtContract.transfer(_to, _value);
    }
    function setLockedTime(uint256 _lockedTime) external onlyOwner {
        lockedTime = _lockedTime;
    }
    function setMaxHolding(uint256 _maxHolding) external onlyOwner {
        maxHolding = _maxHolding;
    }
    function setActiveTrade(uint256 _activeTrade) external onlyOwner {
        activeTrade = _activeTrade;
    }
    function setPermillSeller(uint256 _permillSeller) external onlyOwner {
        permillSeller = _permillSeller;
    }
    function setPermillReferrer(uint256 _permillReferrer) external onlyOwner {
        permillReferrer = _permillReferrer;
    }
    function setPermillBonusPool(uint256 _permillBonusPool) external onlyOwner {
        permillBonusPool = _permillBonusPool;
    }
    function setPermillTechnology(uint256 _permillTechnology) external onlyOwner {
        permillTechnology = _permillTechnology;
    }
    function setTechnologyAddress(address _technologyAddress) external onlyOwner {
        technologyAddress = _technologyAddress;
    }
    function setUsdtContractAddresse(address _usdtContractAddress) external onlyOwner {
        usdtContractAddress = _usdtContractAddress;
    }
    function setTokenPrice(uint256 _tokenId, uint256 _newPrice) external onlyOwner {
        idToCurrentPrice[_tokenId] = _newPrice;
    }
    function setTokenUri(uint256 _tokenId, string memory _uri) external onlyOwner {
        _setTokenUri(_tokenId, _uri);
    }
}