// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract SCTest is Ownable, ERC721A, ReentrancyGuard {
  uint256 public maxMintPerWallet;
  uint256 public maxMintPerTx;
  uint256 public totalFreeMints;
  uint256 public freeMintPerWallet;
  uint256 public freeMintPerTx;

  struct SaleConfig {
    uint64 publicPrice;
  }

  SaleConfig public saleConfig;

  constructor(
    uint256 maxMintPerWallet_,
    uint256 collectionSize_
  ) ERC721A("SCTest", "SCTEST", maxMintPerWallet_, collectionSize_) {
    maxMintPerTx = 10;
    maxMintPerWallet = maxMintPerWallet_;
    freeMintPerTx = 2;
    freeMintPerWallet = 2;
    totalFreeMints = 1500;
    saleConfig = SaleConfig(
      0.005 ether
    );
    require(
      freeMintPerWallet <= collectionSize_,
      "larger collection size needed"
    );
    require(
      freeMintPerTx <= freeMintPerWallet,
      "larger free mint per wallet needed"
    );
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function setMaxMintPerTx(uint256 quantity) external onlyOwner {
    maxMintPerTx = quantity;
  }

  function setMaxMintPerWallet(uint256 quantity) external onlyOwner {
    maxMintPerWallet = quantity;
  }

  function setFreeMintPerWallet(uint256 quantity) external onlyOwner {
    freeMintPerWallet = quantity;
  }

  function Mint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    SaleConfig memory config = saleConfig;
    uint256 publicPrice = uint256(config.publicPrice);

    require(totalSupply() + quantity <= collectionSize, "reached max supply");

    if(totalSupply() + quantity > totalFreeMints || quantity > freeMintPerTx || numberMinted(msg.sender) > freeMintPerWallet ){
        require(
            (publicPrice * quantity) <= msg.value,
            "Insufficient ETH sent"
        );
    }
  
    _safeMint(msg.sender, quantity);
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