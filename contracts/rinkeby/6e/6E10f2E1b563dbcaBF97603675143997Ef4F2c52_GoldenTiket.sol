// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract GoldenTiket is Ownable {
  string private _name;
  string private _symbol;
  string private _baseURIext;
  uint private _tokenIDs = 0;

  mapping(uint => address) private _owners;
  mapping(address => uint) private _balances;
  mapping(uint => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;
  mapping(uint => string) private _tokenURIs;

  event ApproveAll(address _from, address _to);
  event Approval(address _from, address _to, uint _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event Transfer(address _from, address _to, uint _tokenId);

  constructor(string memory nm, string memory smbl, string memory baseUri) {
    _name = nm;
    _symbol = smbl;
    _baseURIext = baseUri;
  }

  function _exists(uint tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _isCanSpend(address _spender, uint _tokenId) private view returns(bool) {
    address owner = ownerOf(_tokenId);
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  function _clearApproval(address owner, uint256 tokenId) internal {
    require(ownerOf(tokenId) == owner, "ERC721: owner dont have this token");
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }
  
  function baseURI() public view returns (string memory) {
    return _baseURIext;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    string memory _tokenURI = _tokenURIs[tokenId];
    string memory base = baseURI();

    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }

    return string(abi.encodePacked(base, tokenId));
  }

  function setBaseURI(string memory baseURI_) public onlyOwner returns(bool) {
      _baseURIext = baseURI_;
      return true;
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
    _tokenURIs[tokenId] = _tokenURI;
  }

  function balanceOf(address _owner) public view returns(uint) {
    return _balances[_owner];
  }

  function ownerOf(uint _tokenId) public view returns(address) {
    return _owners[_tokenId];
  }

  function transferFrom(address _from, address _to, uint _tokenId) public   {
    bool allowance = _isCanSpend(msg.sender, _tokenId);
    address owner = ownerOf(_tokenId);

    require(allowance, "ERC721: you can't spend this");
    
    _balances[_from] -= 1;
    _balances[_to] += 1;
    _clearApproval(owner, _tokenId);
    _owners[_tokenId] = _to;

    emit Transfer(_from, _to, _tokenId);
  }
  
  function approve(address _to, uint _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(msg.sender == owner, "ERC721: you not token owner");
    require(_to != owner, "ERC721: you can't approve yourself");
    
    _tokenApprovals[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  function getApproved(uint _tokenId) public view returns(address) {
    return _tokenApprovals[_tokenId];
  }

  function setApprovalForAll(address _operator, bool _approved) public {
    require(_operator != msg.sender, "you're cant approve for yourself");
    _operatorApprovals[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function isApprovedForAll(address _owner, address _operator) public view returns(bool) {
    return  _operatorApprovals[_owner][_operator];
  }

  function _mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(!_exists(_tokenId), "ERC721: token already minted");

        _balances[_to] += 1;
        _owners[_tokenId] = _to;
  }
  
  function mintToken(address _to, string memory _uri) public {
      _mint(_to, _tokenIDs);
      _setTokenURI(_tokenIDs, _uri);
      _tokenIDs += 1;
      emit Transfer(address(0), _to, _tokenIDs);
  }
}