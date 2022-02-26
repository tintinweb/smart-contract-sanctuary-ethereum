// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./other.sol";
import "./ERC721A.sol";
import "./IERC2981.sol";
import { MerkleProof } from "./MerkleProof.sol";

contract CryptoApeSkullClub is Ownable, ERC721A, ReentrancyGuard ,IERC2981  {

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

  struct SaleConfig {
    uint256 startTime;
    uint256 endTime;
    uint256 price;
  }

  struct AuctionConfig {
    uint256 startPrice;
    uint256 endPrice;
    uint256 stepPrice;
    uint256 supply;
    uint256 interval;
  }
  
  SaleConfig public auctionSaleConfig;
  SaleConfig public whitelistSaleConfig;
  SaleConfig public publicSaleConfig;

  AuctionConfig public auctionConfig;

  uint256 public immutable publicCollectionSize;

  uint256 public immutable maxForFounder;

  uint256 public  founderCount;
  uint256 public  auctionCount;


  bytes32 public merkleRoot;
  mapping(address => uint256) public whitelist;


  uint256 mintCommunityPercent = 75;
  uint256 otherCommunityPercent = 55;

  address public  communityOwner;

  uint256 public founderIncome;
  uint256 public communityIncome;

  uint256 public constant Collection_Size = 10000;

  uint256 public constant Max_Batch_Size = 20;
  uint256 public constant Max_Auction_Batch_Size = 5;


  uint256[] withdrawScale = [0 ether,1,
                            100 ether,20,
                            300 ether,50,
                            1000 ether,80,
                            10000 ether,100];


  uint256 public founderWithdrawAmount;
  uint256 public communityWithdrawAmount;
  
  event FounderWithdraw(uint income);
  event CommunityWithdraw(uint income);

  event Mint(address indexed minter,uint256 indexed price);
  event RoyaltyIncome(address indexed sender, uint indexed income);
  event CommunityOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor(
    uint256 maxForFounder_,
    address communityAddress_,
    string memory _baseTokenURI_ 
  ) ERC721A("CryptoApeSkullClub", "CASC", Max_Batch_Size, Collection_Size) {
    require(maxForFounder_ < Collection_Size,"larger collection size needed");
    _baseTokenURI = _baseTokenURI_;
    publicCollectionSize = Collection_Size - maxForFounder_;
    maxForFounder = maxForFounder_;
    communityOwner = communityAddress_;   
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

   modifier onlyCommunityOwner() {
    require(tx.origin == communityOwner, "Ownable: caller is not the owner");
    _;
   }

  modifier checkSale(SaleConfig storage config,uint256 quantity){
    require(
      quantity <= Max_Batch_Size,
      "can not mint this many"
    );
    require(
      config.startTime != 0 && block.timestamp >= config.startTime,
      "sale has not started yet"
    );
    require(
      config.endTime != 0 && block.timestamp < config.endTime,
      "sale has end yet"
    );
    require(
      totalSupply() + quantity <= publicCollectionSize + founderCount, 
      "reached max supply"
    );
    _;
  }

  function founderMint(uint256 quantity) external onlyOwner {
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

  function auctionMint(uint256 quantity) external payable callerIsUser checkSale(auctionSaleConfig,quantity){
    require(quantity <= Max_Auction_Batch_Size,"can not mint this many");
    require(auctionCount + quantity <= auctionConfig.supply, "reached max supply");
    uint256 price = getAuctionPrice();
    
    auctionCount += quantity;
    _safeMint(msg.sender, quantity);
    settlement(price * quantity);
  }


  function whitelistMint(uint256 quantity,uint256 mintMaxAmount, bytes32[] calldata proof) external payable callerIsUser checkSale(whitelistSaleConfig,quantity){
    require(whitelist[msg.sender] + quantity <= mintMaxAmount, "not eligible for mint");
    
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, mintMaxAmount));
    require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

    whitelist[msg.sender] += quantity;//
    _safeMint(msg.sender, quantity);
    settlement(whitelistSaleConfig.price * quantity);

  }


  function publicMint(uint256 quantity) external payable callerIsUser checkSale(publicSaleConfig,quantity){
    _safeMint(msg.sender, quantity);
    settlement(publicSaleConfig.price * quantity);
  }


  function settlement(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
    uint256 community = price * mintCommunityPercent / 100;
    uint256 founder = price - community;
    //
    founderIncome += founder;
    communityIncome += community;
    emit Mint(msg.sender,price);
  }

  function getAuctionPrice() public view returns (uint256)
  {
    uint256 _saleStartTime = auctionSaleConfig.startTime;
    if (block.timestamp < _saleStartTime) {
      return auctionConfig.startPrice;
    }
    uint256 steps = (block.timestamp - _saleStartTime) / auctionConfig.interval;
    uint256 lost = steps * auctionConfig.stepPrice;
    if(lost >= auctionConfig.startPrice){
       return auctionConfig.endPrice;
    }
    uint256 price = auctionConfig.startPrice - lost;
    if(price < auctionConfig.endPrice){
      return auctionConfig.endPrice;
    }
    return price;
  }


  function setAuction(
    uint256 startTimeStamp,uint256 endTimeStamp,
    uint256 startPriceWei,uint256 endPriceWei,uint256 stepPriceWei,uint256 interval,
    uint256 supply
    ) external onlyOwner {
      auctionSaleConfig.startTime = startTimeStamp;
      auctionSaleConfig.endTime = endTimeStamp;

      auctionConfig.startPrice = startPriceWei;
      auctionConfig.endPrice = endPriceWei;
      auctionConfig.stepPrice = stepPriceWei;
      auctionConfig.interval = interval;
      auctionConfig.supply = supply;

      auctionCount = 0;
  }

  function setWhiteList(uint256 startTimeStamp,uint256 endTimeStamp,uint256 priceWei) external onlyOwner {
    whitelistSaleConfig.startTime = startTimeStamp;
    whitelistSaleConfig.endTime = endTimeStamp;
    whitelistSaleConfig.price = priceWei;
  }

  function setPublic(uint256 startTimeStamp,uint256 endTimeStamp,uint256 priceWei) external onlyOwner {
    publicSaleConfig.startTime = startTimeStamp;
    publicSaleConfig.endTime = endTimeStamp;
    publicSaleConfig.price = priceWei;
  }

  function setMerkleRoot(bytes32 newRoot) external onlyOwner {
      merkleRoot = newRoot;
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


  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
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
    founderIncome += founder;
    communityIncome += community;
    emit RoyaltyIncome(msg.sender,msg.value);
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
  function canWithdrawAmount() public view returns (uint256) {
    if(totalSupply() < collectionSize){
      return 0;
    }
    uint256 percent = 0;
    for (uint256 i = 0; i < withdrawScale.length; i=i+2) {
      if(founderIncome>=withdrawScale[i]){
          percent = withdrawScale[i+1];
      }else{
        break;
      }
    }
    return percent*founderIncome/100 - founderWithdrawAmount;
  }
  
  function founderWithdraw() external onlyOwner nonReentrant {
    uint256 amount = canWithdrawAmount();
    require(amount > 0, "Balance is not enough");
    (bool success, ) = msg.sender.call{value: amount}("");
    if(success){
      founderWithdrawAmount = founderWithdrawAmount + amount;
    }
    require(success, "Transfer failed.");
    emit FounderWithdraw(amount);
  }

  function communityWithdraw() external onlyCommunityOwner nonReentrant {
    uint256 amount = communityIncome - communityWithdrawAmount;
    require(amount > 0, "Balance is not enough");
    (bool success, ) = msg.sender.call{value: amount}("");
    if(success){
      communityWithdrawAmount = communityWithdrawAmount + amount;
    }
    require(success, "Transfer failed");
    emit CommunityWithdraw(amount);
  }

   function transferCommunityOwnership(address newOwner) external  onlyCommunityOwner nonReentrant{
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = communityOwner;
        communityOwner = newOwner;
        emit CommunityOwnershipTransferred(oldOwner,newOwner);
    }
    
  function getBalance() external view returns(uint256){
      return address(this).balance;
  }
}