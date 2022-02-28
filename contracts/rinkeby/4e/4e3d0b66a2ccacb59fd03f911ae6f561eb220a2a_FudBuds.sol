// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract FudBuds is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddress;
  
  uint256 public maxFreePerTransaction = 3;

  uint256 public maxPerTransaction = 20; 

  uint256 public mintPrice = 0.025 ether;

  bool public mintActive = false;

  string private _baseTokenURI;

  uint256 public maxFreeSupply = 750;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) ERC721A("Fud Frens", "FF", maxBatchSize_, collectionSize_) {
    maxPerAddress = maxBatchSize_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function freeMint(uint256 quantity) external callerIsUser {
    require(mintActive, "mint is not active");
    require(totalSupply() + quantity <= maxFreeSupply, "max supply has been reached");
    require(quantity <= maxFreePerTransaction, "max 3 per transaction");
    _safeMint(msg.sender, quantity);
  }

  function mint(uint256 quantity) external payable callerIsUser {
    require(mintActive, "mint is not active");
    require(totalSupply() + quantity <= collectionSize, "max supply has been reached");
    require( quantity <= maxPerTransaction, "max 20 per address");
    require(msg.value >= mintPrice * quantity, "not enough eth sent");
    _safeMint(msg.sender, quantity);
  }

  function devMint(uint256 quantity) external onlyOwner {
    require(quantity % maxBatchSize == 0,"can only mint a multiple of the maxBatchSize");
    require(totalSupply() + quantity <= collectionSize, "max supply has been reached");
    uint256 numChunks = quantity / maxBatchSize; 
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    require(address(this).balance > 0);
    payable(msg.sender).transfer(address(this).balance);
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function toggleMintActive() external onlyOwner {
    mintActive = !mintActive;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}