/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// File: contracts/erc721.sol
interface ERC721
{

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );


  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;


  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;


  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;


  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);


  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

// File: contracts/Ownable.sol
/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor()  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns(address) {
    return _owner;
  }


  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/erc721-token-receiver.sol
/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver
{
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}

// File: contracts/nf-token.sol
contract OGT is
  ERC721,
  Ownable
{
  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";

  // Next mint ID
  uint256 public nextMintID;
  //Actual max mint number
  uint256 public ACT_MAX_MINT;

  //Pirce -> 0 eth for starter
  uint256 private _price = 0.0 ether;

  string baseURI;
  string _symbol;
  string _name;
  
  // Open / close minting
  bool public isMintWindowOpen;

  // Is transfer locked
  bool public transfersLocked;

  /**
   * @dev Magic value of a smart contract that can recieve NFT.
   * Equal to: keccak256("onERC721Received(address,uint256,bytes)").
   */
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  // For minting
  mapping (uint256 => address) internal idToOwner;
  // Check if minted already.. Could be handled in the same array like
  // id to owner, but problem is that in case in the future we want to enable
  // secondary sales, we need to have a clean idToOwner mapping.
  mapping (address => bool) internal mintedAlready;

  // In case in future we decide to open up secondary ( ? )
  mapping (uint256 => address) internal idToApproval;
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  // balaceOf mapping
  mapping (address => uint256) internal ownerToNFTokenCount;

  //Supports interface -> ERC721
  mapping(bytes4 => bool) internal supportedInterfaces;

  //=============================//
  //          Modifiers          //
  //=============================//

  modifier transferIsNotLocked()
  {
    require(!transfersLocked, "OG 401 - Transfer is locked!");
    _;
  }

  modifier canOperate(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_OR_OPERATOR
    );
    _;
  }

  modifier canTransfer(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
    _;
  }

  //======================================//
  //     Implement Supports interface     //
  //======================================//
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

  //========================//
  //    Contract calls     //
  //========================//
  constructor(uint256 max_mint)
  {
    _name = "OLYMPUS";
    _symbol = "OGT";
    setBaseTokenURI("");
    supportedInterfaces[0x80ac58cd] = true; // ERC721
    isMintWindowOpen = true;
    nextMintID = 0;
    ACT_MAX_MINT = max_mint;
    transfersLocked = true;
  }

  //Open / close
  function openCloseMint(bool _status) external onlyOwner{
      isMintWindowOpen = _status;
  }

  // Change max minting nr.
  function openCloseMint(uint256 _newMAX) external onlyOwner{
    require(_newMAX > ACT_MAX_MINT, "OG 406 - MAX cannot be lower than previous MAX");
    ACT_MAX_MINT = _newMAX;
  }

  //Lock vs. unlock. Possible way to openUp secondary sales
  function lockUnlockTransfers(bool _status) external onlyOwner{
      transfersLocked = _status;
  }

  function setBaseTokenURI(string memory _baseURI) public onlyOwner{
      baseURI = _baseURI;
  }

  function name() external view returns (string memory name_ret){
      return _name;
  }

  function symbol() external view returns (string memory symbol_ret){
      return _symbol;
  }

  function totalSupply() external view returns(uint256){
      return nextMintID;
  }

  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    require(tokenId <= nextMintID, "ERC721: URI query for nonexistent token");
    return string(abi.encodePacked(baseURI, uint2str(tokenId), ".json"));
  }

  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    _addNFToken(_to, _tokenId);
    nextMintID += 1;
    emit Transfer(address(0), _to, _tokenId);
  }

  function claim() external payable{
    require (isMintWindowOpen, "OG 402 - Mint window is not open");
    require (nextMintID < ACT_MAX_MINT, "OG 403 - Sold out");
    require (msg.value >= _price, "OG 404 - Not enought ethereum" );
    require (!mintedAlready[msg.sender], "OG 405 - User already minted");

    _mint(msg.sender,nextMintID);
    mintedAlready[msg.sender] = true;
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }

  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    override
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, IS_OWNER);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
    override
  {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function balanceOf(
    address _owner
  )
    external
    override
    view
    returns (uint256)
  {
    require(_owner != address(0), ZERO_ADDRESS);
    return _getOwnerNFTCount(_owner);
  }

  function ownerOf(
    uint256 _tokenId
  )
    external
    override
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }

  function getApproved(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApproval[_tokenId];
  }

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    override
    view
    returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }

  function _transfer(
    address _to,
    uint256 _tokenId
  )
    internal transferIsNotLocked()
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }


  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    ownerToNFTokenCount[_from] -= 1;
    delete idToOwner[_tokenId];
  }

  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] += 1;
  }


  function _getOwnerNFTCount(
    address _owner
  )
    internal
    virtual
    view
    returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }

  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    private
    transferIsNotLocked()
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    if (isContract(_to))
    {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  function _clearApproval(
    uint256 _tokenId
  )
    private
  {
    delete idToApproval[_tokenId];
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
  }

  // In case there is / will be a balance
  function withdraw(address payable recipient) public onlyOwner {
      uint256 balance = address(this).balance;
      recipient.transfer(balance);
  }

  function setPrice(uint256 _newPrice) public onlyOwner() {
      _price = _newPrice;
  }

  function getPrice() public view returns (uint256){
      return _price;
  }

  //If address is contract
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }
}