/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Erc721{
    mapping(address => uint256) internal _balanceOf;
    mapping(uint256 => address) internal _ownerOf;
    mapping(uint256 => address) internal _approverOf;
    mapping(address => mapping(address => bool)) _approverOfAll;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    function balanceOf(address _owner) external view returns(uint256){
      require(_owner != address(0), "Invalid address");

      return _balanceOf[_owner];
    } 

    function ownerOf(uint256 _tokenId) public view returns(address){
      address owner = _ownerOf[_tokenId];
      require(owner != address(0), "Invalid token");

      return owner;
    }

    function setApprovalForAll(address _operator, bool _approved) external{
      require(_operator != address(0), "Invalid Address");

      _approverOfAll[msg.sender][_operator] = _approved;
      emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns(bool){
      return _approverOfAll[_owner][_operator];
    }

    function approve(address _approved, uint256 _tokenId) public payable{
      address owner = ownerOf(_tokenId);
      require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Unauthorised");

      _approverOf[_tokenId] = _approved;
      emit Approval(owner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns(address){
      require(_ownerOf[_tokenId ] != address(0), "Inavlid token");

      return _approverOf[_tokenId];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {
      address owner = ownerOf(_tokenId);
      require(_from == owner, "From address is not the owner of token");
      require(msg.sender == _from || msg.sender == getApproved(_tokenId) || isApprovedForAll(_from, msg.sender), "Unauthorised");
      require(_to != address(0), "Invalid to address");

      _ownerOf[_tokenId] = _to;
      delete _approverOf[_tokenId];
      _balanceOf[_from] -= 1;
      _balanceOf[_to] += 1;
      emit Transfer(_from, _to, _tokenId);
    }
    
    function onERC721Received () private pure returns(bool) {
      return true;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable {
      transferFrom(_from, _to, _tokenId);
      require(onERC721Received(), "Receiver not implemented");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
      safeTransferFrom(_from, _to, _tokenId, "");
    }

    function supportsInterface(bytes4 _interfaceId) public pure virtual returns(bool) {
      return _interfaceId == 0x80ac58cd;
    }
}

contract CreateNFTCollection is Erc721{
  string private _name;
  string private _symbol;
  uint256 private _tokenId;
  mapping(uint256 => string) _tokenURIs;
  
  constructor(string memory name_, string memory symbol_){
    _name = name_;
    _symbol = symbol_;
  }

  function name() external view returns(string memory) {
    return _name;
  }

  function symbol() external view returns(string memory) {
    return _symbol;
  }

  function tokenURI(uint256 _tokenId) external view returns (string memory) {
    require(_ownerOf[_tokenId] != address(0), "Invalid Token");

    return _tokenURIs[_tokenId];
  }

  function mint(string memory _tokenURI) external { 
    _balanceOf[msg.sender] += 1;
    _ownerOf[_tokenId] = msg.sender;
    _tokenURIs[_tokenId] = _tokenURI;
    emit Transfer(address(0), msg.sender, _tokenId);

    _tokenId += 1;
  }

  function supportsInterface(bytes4 _interfaceId) public pure override returns(bool) {
      return _interfaceId == 0x80ac58cd || _interfaceId == 0x5b5e139f;
    }
}