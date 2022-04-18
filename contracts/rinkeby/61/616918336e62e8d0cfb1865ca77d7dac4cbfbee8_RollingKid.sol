// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
contract RollingKid is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable amountForDevs;
  uint256 public  startTime;
  // uint256 public immutable amountForAuctionAndDev;
  // bool private _isBlind = true ;
  // struct SaleConfig {
  //   uint32 publicSaleStartTime;
  //   uint64 mintlistPrice;
  //   uint64 publicPrice;
  //   uint32 publicSaleKey;
  // }

  // SaleConfig public saleConfig;

  mapping(address => uint256) public allowlist;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    // uint256 amountForAuctionAndDev_,
    uint256 amountForDevs_
  ) ERC721A("Rolling kid", "RK", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
    // amountForAuctionAndDev = amountForAuctionAndDev_;
    amountForDevs = amountForDevs_;
    // require(
    //   amountForAuctionAndDev_ <= collectionSize_,
    //   "larger collection size needed"
    // );
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }



  function allowlistMint() external payable callerIsUser {
    // uint256 price = uint256(saleConfig.mintlistPrice);
    // require(price != 0, "allowlist sale has not begun yet");
    require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    require(startTime <= block.timestamp && startTime!=0,"not opened yet");
    // uint256 overTime = startTime + 1209600;
    // require(overTime< block.timestamp,"the activity is over");
    allowlist[msg.sender]--;
    _safeMint(msg.sender, 1);
    // refundIfOver(price);
  }
  function devMint(uint8 quantity) external onlyOwner {
     require(
       quantity % maxBatchSize == 0,
       "can only mint a multiple of the maxBatchSize"
     );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint8 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  // function publicSaleMint(uint8 quantity, uint32 callerPublicSaleKey)
  //   external
  //   payable
  //   callerIsUser
  // {
  //   SaleConfig memory config = saleConfig;
  //   uint32 publicSaleKey = uint32(config.publicSaleKey);
  //   uint64 publicPrice = uint64(config.publicPrice);
  //    uint32 publicSaleStartTime = uint32(config.publicSaleStartTime);
  //   require(
  //     publicSaleKey == callerPublicSaleKey,
  //     "called with incorrect public sale key"
  //   );
  //   require(
  //     publicSaleStartTime <= block.timestamp && publicSaleStartTime!=0,
  //     "no time"
  //   );
    
  //   require(totalSupply() + quantity <= collectionSize, "reached max supply");
  //   require(
  //     numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
  //     "can not mint this many"
  //   );
  //   _safeMint(msg.sender, quantity);
  //   refundIfOver(publicPrice * quantity);
  // }

  // function refundIfOver(uint256 price) private {
  //   require(msg.value >= price, "Need to send more ETH.");
  //   if (msg.value > price) {
  //     payable(msg.sender).transfer(msg.value - price);
  //   }
  // }


  

  // function setpublicSaleTime(
  //   uint32 publicSaleStartTime
  // ) external onlyOwner {
  //   saleConfig = SaleConfig(
  //     publicSaleStartTime,
  //     0,
  //     0,
  //     saleConfig.publicSaleKey
  //   );
  // }
  function setStartTime(
    uint32 startTime_
  ) external onlyOwner {
    startTime =  startTime_;
  }

  // function setPublicSaleKey(uint32 key) external onlyOwner {
  //   saleConfig.publicSaleKey = key;
  // }

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