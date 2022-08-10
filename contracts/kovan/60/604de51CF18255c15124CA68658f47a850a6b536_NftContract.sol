/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function totalSupply() external view returns (uint256 total);
    function name() external view returns (string memory tokenName);
    function symbol() external view returns (string memory tokenSymbol);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transfer(address to, uint256 tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

contract Config{
    using SafeMath for uint256;

    // 白名单
    mapping(address => uint8) private _whiteList;
    address private _owner;
    bool public isNeedWhiteList;
    uint256 public minMintFee;
    // 通过修改配置来实现阶段
    uint256 public maxMintNum;
    // 个人最多拥有token数量
    uint256 public maxOwnNum;
    // 白名单最多铸造数
    uint8 public whiterMaxMintNum;
    string internal _tokenURIPrefix = "ipfs://QmXmuSenZRnofhGMz2NyT3Yc4Zrty1TypuiBKDcaBsNw9V/";
    string internal _tokenURISuffix = ".gif";

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        isNeedWhiteList = true;
        minMintFee = 1_000_000_000_000_000;
        maxMintNum = 3000;
        maxOwnNum = 1000;
        whiterMaxMintNum = 2;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "sender not contract owner");
        _;
    }

    modifier onlyCreator() {
        if (isNeedWhiteList){
            uint8 value = _whiteList[msg.sender];
            require(value > 0, "sender not whiteList or exceed the limit");
            _whiteList[msg.sender] = value - 1;
            _;
        }else{
            _;
        }
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "zero address");
        _;
    }

    function numOfWhiteListMint(address _addr) external view returns (uint8){
        return _whiteList[_addr];
    }

    function addCreator(address[] memory _addrs) external onlyOwner{
        uint256 i;
        for(i = 0; i < _addrs.length - 1; i++){
            require(_addrs[i] != address(0), "zero address");
            _whiteList[_addrs[i]] = whiterMaxMintNum;
        }
    }

    function closeCreator() external onlyOwner{
        isNeedWhiteList = false;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner notZeroAddress(newOwner){
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }

    function updateMinMintFee(uint256 _value) external onlyOwner{
        minMintFee = _value;
    }

    function updateMaxMintNum(uint256 _value) external onlyOwner{
        maxMintNum = _value;
    }

    function updateMaxOwnNum(uint _value) external onlyOwner{
        maxOwnNum = _value;
    }

    function updateTokenURIPrefix(string memory _data) external onlyOwner {
        _tokenURIPrefix = _data;
    }

    function updateTokenURISuffix(string memory _data) external onlyOwner {
        _tokenURISuffix = _data;
    }
}

contract NftContract is IERC721, Config{
    using SafeMath for uint256;

    string[] internal tokens;
    string private _tokenName = "Token";
    string private _tokenSymbol = "TOKEN";

    bytes4 internal constant MAGIC_ERC721_RECEIVED =
        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    bytes4 _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 _INTERFACE_ID_ERC721 = 0x80ac58cd;


    uint256 public ethAmount;

    mapping(uint256 => address) internal tokenToOwner;
    mapping(address => uint256) internal ownerTokenCount;
    mapping(uint256 => address) public tokenToApproved;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event Mint(address indexed to);

    // constructor(string memory tokenName_, string memory tokenSymbol_) {
    //     _tokenName = tokenName_;
    //     _tokenSymbol = tokenSymbol_;
    //     tokens.push("Genesis token");
    // }
    constructor() {
        tokens.push("Genesis token");
    }

    modifier allowMint() {
        require(tokens.length - 1 < maxMintNum, "out of allowable range");
        _;
    }

    modifier allowFee(uint256 _value) {
        require(_value >= minMintFee, "mint fee too little");
        _;
    }

    modifier allowOwnToken(address _addr) {
        require(ownerTokenCount[_addr] < maxOwnNum, "possession limit reached");
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(_tokenId < tokens.length, "invalid tokenId");
        _;
    }

    modifier onlyApproved(uint256 _tokenId) {
        require(isTokenOwner(_tokenId) || isApproved(_tokenId) || isApprovedOperatorOf(_tokenId), "sender not token owner OR approved");
        _;
    }

    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        return (_interfaceId == _INTERFACE_ID_ERC165 ||
            _interfaceId == _INTERFACE_ID_ERC721);
    }

    function setTokenURI(uint256 _tokenId, string memory _data) external onlyOwner validTokenId(_tokenId) {
        tokens[_tokenId] = _data;
    } 

    function tokenURI(uint256 _tokenId) external view validTokenId(_tokenId) returns (string memory) {
        return string(abi.encodePacked(_tokenURIPrefix, tokens[_tokenId], _tokenURISuffix));
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return ownerTokenCount[owner];
    }

    function totalSupply() external view override returns (uint256) {
        return tokens.length - 1;
    }

    function name() external view override returns (string memory) {
        return _tokenName;
    }

    function symbol() external view override returns (string memory) {
        return _tokenSymbol;
    }

    function ownerOf(uint256 _tokenId) external view override validTokenId(_tokenId) returns (address) {
        return _ownerOf(_tokenId);
    }

    function _ownerOf(uint256 _tokenId) internal view returns (address) {
        return tokenToOwner[_tokenId];
    }

    function isTokenOwner(uint256 _tokenId) public view returns (bool) {
        return msg.sender == _ownerOf(_tokenId);
    }

    function isApproved(uint256 _tokenId) public view returns (bool) {
        return msg.sender == tokenToApproved[_tokenId];
    }

    function transfer(address _to, uint256 _tokenId) external override onlyApproved(_tokenId) notZeroAddress(_to) allowOwnToken(_to) {
        require(_to != address(this), "to contract address");

        _transfer(msg.sender, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        tokenToOwner[_tokenId] = _to;
        ownerTokenCount[_to] = ownerTokenCount[_to].add(1);

        if (_from != address(0)) {
            ownerTokenCount[_from] = ownerTokenCount[_from].sub(1);
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override onlyApproved(_tokenId) {
        tokenToApproved[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view override validTokenId(_tokenId) returns (address) {
        return tokenToApproved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return _isApprovedForAll(_owner, _operator);
    }

    function _isApprovedForAll(address _owner, address _operator) internal view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function isApprovedOperatorOf(uint256 _tokenId) public view returns (bool) {
        return _isApprovedForAll(tokenToOwner[_tokenId], msg.sender);
    }

    function _safeTransfer(address _from, address _to, uint256 _tokenId, bytes memory _data) internal {
        _transfer(_from, _to, _tokenId);
        require(_checkERC721Support(_from, _to, _tokenId, _data));
    }

    function _checkERC721Support(address _from, address _to, uint256 _tokenId, bytes memory _data) internal returns (bool) {
        if (!_isContract(_to)) {
            return true;
        }

        //call onERC721Recieved in the _to contract
        bytes4 result = IERC721Receiver(_to).onERC721Received(
            msg.sender,
            _from,
            _tokenId,
            _data
        );

        //check return value
        return result == MAGIC_ERC721_RECEIVED;
    }

    function _isContract(address _to) internal view returns (bool) {
        // wallets will not have any code but contract must have some code
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        return size > 0;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override onlyApproved(_tokenId) notZeroAddress(_to) allowOwnToken(_to) {
        _safeTransfer(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override onlyApproved(_tokenId) notZeroAddress(_to) allowOwnToken(_to) {
        _safeTransfer(_from, _to, _tokenId, bytes(""));
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external override onlyApproved(_tokenId) notZeroAddress(_to) allowOwnToken(_to) {
        _transfer(_from, _to, _tokenId);
    }

    // function mint(address _to, string memory _metadata) external payable override onlyCreator notZeroAddress(_to) allowMint() allowValue(msg.value) {
    //     tokens.push(_metadata);
    //     ethAmount += msg.value;
    //     uint256 newTokenId = tokens.length - 1;
    //     tokenToOwner[newTokenId] = _to;
    //     ownerTokenCount[_to] = ownerTokenCount[_to].add(1);

    //     emit Mint(_to, _metadata);
    // }

    function mint() external payable onlyCreator allowMint allowFee(msg.value) allowOwnToken(msg.sender) {
        tokens.push("0");
        ethAmount += msg.value;
        uint256 newTokenId = tokens.length - 1;
        tokenToOwner[newTokenId] = msg.sender;
        ownerTokenCount[msg.sender] = ownerTokenCount[msg.sender].add(1);

        emit Mint(msg.sender);
    }

    function getEth() external payable onlyOwner {
        ethAmount = 0;
        payable(msg.sender).transfer(ethAmount);
    }
}