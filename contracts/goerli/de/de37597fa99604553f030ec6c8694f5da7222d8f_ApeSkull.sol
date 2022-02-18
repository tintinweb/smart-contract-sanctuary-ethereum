// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./other.sol";
import "./ERC721A.sol";
import "./IERC2981.sol";


contract ApeSkull is Ownable, ERC721A, ReentrancyGuard ,IERC2981  {

    /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A,IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  uint256 public auctionStartTime;
  uint256 public publicStartTime;

  uint256 public constant WHITELLIST_PRICE = 0.0014 ether;
  uint256 public constant PUBLIC_PRICE = 0.0015 ether;

  uint256 public constant AUCTION_START_PRICE = 0.01 ether;
  uint256 public constant AUCTION_END_PRICE = 0.0015 ether;
  uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 340 minutes;
  uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;
  uint256 public constant AUCTION_DROP_PER_STEP = (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);

  uint256 public immutable publicCollectionSize;
  uint256 public immutable maxAddressMint;
  uint256 public immutable maxForFounder;

  uint256 public  founderCount;

  address public  founderContract;
  address public  communityContract;


  mapping(address => uint256) public whitelist;

  uint256 mintCommunityPercent = 75;
  uint256 otherCommunityPercent = 55;


  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 maxAddressMint_,
    uint256 maxForFounder_,
    address communityContract_,
    address founderContract_ 
  ) ERC721A("ApeSkull", "ApeSkull", maxBatchSize_, collectionSize_) {
    require(maxForFounder_ < collectionSize_,"larger collection size needed");
    publicCollectionSize = collectionSize_ - maxForFounder_;
    maxAddressMint = maxAddressMint_;
    maxForFounder = maxForFounder_;
    founderContract = founderContract_;
    communityContract = communityContract_;   
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function founderMint(uint256 quantity) external payable onlyOwner {
    require(founderCount + quantity <= maxForFounder,"can not mint this many");
    founderCount += quantity;

    while(quantity >= maxBatchSize){
        _safeMint(msg.sender, maxBatchSize);
        quantity -= maxBatchSize;
    }
  
    if(quantity > 0){
      _safeMint(msg.sender, quantity);
    }
  }

  function auctionMint(uint256 quantity) external payable callerIsUser {
    require(auctionStartTime != 0 && block.timestamp >= auctionStartTime,"sale has not started yet");
    require(totalSupply() + quantity <= publicCollectionSize + founderCount, "reached max supply");
    require(_numberMinted(msg.sender) + quantity <= maxAddressMint,"can not mint this many");
    uint256 price = getAuctionPrice();
    require(price > 0, "sale has not started yet");
    _safeMint(msg.sender, quantity);
    settlement(price * quantity);
  }


  function whitelistMint(uint256 quantity) external payable callerIsUser {
    require(publicStartTime != 0 && block.timestamp >= publicStartTime,"sale has not started yet");
    require(totalSupply() + quantity <= publicCollectionSize + founderCount, "reached max supply");
    require(whitelist[msg.sender] - quantity >= 0, "not eligible for mint");

    whitelist[msg.sender] -= quantity;//
    _safeMint(msg.sender, quantity);
    settlement(WHITELLIST_PRICE * quantity);
  }


  function publicMint(uint256 quantity) external payable callerIsUser {
    require(publicStartTime != 0 && block.timestamp >= publicStartTime,"sale has not started yet");
    require(totalSupply() + quantity <= publicCollectionSize + founderCount, "reached max supply");
    require(_numberMinted(msg.sender) + quantity <= maxAddressMint,"can not mint this many");

    _safeMint(msg.sender, quantity);
    settlement(PUBLIC_PRICE * quantity);
  }


  function settlement(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
    uint256 community = price * mintCommunityPercent / 100;
    uint256 founder = price - community;
    //
    (bool success, ) = payable(founderContract).call{value: founder}("mint");
    require(success, "Transfer failed");
    (success, ) = payable(communityContract).call{value: community}("mint");
    require(success, "Transfer failed.");
  }

  function getAuctionPrice()
    public
    view
    returns (uint256)
  {
    uint256 _saleStartTime = auctionStartTime;
    if (block.timestamp < _saleStartTime) {
      return AUCTION_START_PRICE;
    }
    if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
      return AUCTION_END_PRICE;
    } else {
      uint256 steps = (block.timestamp - _saleStartTime) /
        AUCTION_DROP_INTERVAL;
      return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
    }
  }

  // function getAuctionPrice() public view returns (uint256)
  // {
  //   uint256 startTime = saleConfig.auctionStartTime;
  //   if (block.timestamp < startTime) { 
  //     return saleConfig.startPrice;
  //   }
  //   if (block.timestamp - startTime >= saleConfig.curveLength) { 
  //     return saleConfig.endPrice;
  //   } else {
  //     uint256 perPrice = (saleConfig.startPrice - saleConfig.endPrice) / saleConfig.curveLength; 
  //     uint256 outPrice = (block.timestamp - startTime) * perPrice;

  //     return saleConfig.startPrice - outPrice;
  //   }
  // }

  function startAuction(uint256 startTimeStamp) external onlyOwner {
    auctionStartTime = startTimeStamp;
    // saleConfig.startPrice = startPriceWei;
    // saleConfig.endPrice = endPriceWei;
    // saleConfig.curveLength = curveLength / dropInterval;
  }

  function startPublic() external onlyOwner {
    auctionStartTime = 0;
    publicStartTime = block.timestamp;
    // saleConfig.whiteListPrice = whiteListPriceWei;
    // saleConfig.publicPrice = publicPriceWei;
    // saleConfig.publicSaleKey = publicSaleKey;
  }
  
  function addWhitelist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelist[addresses[i]] = numSlots[i];
    }
  }

  //metadata URI
  string private _baseTokenURI; //


  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
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
 
   function sellOut() external view returns (bool yes)
   {
     return totalSupply() >= collectionSize;
   }

 
  function setFounderContract(address addr) external onlyOwner{
    founderContract = addr;
  }


  function setCommunityContract(address addr) external onlyOwner{
    communityContract = addr;
  }


  fallback () external payable{
    _royalty();
  }


  receive () external payable{
    _royalty();
  }

  function _royalty() private{
    if(msg.value <= 0){
      return;
    }
    uint256 community = msg.value * otherCommunityPercent / 100;
    uint256 founder = msg.value - community;
    
   (bool success, ) = payable(founderContract).call{value: founder}("royalty");
   require(success, "Transfer failed");
   (success, ) =  payable(communityContract).call{value: community}("royalty");
   require(success, "Transfer failed.");
  }

  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  )external view override returns (
    address receiver,
    uint256 royaltyAmount
){
    _tokenId;
    _salePrice;
  return(address(this),_salePrice / 10);
}

  function getBalance() external view returns(uint256){
      return address(this).balance;
  }
}