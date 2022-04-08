// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract SCTest is Ownable, ERC721A, ReentrancyGuard {
  uint256 public maxPerAddressDuringMint;
  uint256 public maxMintPerTx;
  uint256 public freeMintAmount;

  struct SaleConfig {
    uint64 publicPrice;
  }

  SaleConfig public saleConfig;

  constructor(
    uint256 maxMintPerTx_,
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 freeMintAmount_
  ) ERC721A("SCTest", "SCTEST", maxBatchSize_, collectionSize_) {
    maxMintPerTx = maxMintPerTx_;
    maxPerAddressDuringMint = maxBatchSize_;
    freeMintAmount = freeMintAmount_;
    require(
      freeMintAmount <= collectionSize_,
      "larger collection size needed"
    );
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function setMaxMintPerTx(uint256 quantity) external onlyOwner {
    maxMintPerTx = quantity;
  }

  function setMaxPerAddressDuringMint(uint256 quantity) external onlyOwner {
    maxPerAddressDuringMint = quantity;
  }

  function setFreeMintAmount(uint256 quantity) external onlyOwner {
    freeMintAmount = quantity;
  }

  function Mint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    SaleConfig memory config = saleConfig;
    uint256 publicPrice = uint256(config.publicPrice);

    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
        quantity <= maxMintPerTx,
        "can not mint this many"
    );
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );//freeMintAmount
    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * freeMintAmount < (totalSupply() + quantity) ? (freeMintAmount < totalSupply() ? quantity : quantity - (freeMintAmount - totalSupply())) : 0);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function setPublicPrice(
    uint64 publicPriceWei
  ) external onlyOwner {
    saleConfig = SaleConfig(
      publicPriceWei
    );
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
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