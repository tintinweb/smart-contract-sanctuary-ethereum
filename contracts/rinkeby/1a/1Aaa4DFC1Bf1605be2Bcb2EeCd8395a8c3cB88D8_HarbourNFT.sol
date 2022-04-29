/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Address {
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;


      bytes32 accountHash
     = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }
}

library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}

abstract contract AdminRole {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  constructor() {
    _addAdmin(msg.sender);
  }

  modifier onlyAdmin() {
    require(
      isAdmin(msg.sender),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return _admins.has(account);
  }

  function addAdmin(address account) public onlyAdmin {
    _addAdmin(account);
  }

  function renounceAdmin() public {
    _removeAdmin(msg.sender);
  }

  function _addAdmin(address account) internal {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    _admins.remove(account);
    emit AdminRemoved(account);
  }
}

abstract contract MinterRole is AdminRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private _minters;

  constructor() {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(
      isMinter(msg.sender),
      'MinterRole: caller does not have the Minter role'
    );
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return _minters.has(account);
  }

  function addMinter(address account) public onlyAdmin {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    _minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    _minters.remove(account);
    emit MinterRemoved(account);
  }
}

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract IERC721 is IERC165 {
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner)
    public
    view
    virtual
    returns (uint256 balance);

  function ownerOf(uint256 tokenId) public view virtual returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual;

  function approve(address to, uint256 tokenId) public virtual;

  function getApproved(uint256 tokenId)
    public
    view
    virtual
    returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public virtual;

  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual;
}

abstract contract IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  ) public virtual returns (bytes4);
}

abstract contract ERC165 is IERC165 {
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  mapping(bytes4 => bool) private _supportedInterfaces;

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC165);
  }

  function supportsInterface(bytes4 interfaceId)
    external
    view
    override
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

  function _registerInterface(bytes4 interfaceId) internal {
    require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
    _supportedInterfaces[interfaceId] = true;
  }
}

contract ERC721 is ERC165, IERC721 {
  using Address for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  uint256 private _totalSupply;
  mapping(uint256 => address) private _tokenOwner;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => uint256) private _ownedTokensCount;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC721);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), 'ERC721: balance query for the zero address');

    return _ownedTokensCount[owner];
  }

  function ownerOf(uint256 tokenId) public view override returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0), 'ERC721: owner query for nonexistent token');

    return owner;
  }

  function approve(address to, uint256 tokenId) public override {
    address owner = ownerOf(tokenId);
    require(to != owner, 'ERC721: approval to current owner');

    require(
      msg.sender == owner || isApprovedForAll(owner, msg.sender),
      'ERC721: approve caller is not owner nor approved for all'
    );

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), 'ERC721: approved query for nonexistent token');

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address to, bool approved) public override {
    require(to != msg.sender, 'ERC721: approve to caller');

    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(msg.sender, tokenId),
      'ERC721: transfer caller is not owner nor approved'
    );

    _transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    safeTransferFrom(from, to, tokenId, '');
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    require(
      _isApprovedOrOwner(msg.sender, tokenId),
      'ERC721: transfer caller is not owner nor approved'
    );
    _safeTransferFrom(from, to, tokenId, _data);
  }

  function _safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal {
    _transferFrom(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      'ERC721: transfer to non ERC721Receiver implementer'
    );
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    returns (bool)
  {
    require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
    address owner = ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender));
  }

  function _safeMint(address to, uint256 tokenId) internal {
    _safeMint(to, tokenId, '');
  }

  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      'ERC721: transfer to non ERC721Receiver implementer'
    );
  }

  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0), 'ERC721: mint to the zero address');
    require(!_exists(tokenId), 'ERC721: token already minted');

    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to]++;
    _totalSupply++;

    emit Transfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal {
    address owner = _tokenOwner[tokenId];
    _clearApproval(tokenId);
    _totalSupply--;
    _ownedTokensCount[owner]--;
    _tokenOwner[tokenId] = address(0);
    emit Transfer(owner, address(0), tokenId);
  }

  function _transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    require(
      ownerOf(tokenId) == from,
      'ERC721: transfer of token that is not own'
    );
    require(to != address(0), 'ERC721: transfer to the zero address');

    _clearApproval(tokenId);

    _ownedTokensCount[from]--;
    _ownedTokensCount[to]++;

    _tokenOwner[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal returns (bool) {
    if (!to.isContract()) {
      return true;
    }

    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender,
      from,
      tokenId,
      _data
    );
    return (retval == _ERC721_RECEIVED);
  }

  function _clearApproval(uint256 tokenId) private {
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}

abstract contract IERC721Metadata is IERC721 {
  function name() external view virtual returns (string memory);

  function symbol() external view virtual returns (string memory);

  function tokenURI(uint256 tokenId)
    external
    view
    virtual
    returns (string memory);
}

abstract contract ERC721MetadataMintable is
  ERC165,
  ERC721,
  MinterRole,
  IERC721Metadata
{
  string private _name;
  string private _symbol;
  string private _baseURI;
  uint256 private _stringId = 0;
  mapping(uint256 => string) private _stringIdUriMap;
  mapping(uint256 => uint256) private _tokenIdStringIdMap;

  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

  constructor(
    string memory argName,
    string memory argSymbol,
    string memory argBaseURI
  ) {
    _name = argName;
    _symbol = argSymbol;
    _baseURI = argBaseURI;

    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
  }

  function name() external view override returns (string memory) {
    return _name;
  }

  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  function baseURI() external view returns (string memory) {
    return _baseURI;
  }

  function mintWithTokenURI(
    address to,
    uint256 tokenId,
    string memory _tokenURI
  ) public onlyMinter returns (bool) {
    _mint(to, tokenId);
    uint256 stringId = ++_stringId;
    _stringIdUriMap[stringId] = _tokenURI;
    _tokenIdStringIdMap[tokenId] = stringId;
    return true;
  }

  function mintMultipleWithTokenURI(
    address to,
    uint256 startTokenId,
    uint256 count,
    string memory _tokenURI
  ) public onlyMinter returns (bool) {
    uint256 stringId = ++_stringId;
    _stringIdUriMap[stringId] = _tokenURI;

    for (uint256 i = 0; i < count; i++) {
      uint256 tokenId = startTokenId + i;
      _mint(to, tokenId);
      _tokenIdStringIdMap[tokenId] = stringId;
    }
    return true;
  }

  function burn(uint256 tokenId) public returns (bool) {
    require(
      _isApprovedOrOwner(msg.sender, tokenId),
      'ERC721: burn caller is not owner nor approved'
    );
    _burn(tokenId);
    return true;
  }

  function tokenURI(uint256 tokenId)
    external
    view
    override
    returns (string memory)
  {
    string memory _tokenURI = _stringIdUriMap[_tokenIdStringIdMap[tokenId]];
    if (bytes(_tokenURI).length == 0) {
      return '';
    } else {
      return string(abi.encodePacked(_baseURI, _tokenURI));
    }
  }
}

abstract contract Owned is AdminRole {
  address private _owner;

  constructor() {
    _owner = msg.sender;
  }

  function owner() public view returns (address) {
    return _owner;
  }

  function getOwner() public view returns (address) {
    return _owner;
  }

  function setOwner(address newOwner) public onlyAdmin {
    _owner = newOwner;
  }
}

contract HarbourNFT is ERC721MetadataMintable, Owned {
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;
  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
  bytes4 private constant _INTERFACE_ID_ROYALTIES = 0x44c74bcc;
  bytes4 private constant _INTERFACE_ID_RARABLEV2 = 0xcad96cca;

  string private _contractURI;
  address payable private _royaltyReceiver;
  uint256 private _royaltyAmount;
  uint256 private _feeBps;
  uint96 private _royaltyValue;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI,
    string memory argContractURI,
    address payable royaltyReceiver,
    uint256 royaltyAmount,
    uint256 feeBps,
    uint96 royaltyValue
  ) ERC721MetadataMintable(name, symbol, baseURI) {
    _registerInterface(_INTERFACE_ID_CONTRACT_URI);
    _registerInterface(_INTERFACE_ID_ERC2981);
    _registerInterface(_INTERFACE_ID_FEES);
    _registerInterface(_INTERFACE_ID_ROYALTIES);
    _registerInterface(_INTERFACE_ID_RARABLEV2);

    _contractURI = argContractURI;
    _royaltyReceiver = royaltyReceiver;
    _royaltyAmount = royaltyAmount;
    _feeBps = feeBps;
    _royaltyValue = royaltyValue;
  }

  function setContractURI(string memory uri) public onlyAdmin {
    _contractURI = uri;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setRoyaltyReceiver(address payable _addr) public onlyAdmin {
    _royaltyReceiver = _addr;
  }

  function setRoyaltyAmount(uint256 _amount) public onlyAdmin {
    _royaltyAmount = _amount;
  }

  function setFeeBps(uint256 _amount) public onlyAdmin {
    _feeBps = _amount;
  }

  function setRoyaltyValue(uint96 _amount) public onlyAdmin {
    _royaltyValue = _amount;
  }

  function royaltyInfo(uint256, uint256 _value)
    public
    view
    returns (address receiver, uint256 amount)
  {
    return (_royaltyReceiver, (_value * _royaltyAmount) / 10000);
  }

  function getFeeRecipients(uint256)
    public
    view
    returns (address payable[] memory)
  {
    address payable[] memory result = new address payable[](1);
    result[0] = _royaltyReceiver;
    return result;
  }

  function getFeeBps(uint256) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](1);
    result[0] = _feeBps;
    return result;
  }

  struct Part {
    address payable account;
    uint96 value;
  }

  function getRoyalties(uint256) public view returns (Part[] memory) {
    Part[] memory result = new Part[](1);
    result[0].account = _royaltyReceiver;
    result[0].value = _royaltyValue;
    return result;
  }

  function getRaribleV2Royalties(uint256) public view returns (Part[] memory) {
    Part[] memory result = new Part[](1);
    result[0].account = _royaltyReceiver;
    result[0].value = _royaltyValue;
    return result;
  }
}