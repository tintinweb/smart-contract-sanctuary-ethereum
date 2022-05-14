// SPDX-License-Identifier: MIT

// Created by Russ
// Wizardry Tools Master Contract

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract GingerbreadMen is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI = "http://localhost/metadata/4/";
  uint256 public cost = 0.1 ether;
  uint256 public presaleCost = 0.05 ether;
  uint256 public maxSupply = 100;
  uint256 public maxMintsPresale = 2;
  uint256 public maxMintsPublic = 5;

  bool public paused = true;
  bool public presalePaused = true;

  mapping(address => bool) public presaleAllowed;
  mapping(address => uint256) internal minted;

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
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintsPublic);
    require(supply + _mintAmount <= maxSupply);
    require(balanceOf(_to) + _mintAmount < maxMintsPublic);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function mintPresale(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!presalePaused);
    require(_mintAmount > 0); 
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(presaleAllowed[msg.sender] == true);
      require(balanceOf(_to) + _mintAmount <= maxMintsPresale);
      require(msg.value >= presaleCost * _mintAmount);
      require(_mintAmount <= maxMintsPresale);
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
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
      "ERC721Metadata: URI query for nonexistent token"
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

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function pausePresale(bool _state) public onlyOwner {
    presalePaused = _state;
  }
 
 function presaleUser(address _user) public onlyOwner {
    presaleAllowed[_user] = true;
  }
 
  function removePresaleUser(address _user) public onlyOwner {
    presaleAllowed[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}