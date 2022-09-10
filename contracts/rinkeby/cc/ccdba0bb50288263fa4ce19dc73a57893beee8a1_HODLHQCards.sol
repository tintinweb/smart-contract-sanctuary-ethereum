// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract HODLHQCards is ERC721, Ownable {
  using Strings for uint256;
 
  string public baseURI;
  string public baseExtension = '';
  uint256 public maxSupply = 10000;
  uint256 public totalSupply = 0;
  uint256 public maxMintAmount = 5;
  uint256 public price = 0.001 ether;
  bool public paused = false;

  constructor(
    string memory _initBaseURI
  ) ERC721("TESTNFT", "NFT") {
    setBaseURI(_initBaseURI);
  }
 
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public 
  // add subdomain array and check if mint amount == subdomain.length
  function mint(address _to, uint256 _mintAmount, string calldata subDomain) payable external {
    require(_mintAmount > 0);
    require(totalSupply + _mintAmount <= maxSupply);
 
    if (msg.sender != owner()) {
      require(!paused);
      require(_mintAmount <= maxMintAmount);
      require(msg.value >= price * _mintAmount);
    }
 
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _mint(_to, totalSupply + i);
      ENSresolver.createSubdomain(subDomain, totalSupply + 1);
    }
    totalSupply += _mintAmount;
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);
      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }
 
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");
 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
 
  //only owner
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setMaxMint(uint256 _maxMint) public onlyOwner {
    maxMintAmount = _maxMint;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }

  function setENSResolver(address newResolver) public onlyOwner {
    ENSresolver = resolver(newResolver);
  }

  function withdraw() external onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}