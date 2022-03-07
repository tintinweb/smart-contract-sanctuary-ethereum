/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
interface ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _approved, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC721Metadata {
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract Avatar is ERC721, ERC721Metadata {

  string private _name;
  string private _symbol;

  mapping(address => uint256) private _balances;
  mapping(uint256 => address) private _owners;
  mapping(uint256 => address) private _approvals;
  mapping(uint256 => string) private _tokenURIs;

  address private _owner;

  modifier onlyOwner() {
    require(owner() == msg.sender, "ownable: caller is not the owner");
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }
 
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
    _owner = msg.sender;
    _balances[msg.sender] += 1;
    _owners[0] = msg.sender;
  }

  function name() external view override returns (string memory) {
    return _name;
  }

  function symbol() external view override returns (string memory) {
    return _symbol; 
  }

  function tokenURI(uint256 _tokenId) external view override returns (string memory) {
    return _tokenURIs[_tokenId];
  }

  function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
    _tokenURIs[_tokenId] = _tokenURI;
  }

  function balanceOf(address _owner) public view override returns (uint256) {
    return _balances[_owner]; 
  }

  function ownerOf(uint256 _tokenId) external view override returns (address) {
    return _owners[_tokenId]; 
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable override {

  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable override {

  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external payable override {
    
  }

  function approve(address _approved, uint256 _tokenId) external payable override {

  }

  function setApprovalForAll(address _operator, bool _approved) external override {
    
  }

  function getApproved(uint256 _tokenId) external view override returns (address) {
    return _approvals[_tokenId];
  }

  function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {

  }
}