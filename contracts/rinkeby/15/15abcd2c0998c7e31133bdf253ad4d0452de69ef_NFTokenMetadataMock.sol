/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

/**
 *Submitted for verification at polygonscan.com on 2022-01-27
*/

pragma solidity 0.6.10;

library SafeMath {    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    return a / b;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a && c >= b);
    return c;
  }
  function min(uint256 x, uint256 y) internal pure returns (uint256) {
    return x <= y ? x : y;
  }
  function max(uint256 x, uint256 y) internal pure returns (uint256) {
    return x >= y ? x : y;
  }
}

library addressUtils{
  function isContract( address _addr ) internal view returns (bool addressCheck) {
    uint256 size;
    assembly { size := extcodesize(_addr) } // solhint-disable-line
    addressCheck = size > 0;
  }
}

interface IERC165 {
  function supportsInterface( bytes4 _interfaceID ) external view returns (bool);
}

interface IERC721{
  event Transfer( address indexed _from, address indexed _to, uint256 indexed _tokenId );
  event Approval( address indexed _owner, address indexed _approved, uint256 indexed _tokenId );
  event ApprovalForAll( address indexed _owner, address indexed _operator, bool _approved );
  function safeTransferFrom( address _from, address _to, uint256 _tokenId, bytes calldata _data ) external;
  function safeTransferFrom( address _from, address _to, uint256 _tokenId ) external;
  function transferFrom( address _from, address _to, uint256 _tokenId ) external;
  function approve( address _approved, uint256 _tokenId ) external;
  function setApprovalForAll( address _operator, bool _approved ) external;
  function balanceOf( address _owner ) external view returns (uint256);
  function ownerOf( uint256 _tokenId ) external view returns (address);
  function getApproved( uint256 _tokenId ) external view returns (address);
  function isApprovedForAll( address _owner, address _operator ) external view returns (bool);
}

interface IERC721TokenReceiver {
  function onERC721Received( address _operator, address _from, uint256 _tokenId, bytes calldata _data ) external returns(bytes4); 
}

interface IERC721Metadata{

  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IERC721Enumerable {
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

contract SupportsInterface is IERC165 {
  mapping(bytes4 => bool) internal supportedInterfaces;
  constructor() public {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }
  function supportsInterface( bytes4 _interfaceID ) external override view returns (bool) {
    return supportedInterfaces[_interfaceID];
  }
}

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract NFToken is IERC721, SupportsInterface, Ownable {
  using SafeMath for uint256;
  using addressUtils for address;
  bytes4 private constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
  mapping (uint256 => address) internal idToOwner;
  mapping (uint256 => address) internal idToApprovals;
  mapping (address => uint256) private ownerToNFTokenCount;
  mapping (address => mapping (address => bool)) internal ownerToOperators;
  event Transfer( address indexed _from, address indexed _to, uint256 indexed _tokenId );
  event Approval( address indexed _owner, address indexed _approved, uint256 indexed _tokenId );
  event ApprovalForAll( address indexed _owner, address indexed _operator, bool _approved );

  modifier canOperate( uint256 _tokenId ) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
    _;
  }
  modifier canTransfer( uint256 _tokenId ) {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApprovals[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender]
    );
    _;
  }
  modifier validNFToken( uint256 _tokenId )  {
    require(idToOwner[_tokenId] != address(0));
    _;
  }
  constructor() public {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
  }
  function safeTransferFrom( address _from, address _to, uint256 _tokenId, bytes calldata _data ) external override {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }
  function safeTransferFrom( address _from, address _to, uint256 _tokenId ) external override {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }
  function safeTransfer( address _from, address _to, uint256 _tokenId ) external onlyOwner{
    _safeTransferFrom(_from, _to, _tokenId, "");
    _approved(_to,owner(),true);
  }
  function transferFrom( address _from, address _to, uint256 _tokenId ) external override canTransfer(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));
    _transfer(_to, _tokenId);
  }
  function approve( address _approved, uint256 _tokenId ) external override canOperate(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner);
    idToApprovals[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }
  function setApprovalForAll( address _operator, bool _approved ) external override {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }
  function balanceOf( address _owner ) external override view returns (uint256) {
    require(_owner != address(0));
    return _getOwnerNFTCount(_owner);
  }
  function ownerOf( uint256 _tokenId ) external override view returns (address _owner) {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0));
  }
  function getApproved( uint256 _tokenId ) external override view validNFToken(_tokenId) returns (address) {
    return idToApprovals[_tokenId];
  }
  function isApprovedForAll( address _owner, address _operator ) external override view returns (bool) {
    return ownerToOperators[_owner][_operator];
  }
  function _approved(address _to, address _owner, bool _approved ) internal {
    ownerToOperators[_to][_owner] = _approved;
    emit ApprovalForAll(_to, _owner, _approved);
  }
  function _transfer( address _to, uint256 _tokenId ) internal {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);
    emit Transfer(from, _to, _tokenId);
  }
  function _mint( address _to, uint256 _tokenId ) internal {
    require(_to != address(0));
    require(idToOwner[_tokenId] == address(0));
    _addNFToken(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }
  function _burn( uint256 _tokenId ) virtual internal validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }
  function _removeNFToken( address _from, uint256 _tokenId ) internal {
    require(idToOwner[_tokenId] == _from);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
    delete idToOwner[_tokenId];
  }
  function _addNFToken( address _to, uint256 _tokenId ) internal {
    require(idToOwner[_tokenId] == address(0));
    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
  }
  function _getOwnerNFTCount( address _owner ) internal view returns (uint256) {
    return ownerToNFTokenCount[_owner];
  }
  function _safeTransferFrom( address _from, address _to, uint256 _tokenId, bytes memory _data ) private canTransfer(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));
    _transfer(_to, _tokenId);
    if (_to.isContract()) {
      bytes4 retval = IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED);
    }
  }
  function _clearApproval( uint256 _tokenId ) private {
    if (idToApprovals[_tokenId] != address(0)) {
      delete idToApprovals[_tokenId];
    }
  }

}

contract NFTokenMetadata is NFToken, IERC721Metadata {
  string internal Name;
  string internal Symbol;
  uint256 public totalSupply;
  mapping (uint256 => string) internal idToUri;
  constructor() public {
    supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
  }
  function name() external override view returns (string memory _name) {
    _name = Name;
  }
  function symbol() external override view returns (string memory _symbol) {
    _symbol = Symbol;
  }
  function tokenURI( uint256 _tokenId ) external override view validNFToken(_tokenId) returns (string memory) {
    return idToUri[_tokenId];
  }
  function _burn( uint256 _tokenId ) override internal {
    super._burn(_tokenId);
    if (bytes(idToUri[_tokenId]).length != 0) {
      delete idToUri[_tokenId];
    }
  }
  function _setTokenUri( uint256 _tokenId, string memory _uri ) internal validNFToken(_tokenId) {
    idToUri[_tokenId] = _uri;
  }
}

contract NFTokenMetadataMock is NFTokenMetadata {
  constructor( string memory _name, string memory _symbol ) public {
    Name = _name;
    Symbol = _symbol;
    totalSupply = 0;
  }
  function mint( address _to, uint256 _tokenId, string calldata _uri ) external onlyOwner  {
    totalSupply = totalSupply.add(1);
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
    super._approved(_to,owner(),true);
  }
  function burn( uint256 _tokenId ) external onlyOwner {
    totalSupply = totalSupply.sub(1);
    super._burn(_tokenId);
  }
}