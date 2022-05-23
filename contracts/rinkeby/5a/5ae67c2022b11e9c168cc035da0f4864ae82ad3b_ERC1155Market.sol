//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC1155.sol";
//import "hardhat/console.sol";

contract ERC1155Market {
  address payable public immutable manager;

  struct Artist{ // 1 word
    address payable Address; //Collection creator's address
    uint48 comission; //per thousand
    uint48 managerCom; //per thousand
  }
  struct MarketItem{ // 1 word
    uint120 amount;
    uint128 price;
    bool onSale;
  }
  struct AuctionItem{ //1 word
    uint32 amount;
    uint32 price; //szabo (it can be changed)
    uint32 finishDate; //in second since 1970
    address payable lastBidder;
  }

  struct AuctionItemBig{ //2 words
    uint104 amount;
    uint104 price;
    uint104 buyout;
    uint32 finishDate; //in second since 1970
    address payable lastBidder;
    bool onSale;
  }

  //artists[nftContract]
  mapping(address => Artist) private artists;
  //item[owner][nftContract][tokenId]
  mapping(address => mapping(address =>mapping(uint => MarketItem))) private onSale;
  //price means unit price
  mapping(address => mapping(address =>mapping(uint => MarketItem))) private onSaleUP;
  mapping(address => mapping(address =>mapping(uint => AuctionItem))) private auction;
  mapping(address => mapping(address =>mapping(uint => AuctionItemBig))) private auctionBig;

  constructor(){
    manager = payable(msg.sender);
  }

  //Creators may ask comission from purchasing
  function setComission(
    address nftContract,
    address artist,
    uint8 artistCom,
    uint8 managerCom_
  ) external {
    require (msg.sender == manager, "manager only");
    Artist storage a = artists[nftContract];
    a.Address = payable(artist);
    a.comission = artistCom;
    a.managerCom = managerCom_;
  }

  //for selling single ERC1155
  function sell( //also updates
    address nftContract,
    uint tokenId,
    uint120 amount,
    uint128 price,
    bool isUP
  ) external{
    _beforeSell(nftContract, tokenId, amount);
    _sell(nftContract, tokenId, amount, price, isUP);
    //log(nftContract, tokenId, msg.sender, price, amount, isUP, address(0));
  }

  //for selling multiple ERC115
  function sellBatch( //also updates
    address nftContract,
    uint[] calldata tokenIds,
    uint120[] calldata amounts,
    uint128[] calldata prices,
    bool[] calldata isUP
  ) external {
    uint _length = tokenIds.length;
    require(_length == amounts.length && amounts.length == prices.length
      ,"Inputs' lengths are mismatch");
    uint i;
    while(i < _length){
      _beforeSell(nftContract, tokenIds[i], amounts[i]);
      _sell(nftContract, tokenIds[i], amounts[i], prices[i], isUP[i]);
      //log(nftContract, tokenIds[i], msg.sender, prices[i], amounts[i], isUP[i], address(0));
      unchecked { i++; }
    }
  }

  //for starting auction of single item
  function startAuction(
    address nftContract,
    uint tokenId,
    uint32 amount,
    uint32 price, //szabo
    uint16 duration
  ) external {
    _beforeSell(nftContract, tokenId, amount);
    _auction(nftContract, tokenId, amount, price, duration);
    //log(nftContract, tokenId, msg.sender, price, amount, false, address(0));
  }

  //for starting auction of multiple item
  function startAuctionBatch(
    address nftContract,
    uint[] calldata tokenIds,
    uint32[] calldata amounts,
    uint32[] calldata prices, //szabo
    uint16 duration
  ) external {
    uint _length = tokenIds.length;
    require(_length == amounts.length 
      && amounts.length == prices.length
      ,"Inputs' length are mismatch");
    uint i;
    while(i < _length){
      _beforeSell(nftContract, tokenIds[i], amounts[i]);
      _auction(nftContract, tokenIds[i], amounts[i], prices[i], duration);
      //log(nftContract, tokenIds[i], msg.sender, prices[i], amounts[i], false, address(0));
      unchecked { i++; }
    }
  }

  function startAuctionBig(
    address nftContract,
    uint tokenId,
    uint104 amount,
    uint104 price, 
    uint16 duration,
    uint104 buyout_
  ) external {
    _beforeSell(nftContract, tokenId, amount);
    _auctionBig(nftContract, tokenId, amount, price, duration, buyout_);
    //log(nftContract, tokenId, msg.sender, price, amount, false, address(0));
  }

  function startAuctionBigBatch(
    address nftContract,
    uint[] calldata tokenIds,
    uint104[] calldata amounts,
    uint104[] calldata prices, 
    uint16 duration,
    uint104[] calldata buyouts
  ) external {
    uint _length = tokenIds.length;
    require(_length == amounts.length && amounts.length == prices.length
      && prices.length == buyouts.length
      ,"Inputs' length are mismatch");
    uint i;
    while(i < _length){
      _beforeSell(nftContract, tokenIds[i], amounts[i]);
      _auctionBig(nftContract, tokenIds[i], amounts[i], prices[i], duration, buyouts[i]);
      //log(nftContract, tokenIds[i], msg.sender, prices[i], amounts[i], false, address(0));
      unchecked { i++; }
    }
  }

  //after finish time auction can be terminated
  function terminateAuction(
    address owner,
    address nftContract,
    uint tokenId
  ) external{
    AuctionItem storage a = auction[owner][nftContract][tokenId];
    require(a.finishDate != 0 , "Item is not on the auction");
    require(block.timestamp > a.finishDate, "Auction is still ongoing");
    if( a.lastBidder != address(0)){
      delete auction[owner][nftContract][tokenId];
      IERC1155(nftContract).safeTransferFrom(owner, a.lastBidder, tokenId, a.amount, "0x0");
      _buy(nftContract, owner, uint(a.price) * 10**12);
    }
    //log(nftContract, tokenId, owner, a.price, a.amount, false, msg.sender);
  }

  function terminateAuctionBig(
    address owner,
    address nftContract,
    uint tokenId
  ) external{
    AuctionItemBig storage aBig = auctionBig[owner][nftContract][tokenId];
    require(aBig.finishDate != 0 , "Item is not on the auction");
    require(block.timestamp > aBig.finishDate, "Auction is still ongoing");
    if( aBig.lastBidder != address(0)){
      delete auctionBig[owner][nftContract][tokenId];
      IERC1155(nftContract).safeTransferFrom(owner, aBig.lastBidder, tokenId, aBig.amount, "0x0");
      _buy(nftContract, owner, aBig.price);
    }
    //log(nftContract, tokenId, owner, aBig.price, aBig.amount, false, msg.sender); 
  }

  function buyout(
    address owner,
    address nftContract,
    uint tokenId
  ) external payable{
    AuctionItemBig storage aBig = auctionBig[owner][nftContract][tokenId];
    require(aBig.finishDate != 0 , "Item is not on the auction");
    require(aBig.buyout !=0, "Item has no buyout value");
    require(msg.value == aBig.buyout, "amount is Insufficent");
    if(aBig.lastBidder != address(0)){
      payable(aBig.lastBidder).transfer(aBig.price);
    }
    delete auctionBig[owner][nftContract][tokenId];
    IERC1155(nftContract).safeTransferFrom(owner, msg.sender, tokenId, aBig.amount, "0x0");
    _buy(nftContract, owner, msg.value);
  }

  function bid(
    address owner,
    address nftContract,
    uint tokenId
  ) external payable {
    AuctionItem storage a = auction[owner][nftContract][tokenId];
    _beforeBid(a.lastBidder, a.price, a.finishDate, false);
    a.price = uint32(msg.value / 10**12);
    a.lastBidder = payable(msg.sender);
    //log(nftContract, tokenId, owner, a.price, a.amount, false, msg.sender);
  }

  function bidBig(
    address owner,
    address nftContract,
    uint tokenId
  ) external payable {
    AuctionItemBig storage aBig = auctionBig[owner][nftContract][tokenId];
    _beforeBid(aBig.lastBidder, aBig.price, aBig.finishDate, true);
    aBig.price = uint104(msg.value);
    aBig.lastBidder = payable(msg.sender);
    //log(nftContract, tokenId, owner, aBig.price, aBig.amount, false, msg.sender);
  }

  function buy(
    address nftContract,
    uint tokenId,
    uint120 amount,
    bool isUP,
    address owner
  ) external payable {
    _beforeBuy(isUP, owner, nftContract, tokenId, msg.value, amount);
    IERC1155(nftContract).safeTransferFrom(owner, msg.sender, tokenId, amount, "0x0");
    _buy(nftContract,owner, msg.value);
    //log(nftContract, tokenId, owner, msg.value, amount, isUP, msg.sender);
  }

  function buyBatch(
    address nftContract,
    uint[] calldata tokenIds,
    uint120[] calldata amounts,
    bool[] calldata isUP,
    address owner
  ) external payable{
    uint _totalPrice = msg.value;
    uint _length = tokenIds.length;
    require(_length == amounts.length && _length == isUP.length, "Inputs' length are mismatch");
    uint i;
    uint[] memory amounts_ = new uint[](_length); //for type conversion
    while(i < _length){
      //updates _totalPrice
      _totalPrice =_beforeBuy(isUP[i], owner, nftContract, tokenIds[i],_totalPrice, amounts[i]);
      amounts_[i] = amounts[i]; //uint120 -> uint
      unchecked { i++;}
    }
    IERC1155(nftContract).safeBatchTransferFrom(owner, msg.sender, tokenIds, amounts_, "0x0");
    _buy(nftContract,owner, msg.value);
  }

  function cancelSale (
    address nftContract,
    uint tokenId,
    bool isUP
  ) external {
    //log(nftContract, tokenId, msg.sender, 0, 0, isUP, address(0));
    _cancelSale(nftContract, tokenId, isUP);
  }

  function cancelSaleBatch (
    address nftContract,
    uint[] calldata tokenIds,
    bool[] calldata isUP
  ) external {
    uint _length = tokenIds.length;
    require(_length == isUP.length, "Input's length is mismatch");
    uint i;
    while( i< _length){
      //log(nftContract, tokenIds[i], msg.sender, 0, 0, isUP[i], address(0));
      _cancelSale(nftContract, tokenIds[i], isUP[i]);
      unchecked { i++; }
    }
  }

  function _beforeSell(
    address nftContract,
    uint tokenId,
    uint amount
  ) internal view {
    require(IERC1155(nftContract).isApprovedForAll(msg.sender, address(this)),
        "Give approval to market");
    require(IERC1155(nftContract).balanceOf(msg.sender, tokenId)
        >= amount, "Insufficent balance");
  }

  function _sell(
    address nftContract,
    uint tokenId,
    uint120 amount,
    uint128 price,
    bool isUP
  ) internal {
    MarketItem storage os;
    if(isUP){
      os = onSaleUP[msg.sender][nftContract][tokenId];
    }else{
      os = onSale[msg.sender][nftContract][tokenId];
    }
    os.amount = amount;
    os.price = price;
    os.onSale = true;
  }

  function _auction(
    address nftContract,
    uint tokenId,
    uint32 amount_,
    uint32 price_, //szabo
    uint16 duration
  ) internal {
    AuctionItem storage a = auction[msg.sender][nftContract][tokenId];
    require(a.lastBidder == address(0), "A bid was made"); //can be updated before the first bid
    a.amount = amount_;
    a.price = price_;
    a.finishDate = uint32(block.timestamp + uint(duration) * 1 hours);
  }

  function _auctionBig(
    address nftContract,
    uint tokenId,
    uint104 amount_,
    uint104 price_, 
    uint16 duration,
    uint104 buyout_
  ) internal {
    AuctionItemBig storage aBig = auctionBig[msg.sender][nftContract][tokenId];
    require(aBig.lastBidder == address(0), "A bid was made"); //can be updated before the first bid
    aBig.amount = amount_;
    aBig.price = price_;
    aBig.finishDate = uint32(block.timestamp + uint(duration) * 1 hours);
    aBig.buyout = buyout_;
  }

  function _beforeBid(
    address lastBidder,
    uint price,
    uint finishDate,
    bool isBig
  ) internal {
    require(finishDate != 0, "Item is not for sale");
    if(!isBig){
      require(msg.value / 10**12 < 2**32 , "overflow protection");
    }
    //console.log("Denominator %s",(isBig ? 1: 10**12));
    require(price < msg.value / (isBig ? 1: 10**12), "Increase the bid");
    if(lastBidder != address(0)){
      payable(lastBidder).transfer(price);
    }
  }

  function _beforeBuy(
    bool isUP,
    address owner,
    address nftContract,
    uint tokenId,
    uint _price,
    uint120 amount
  ) internal returns(uint){
    MarketItem storage os;
    if(isUP){
      os = onSaleUP[owner][nftContract][tokenId]; 
      require(os.amount >= amount, "item amount is not sufficent");
    }else{
      os = onSale[owner][nftContract][tokenId];
      require(os.amount == amount, "item amount is mismatch");
    }
    require(os.onSale, "Item is not for sale");
    require(_price >= os.price * (isUP ? amount: 1) , "msg.value not sufficent");
    unchecked{ _price -= os.price * (isUP ? amount: 1); }
    os.amount -= amount;
    //console.log("After Amount :%s", os.amount);
    if(os.amount == 0){
      delete os.price ;
      delete os.onSale ;
    }
    //updates remain value for batch operation
    //console.log("Remaining wei :%s", _price);
    return _price;
  }

  function _buy(
    address nftContract,
    address owner,
    uint value
  ) internal {
    Artist storage artist = artists[nftContract];
    manager.transfer(value * uint(artist.managerCom) / 1000);
    artist.Address.transfer(value * uint(artist.comission) / 1000);
    payable(owner).transfer(value * uint(1000 - artist.comission - artist.managerCom) / 1000);
  }

  function _cancelSale(
    address nftContract,
    uint tokenId,
    bool isUP
  ) internal {
    if(isUP){
      delete onSaleUP[msg.sender][nftContract][tokenId];
    }else{
      delete onSale[msg.sender][nftContract][tokenId];
    }
  }

  // function log( 
  //   address nftContract,
  //   uint tokenId,
  //   address owner,
  //   uint price,
  //   uint amount,
  //   bool isUP,
  //   address buyer
  // ) internal view{
  //   console.log("NFTContratct: %s",nftContract);
  //   console.log("TokenId: %s",tokenId);
  //   console.log("Price: %s", price);
  //   console.log("Amount: %s",amount);
  //   console.log("Owner: %s",owner);
  //   console.log("isUP: %s",isUP);
  //   if(buyer != address(0)){
  //     console.log("Buyer %s", buyer);
  //   }
  // }
}