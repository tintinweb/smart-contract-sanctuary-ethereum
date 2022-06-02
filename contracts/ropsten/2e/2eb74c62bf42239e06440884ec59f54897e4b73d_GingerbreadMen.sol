// SPDX-License-Identifier: MIT

// Created by Russ
// Wizardry Tools Master Contract

pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract GingerbreadMen is ERC721Enumerable, Ownable {
  using Strings for uint256;

  bytes32 public merkleRoot = 0xA0820CF170AD784BA4D5BE1AF1082638A0820CF170AD784BA4D5BE1AF1082638;

  bool public paused = true;
  bool public presalePaused = true;

  mapping(address => uint256) internal minted;
  mapping(address => uint256) internal presaleMinted;

  string public baseURI;
  uint256 public cost = 0.1 ether;
  uint256 public presaleCost = 0.05 ether;
  uint256 public maxSupply = 100;
  uint256 public maxMintsPresale = 2;
  uint256 public maxMintsPublic = 5;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(supply + _mintAmount <= maxSupply);
    require(minted[msg.sender] + _mintAmount <= maxMintsPublic);
    
    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function mintPresale(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
    uint256 supply = totalSupply();
    require(!presalePaused);
    require(_mintAmount > 0);
    require(supply + _mintAmount <= maxSupply);
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    if (msg.sender != owner()) {
      require(presaleMinted[msg.sender] + _mintAmount <= maxMintsPresale);
      require(msg.value >= presaleCost * _mintAmount);
      require(MerkleProof.verify(_merkleProof, merkleRoot, leaf));
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply+ i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERROR: Token not found."
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setPresaleCost(uint256 _newCost) public onlyOwner() {
    presaleCost = _newCost;
  }

  function setMaxSupply(uint256 _newSupply) public onlyOwner() {
    maxSupply = _newSupply;
  }

  function setMaxMintspresale(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintsPresale = _newmaxMintAmount;
  }

  function setMaxMintsPublic(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintsPublic = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
    merkleRoot = _newMerkleRoot;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function pausePresale(bool _state) public onlyOwner {
    presalePaused = _state;
  }
 
  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}