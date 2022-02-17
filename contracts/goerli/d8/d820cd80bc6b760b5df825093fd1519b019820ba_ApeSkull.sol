// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./other.sol";
import "./ERC721A.sol";
import "./IERC2981.sol";

// interface ICommunity {
//     function mintRecord(address to,uint256 tokenId, uint256 quantity) external payable;//mint
//     function transferRecord(address from,address to,uint256 tokenId) external payable;//mint
// }

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

  struct SaleConfig {
    uint256 saleStartTime;//发售开始时间
    uint256 saleEndTime;//发售结束时间    
    uint256 supply;//mint供给量
    uint256 addressSupply;//每个地址mint最大量
    uint256 price;//价格
    uint256 mintCount;//已经mint数

    uint256 startPrice;//拍卖开始价格
    uint256 endPrice;//拍卖开始价格
    uint256 curveLength;//拍卖曲线时间长度
  }

  address public  founderContract;//开发团队资产管理地址
  address public  communityContract;//社区资产管理地址

  SaleConfig public founderConfig;
  SaleConfig public ogConfig;
  SaleConfig public whitelistConfig;
  SaleConfig public auctionConfig;

  mapping(address => bool) public founderlist; //团队名单
  mapping(address => bool) public oglist; //og名单
  mapping(address => bool) public whitelist; //白名单

  mapping(address => uint256) public founderCount; //团队名单每个地址mint数
  mapping(address => uint256) public ogCount; //og名单每个地址mint数
  mapping(address => uint256) public whiteCount; //白名单每个地址mint数
  mapping(address => uint256) public auctionCount; //每个地址拍卖数

  // uint64 holdingTime = 3121222;//持有30天
  // uint256 founderPercent = 25;
  uint256 mintCommunityPercent = 75;
  uint256 otherCommunityPercent = 55;

  // uint256 totalAmount = 0; //总收益
  // uint256 withdrawAmount = 0; //已提现金额


  constructor(
    uint256 maxBatchSize_,//单次最大数
    uint256 collectionSize_,//总量
    address communityContract_,//社区合约地址
    address founderContract_ //团队合约地址
  ) ERC721A("ApeSkull", "ApeSkull", maxBatchSize_, collectionSize_) {
    founderContract = founderContract_;
    communityContract = communityContract_;
  }

  //禁止合约操作，只能钱包地址操作
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function _checkSale(SaleConfig storage config,uint256 quantity) private view {
    require(
      config.saleStartTime != 0 && block.timestamp >= config.saleStartTime,
      "sale has not started yet"
    );
    require(
      config.saleEndTime != 0 && block.timestamp < config.saleEndTime,
      "sale has end yet"
    );
    require(
      config.mintCount + quantity <= config.supply,
      "too many already minted before dev mint"
    );
    require(
      totalSupply() + quantity <= collectionSize,
       "reached max supply"
    );
  }

  //开发者mint
  function founderMint(uint256 quantity) external payable callerIsUser {
    _checkSale(founderConfig,quantity);//检查时间和数量
    require(founderlist[msg.sender],"");//不在团队名单
    require(founderCount[msg.sender] + quantity <= founderConfig.addressSupply, "not eligible for founderlist mint");//该地址购买超了
    founderCount[msg.sender] += quantity;
    founderConfig.mintCount += quantity;
    uint256 tokenId = totalSupply();
    _safeMint(msg.sender, quantity);
    if(founderConfig.price > 0){
      settlement(founderConfig.price*quantity,quantity,tokenId);
    }
  }

  //og mint
  function ogMint(uint256 quantity) external payable callerIsUser {
    _checkSale(ogConfig,quantity);//检查时间和数量
    require(oglist[msg.sender], "");//不在og名单
    require(ogCount[msg.sender] + quantity <= ogConfig.addressSupply, "not eligible for og mint");//该地址购买超了
    ogCount[msg.sender] += quantity;
    ogConfig.mintCount += quantity;
    uint256 tokenId = totalSupply();
    _safeMint(msg.sender, quantity);
    settlement(ogConfig.price*quantity,quantity,tokenId);
  }

  //白名单mint
  function whitelistMint(uint256 quantity) external payable callerIsUser {
    _checkSale(whitelistConfig,quantity);//检查时间和数量
    require(whitelist[msg.sender], "");//不在白名单
    require(whiteCount[msg.sender] + quantity <= whitelistConfig.addressSupply, "not eligible for og mint");//该地址购买超了
    whiteCount[msg.sender] += quantity;
    whitelistConfig.mintCount += quantity;
    uint256 tokenId = totalSupply();
    _safeMint(msg.sender, quantity);
    settlement(whitelistConfig.price * quantity,quantity,tokenId);
  }

    //拍卖mint
  function auctionMint(uint256 quantity) external payable callerIsUser {
     _checkSale(auctionConfig,quantity);//检查时间和数量
    require(auctionCount[msg.sender] + quantity <= auctionConfig.addressSupply, "not eligible for og mint");
    auctionCount[msg.sender] += quantity;
    auctionConfig.mintCount += quantity;
    uint256 totalCost = getAuctionPrice() * quantity;
    uint256 tokenId = totalSupply();
    _safeMint(msg.sender, quantity);
    settlement(totalCost,quantity,tokenId);
  }

  //结算金额
  function settlement(uint256 price,uint256 quantity,uint256 tokenId) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }

    uint256 community = price * mintCommunityPercent / 100;
    uint256 founder = price - community;
    // payable(founderContract).transfer(founder); //转给团队
    // payable(communityContract).transfer(community);//转给社区
    // ICommunity(communityContract).mintRecord{value:community}(msg.sender,tokenId, quantity);
    quantity;
    tokenId;
    (bool success, ) = payable(founderContract).call{value: founder}("mint");
    require(success, "lost.1");
    (success, ) = payable(communityContract).call{value: community}("mint");
    require(success, "lost.2");
  }

    //计算出拍卖价格
  function getOgPrice() public view returns (uint256)
  {
    return ogConfig.price;
  }

   //计算出拍卖价格
  function getWhitePrice() public view returns (uint256)
  {
     return whitelistConfig.price;
  }


  //计算出拍卖价格
  function getAuctionPrice() public view returns (uint256)
  {
    uint256 _saleStartTime = auctionConfig.saleStartTime;
    if (block.timestamp < _saleStartTime) { //小于开始时间 还未开始，价格返回0
      return 9999 ether;
    }
    if (block.timestamp - _saleStartTime >= auctionConfig.curveLength) { //大于周期价格，一直是最低价
      return auctionConfig.endPrice;
    } else {
      uint256 perPrice = (auctionConfig.startPrice - auctionConfig.endPrice) / auctionConfig.curveLength; //浮动价格/周期时间
      uint256 outPrice = (block.timestamp - _saleStartTime) * perPrice; // 已经跌掉的价格

      return auctionConfig.startPrice - outPrice; //当前价格
    }
  }

    //设置团队mint时间及价格和个数
  function setFounderConfig(uint32 startTime,uint32 endTime,uint256 supply,uint256 addressSupply,uint256 price) external onlyOwner {
    founderConfig.saleStartTime = startTime;
    founderConfig.saleEndTime = endTime;
    founderConfig.supply = supply;
    founderConfig.addressSupply = addressSupply;
    founderConfig.price = price;
  }

      //设置OG mint时间及价格和个数
  function setOgConfig(uint32 startTime,uint32 endTime,uint256 supply,uint256 addressSupply,uint256 price) external onlyOwner {
    ogConfig.saleStartTime = startTime;
    ogConfig.saleEndTime = endTime;
    ogConfig.supply = supply;
    ogConfig.addressSupply = addressSupply;
    ogConfig.price = price;
  }

      //设置white mint时间及价格和个数
  function setWhiteConfig(uint32 startTime,uint32 endTime,uint256 supply,uint256 addressSupply,uint256 price) external onlyOwner {
    whitelistConfig.saleStartTime = startTime;
    whitelistConfig.saleEndTime = endTime;
    whitelistConfig.supply = supply;
    whitelistConfig.addressSupply = addressSupply;
    whitelistConfig.price = price;
  }


  //设置开始拍卖时间及价格和个数
  function setAuctionConfig(uint32 startTime,uint32 endTime,uint256 supply,uint256 addressSupply,
                            uint256 startPrice,uint256 endPrice,uint256 curveLength) external onlyOwner {
    auctionConfig.saleStartTime = startTime;
    auctionConfig.saleEndTime = endTime;
    auctionConfig.supply = supply;
    auctionConfig.addressSupply = addressSupply;
    auctionConfig.startPrice = startPrice;
    auctionConfig.endPrice = endPrice;
    auctionConfig.curveLength = curveLength;
  }

    //添加团队名单
  function addFounderlist(address[] memory addresses) external onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      if(founderlist[addresses[i]]){
        continue;
      }
      founderlist[addresses[i]] = true;
    }
  }

    //添加og名单
  function addOglist(address[] memory addresses) external onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
       if(oglist[addresses[i]]){
        continue;
      }
      oglist[addresses[i]] = true;
    }
  }

      //添加团队名单
  function addWhitelist(address[] memory addresses) external onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      if(whitelist[addresses[i]]){
        continue;
      }
      whitelist[addresses[i]] = true;
    }
  }


      //添加团队名单
  function removeFounderlist(address[] memory addresses) external onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      delete founderlist[addresses[i]];
    }
  }

    //添加og名单
  function removeOglist(address[] memory addresses) external onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      delete oglist[addresses[i]];
    }
  }

      //添加团队名单
  function removeWhitelist(address[] memory addresses) external onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      delete whitelist[addresses[i]];
    }
  }

  //metadata URI
  string private _baseTokenURI; //

  //nft输出地址前缀
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  //设置展示的nft的前缀，最终地址 _baseTokenURI+(tokenid)
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  //已经mint多少
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  //tokenid对应所有者
  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
    //是否售罄
   function sellOut() external view returns (bool yes)
   {
     return totalSupply() >= collectionSize;
   }

    //设置团队合约地址
  function setFounderContract(address addr) external onlyOwner{
    founderContract = addr;
  }

    //设置社区合约地址
  function setCommunityContract(address addr) external onlyOwner{
    communityContract = addr;
  }

    //Fallback
  //转账处理事件,版税处理
  fallback () external payable{
    _royalty();
  }

  //其他转账当版税处理
  receive () external payable{
    _royalty();
  }

   function _royalty() private{
     if(msg.value <= 0){
      return;
    }
    uint256 community = msg.value * otherCommunityPercent / 100;
    uint256 founder = msg.value - community;
    
  // (bool success, ) = 
   (bool success, ) = payable(founderContract).call{value: founder}("royalty");
   require(success, "lost.1");
   (success, ) =  payable(communityContract).call{value: community}("royalty");
   require(success, "lost.2");
  }
  //   /**
  //   * @dev See {IERC721-transferFrom}.
  //   */
  //   function transferFrom(
  //     address from,
  //     address to,
  //     uint256 tokenId
  //   ) public override {
  //     _transfer(from, to, tokenId);
  //     ICommunity(communityContract).transferRecord(from,to,tokenId);
  //   }
  //   /**
  //  * @dev See {IERC721-safeTransferFrom}.
  //  */
  // function safeTransferFrom(
  //   address from,
  //   address to,
  //   uint256 tokenId,
  //   bytes memory _data
  // ) public override {
  //   _transfer(from, to, tokenId);
  //   ICommunity(communityContract).transferRecord(from,to,tokenId);
  //   require(
  //     _checkOnERC721Received(from, to, tokenId, _data),
  //     "ERC721A: transfer to non ERC721Receiver implementer"
  //   );
  // }

     function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (
        address receiver,
        uint256 royaltyAmount
    ){
        _tokenId;
        _salePrice;
      return(address(this),0.1 ether);
    }

  function getBalance() external view returns(uint256){
      return address(this).balance;
  }
}