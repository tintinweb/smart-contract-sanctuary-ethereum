// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

interface IPDSReserved {
  function tradeToBuy (address from, uint256 tokenId) external;

}

contract PortDuSoleil is Ownable, ERC721A, ReentrancyGuard {

  IPDSReserved public PDSR;

  uint256 public constant maxPerAddressDuringMint = 20;
  uint256 public constant amountForDevs = 20;

  struct SaleConfig {
    uint32 publicSaleStartTime;
    uint64 mintlistPrice;
    uint64 publicPrice;
    uint32 publicSaleKey;
  }

  SaleConfig public saleConfig;

  bool public isSaleActive = false;
  bool public isReservedClaimActive = false;

  uint256 public constant PRICEFOR1 = 0.006 ether;

  mapping(address => uint256) public allowlist;

  constructor(

  ) ERC721A("PortDuSoleil", "PDS") {
   
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "caller is other contract");
    _;
  }

    function setPDSR(address PDSRAddress) external onlyOwner {
        PDSR = IPDSReserved(PDSRAddress);
    }

    function setSaleState (bool newState) external onlyOwner {
      isSaleActive = newState;
    }

    function setReservedClaimState (bool newState) external onlyOwner {
      isReservedClaimActive = newState;
    }

  function allowlistMint() external payable callerIsUser {
    uint256 price = uint256(saleConfig.mintlistPrice);
    require(price != 0, "allowlist inactive");
    require(allowlist[msg.sender] > 0, "not eligible for allowlist");
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    --allowlist[msg.sender];
    _safeMint(msg.sender, 1);
    refundIfOver(price);
  }

//need to be able to send token array in from website
  function reservedMintClaim (uint256[] memory tokenArray) external {
    require(isReservedClaimActive, "can't reserve right now");
    for ( uint i = 0; i < tokenArray.length ; i++){
      PDSR.tradeToBuy(msg.sender, tokenArray[i]);
      _safeMint(msg.sender, 1);
    }

  }

  function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey)
    external
    payable
    callerIsUser
  {
    require(isSaleActive, "sale not active");
    SaleConfig memory config = saleConfig;
    uint256 publicSaleKey = uint256(config.publicSaleKey);
    uint256 publicPrice = uint256(config.publicPrice);
    uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
    require(
      publicSaleKey == callerPublicSaleKey,
      "called with incorrect public sale key"
    );

    require(
      isPublicSaleOn(publicPrice, publicSaleKey, publicSaleStartTime),
      "public sale inactive"
    );

    require(totalSupply() + quantity <= collectionSize, "reached max supply");

    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );

    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

  function setupSaleInfo(
    uint64 mintlistPriceWei,
    uint64 publicPriceWei,
    uint32 publicSaleStartTime
  ) external onlyOwner {
    saleConfig = SaleConfig(
      publicSaleStartTime,
      mintlistPriceWei,
      publicPriceWei,
      saleConfig.publicSaleKey
    );
  }

  function refundIfOver(uint256 price) private {

    require(msg.value >= price, "Insufficient ETH.");

    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function isPublicSaleOn(
    uint256 publicPriceWei,
    uint256 publicSaleKey,
    uint256 publicSaleStartTime
  ) public view returns (bool) {
    return
      publicPriceWei != 0 &&
      publicSaleKey != 0 &&
      block.timestamp >= publicSaleStartTime;
  }

  function setPublicSaleKey(uint32 key) external onlyOwner {
    saleConfig.publicSaleKey = key;
  }

  function seedAllowlist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
    }
  }

  // Marketing, Reservations, etc
  function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  // metadata URI
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