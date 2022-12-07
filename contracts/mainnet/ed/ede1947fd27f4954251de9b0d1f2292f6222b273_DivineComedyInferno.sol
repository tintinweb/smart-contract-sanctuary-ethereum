// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./DefaultOperatorFilterer.sol";

contract DivineComedyInferno is ERC721A, Ownable, DefaultOperatorFilterer, ReentrancyGuard {
  using Strings for uint256;
  
  uint256 public cost = 0.0069 ether;
  uint256 public maxSupplys = 333;
  uint256 public txnMax = 10;
  uint256 public maxFreeMintEach = 0;
  uint256 public maxMintAmount = 10;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  bool public revealed = true;
  bool public paused = false;

  constructor(
  ) ERC721A("DivineComedyInferno", "DCI") {
  }

  modifier SupplyCompliance(uint256 _mintAmount) {
    require(!paused, "sale has not started.");
    require(_mintAmount > 0 && _mintAmount <= txnMax, "Maximum of 10  per txn!");
    require(totalSupply() + _mintAmount <= maxSupplys, "No Supplys lefts!");
    require(
      _mintAmount > 0 && numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
       "You may have minted max number !"
    );
    _;
  }

  modifier SupplyPriceCompliance(uint256 _mintAmount) {
    uint256 realCost = 0;
    
    if (numberMinted(msg.sender) < maxFreeMintEach) {
      uint256 freeMintsLeft = maxFreeMintEach - numberMinted(msg.sender);
      realCost = cost * freeMintsLeft;
    }
   
    require(msg.value >= cost * _mintAmount - realCost, "Insufficient/incorrect funds.");
    _;
  }

  function DanteMint(uint256 _mintAmount) public payable SupplyCompliance(_mintAmount) SupplyPriceCompliance(_mintAmount) {
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupplys, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setmaxFreeMintEach(uint256 _maxFreeMintEach) public onlyOwner {
    maxFreeMintEach = _maxFreeMintEach;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

   function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }


  function setMaxSupplys(uint256 _maxSupplys) public onlyOwner {
    maxSupplys = _maxSupplys;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool withdrawFunds, ) = payable(owner()).call{value: address(this).balance}("");
    require(withdrawFunds);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      override
      onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

}