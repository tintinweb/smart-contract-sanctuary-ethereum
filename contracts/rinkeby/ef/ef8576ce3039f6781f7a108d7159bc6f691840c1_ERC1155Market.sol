//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC1155.sol";

contract ERC1155Market {
  address payable public immutable _manager;
  uint private _comissionRate; //per thousand

  struct MarketItem{
    uint128 price; //szabo (10^12)
    uint120 amount;
    bool onSale;
  }

  struct AuctionItem{
    uint32 price; //szabo
    uint24 amount;
    uint32 finishDate; //in second since 1970
    address payable lastBidder;
    bool onSale;
  }
  
  //item[owner][nftContract][tokenId]
  mapping(address => mapping(address =>mapping(uint => MarketItem))) private onSale;
  //price means unit price
  mapping(address => mapping(address =>mapping(uint => MarketItem))) private onSaleUP;
  mapping(address => mapping(address =>mapping(uint => AuctionItem))) private auction;

  modifier byManager(){
    require(msg.sender == _manager, "Caller must be manager");
    _;
  }

  function setComission(uint comissonRate_) external byManager {
    _comissionRate = comissonRate_;
  }

  constructor(uint comissionRate_){
    _manager = payable(msg.sender);
    _comissionRate = comissionRate_; //per thousand
  }

  function sell( //also updates
    address nftContract,
    uint tokenId,
    uint32 amount,
    uint32 price,
    bool isUP
  ) external{
    _beforeSell(nftContract, tokenId, amount);
    MarketItem storage os;
    if(isUP){
      os = onSaleUP[msg.sender][nftContract][tokenId];
    }else{
      os = onSale[msg.sender][nftContract][tokenId];
    }
    os.price = price;
    os.amount = amount;
    os.onSale = true;
  }

  function sellBatch( //also updates
    address nftContract,
    uint[] calldata tokenIds,
    uint32[] calldata amounts,
    uint32[] calldata prices,
    bool[] calldata isUP
  ) external {
    uint _length = tokenIds.length;
    require(_length == amounts.length && amounts.length == prices.length
      ,"Inputs' length are mismatch");
    uint i;
    MarketItem storage os;
    while(i < _length){
      _beforeSell(nftContract, tokenIds[i], amounts[i]);
      if(isUP[i]){
        os = onSaleUP[msg.sender][nftContract][tokenIds[i]];
      }else{
        os = onSale[msg.sender][nftContract][tokenIds[i]];
      }
      os.price = prices[i];
      os.amount = amounts[i];
      os.onSale = true;
      unchecked { i++; }
    }
  }

  function startAuction(
    address nftContract,
    uint tokenId,
    uint24 amount,
    uint32 prices,
    uint32 duration
  ) external {
    _beforeSell(nftContract, tokenId, amount); 
    AuctionItem storage a = auction[msg.sender][nftContract][tokenId];
    a.price = prices;
    a.amount = amount;
    a.finishDate = uint32(block.timestamp + duration * 1 hours);  
  }

  function startAuctionBatch(
    address nftContract,
    uint[] calldata tokenIds,
    uint24[] calldata amounts,
    uint32[] calldata prices,
    uint32[] calldata durations
  ) external {
    uint _length = tokenIds.length;
    require(_length == amounts.length && amounts.length == prices.length
      ,"Inputs' length are mismatch");
    uint i;
    while(i < _length){
      AuctionItem storage a = auction[msg.sender][nftContract][tokenIds[i]];
      a.price = prices[i];
      a.amount = amounts[i];
      a.finishDate = uint32(block.timestamp + durations[i] * 1 hours);
      unchecked { i++; }
    }
  }

  function buy(
    address nftContract,
    uint tokenId,
    uint amount,
    bool isUP,
    address owner
  ) external payable {
    _beforeBuy(isUP, owner, nftContract, tokenId, msg.value, amount);

    IERC1155(nftContract).safeTransferFrom(owner, msg.sender, tokenId, amount, "0x0");
    payable(owner).transfer(msg.value * (1000 - _comissionRate) / 1000);
    _manager.transfer(msg.value * _comissionRate / 1000);

    _afterBuy(isUP, owner, nftContract, tokenId, uint120(amount));   
  }

  function buyBatch(
    address nftContract,
    uint[] calldata tokenIds,
    uint[] calldata amounts,
    bool[] calldata isUP,
    address owner
  ) external payable{
    uint _price = msg.value;
    uint _length = tokenIds.length;
    require(_length == amounts.length, "Inputs' length are mismatch");
    uint i;
    while(i < _length){
      _price =_beforeBuy(isUP[i], owner, nftContract, tokenIds[i], _price, amounts[i]);
      //updates _price
      unchecked { i++;}
    }
    IERC1155(nftContract).safeBatchTransferFrom(owner, msg.sender, tokenIds, amounts, "");
    payable(owner).transfer(msg.value *  (1000 - _comissionRate) / 1000);
    _manager.transfer(msg.value * _comissionRate / 1000);

    i=0;
    while(i<_length){
      _afterBuy(isUP[i], owner, nftContract, tokenIds[i], uint120(amounts[i]));
    }
  }

  function bid(
    address owner,
    address nftContract,
    uint tokenId
  ) external payable {
    AuctionItem storage a = auction[owner][nftContract][tokenId];
    require(a.onSale, "Item is not for sale");
    require(a.price < msg.value, "Increase the bid");
    
    if(a.lastBidder != address(0)){
      a.lastBidder.transfer(a.price);
    }
    a.price = uint32(msg.value);
    a.lastBidder = payable(msg.sender);
  }

  function terminateAuction(
    address owner,
    address nftContract,
    uint tokenId
  ) external{
    AuctionItem storage a = auction[owner][nftContract][tokenId];
    require(a.onSale , "Item is not for sale");
    require(block.timestamp > a.finishDate, "Auction still ongoing");
    if( a.lastBidder != address(0)){
      IERC1155(nftContract).safeTransferFrom(owner, a.lastBidder, tokenId, a.amount, "0x0");
      payable(owner).transfer(a.price * (1000 - _comissionRate) / 1000);
      _manager.transfer(a.price * _comissionRate / 1000);
    }
    delete auction[owner][nftContract][tokenId];
  }

  function cancelSale (
    address nftContract,
    uint tokenId,
    bool isUP
  ) external {
    if(isUP){
      delete onSaleUP[msg.sender][nftContract][tokenId];
    }else{
      delete onSale[msg.sender][nftContract][tokenId];
    }
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
      if(isUP[i]){
        delete onSaleUP[msg.sender][nftContract][tokenIds[i]];
      }else{
        delete onSale[msg.sender][nftContract][tokenIds[i]];
      }
      unchecked { i++; }
    }
  }

  function _beforeSell(
    address nftContract,
    uint tokenId,
    uint32 amount
  ) internal view {
    require(IERC1155(nftContract).isApprovedForAll(msg.sender, address(this)),
        "Give approval to market");
    require(IERC1155(nftContract).balanceOf(msg.sender, tokenId)
        <= amount, "Insufficent balance");
  }

  function _afterBuy(
    bool isUP,
    address owner,
    address nftContract,
    uint tokenId,
    uint120 amount
  ) internal {
    MarketItem storage os;
    if(isUP){
      os = onSaleUP[owner][nftContract][tokenId]; 
    }else{
      os = onSale[owner][nftContract][tokenId];
    }
    os.amount -= amount;
    if(os.amount == 0){
      delete os.price;
    }
  }

  function _beforeBuy(
    bool isUP,
    address owner,
    address nftContract,
    uint tokenId,
    uint _price,
    uint amount
  ) internal view returns(uint){
    MarketItem storage os;
    if(isUP){
      os = onSaleUP[owner][nftContract][tokenId]; 
    }else{
      os = onSale[owner][nftContract][tokenId]; 
    }
    require(os.onSale, "Item is not for sale");
    require(os.amount >= amount, "item amount is mismatch");
    require(_price >= os.price * 10^12 * (isUP ? amount: 1) , "msg.value not sufficent");
    unchecked{ _price -= os.price * 10^12 * (isUP ? amount: 1); } //updates remain value for batch operation
    return _price;
  }
}