// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ReentrancyGuard.sol';
import './Counters.sol';
import './IERC721.sol';
import './Context.sol';


contract CloseSea is ReentrancyGuard,Context{



  using Counters for Counters.Counter;

  Counters.Counter orderIds;

  mapping(uint256 => Order) orders;
  mapping(address => uint256[]) userOrders;


  enum Status{
    open,
    close,
    cancel
  }

  enum Direction{
    sell,
    buy
  }

  struct Order {
      uint256 id;
      uint256 tokenId;
      uint256 price;
      uint256 deadline;
      address nft;
      address otherside;
      address creater;
      Direction direction;
      Status status;
  }

  event CreateOrder(address creater,uint256 orderId,Direction direction);
  event CancelOrder(address creater,uint256 orderId,Direction direction);
  event Clinch(address indexed nft,uint256 indexed orderId,uint256 tokenId,uint256 price);
  event UpdatePrice(uint256 indexed orderId,uint256 price,uint256 newPrice);

  constructor(){  

  }

  function getOrderInfo(uint256[] memory _ids)public view returns(Order[] memory){
    Order[] memory _orders = new Order[](_ids.length);

    for(uint256 i;i < _ids.length;i++){
      _orders[i] = orders[_ids[i]];
    }
    return _orders;
  }

  function getUserOrder(address _user)external view returns(Order[] memory){
    return getOrderInfo(userOrders[_user]);
  }

  function nextOrderId()external view returns(uint256 orderId){
    return orderIds.current();
  }


  function offerForSale(address _nft,uint256 _tokenId,uint256 _price,uint256 _deadline) external nonReentrant{
    _offerForSale(_nft,_tokenId,_price,address(0),_deadline);
  }

  function offerForSaleWithLimitedBuyer(address _nft,uint256 _tokenId,uint256 _price,address _buyer,uint256 _deadline) external nonReentrant{
    _offerForSale(_nft,_tokenId,_price,_buyer,_deadline);
  }

  function _offerForSale(address _nft,uint256 _tokenId,uint256 _price,address _buyer,uint256 _deadline) internal{
    address approvedAddress = IERC721(_nft).getApproved(_tokenId);
    bool isOperator = IERC721(_nft).isApprovedForAll(_msgSender(), address(this));
    require(approvedAddress == address(this) || isOperator,'not allowed');
    require(_deadline > block.timestamp,'deadline is error');
    
    _createOrder(_nft, _tokenId, _price,_deadline, _buyer, Direction.sell);
  }

  

  
 
  function offerForBuyer(address _nft,uint256 _tokenId,uint256 _deadline)payable external nonReentrant{
    require(msg.value > 0,'Price must be greater than 0');
    require(_deadline > block.timestamp,'deadline is error');

    _createOrder(_nft, _tokenId, msg.value,_deadline, address(0), Direction.buy);
  }

  


  function cancelOrder(uint256 _orderId) external nonReentrant {
    require(_orderId < orderIds.current(),'order does not exist');

    Order storage order = orders[_orderId];
    require(order.creater == _msgSender(),'not your order');
    require(order.status == Status.open && block.timestamp <= order.deadline,'order closed');

    order.status = Status.cancel;
    if(order.direction == Direction.buy){
      require(
        payable(_msgSender()).send(order.price),
        'Failed to return eth'
        );
    }
    emit CancelOrder(_msgSender(), _orderId, order.direction);
  }

  function updateBuyOrderPrice(uint256 _orderId,uint256 _price,uint256 _newPrice)payable external nonReentrant{
    _checkOrderInfo(_orderId,_price,_newPrice);

    Order storage order = orders[_orderId];
    require(order.direction == Direction.buy,'not buy order');
    if(_price > _newPrice){
      require(payable(_msgSender()).send(_price - _newPrice),'Failed to return eth');
    }else{
      require(msg.value == _newPrice - _price,'The price increase does not match');
    }
    order.price = _newPrice;
    emit UpdatePrice(_orderId, _price, _newPrice);
  }

  function updateSellOrderPrice(uint256 _orderId,uint256 _price,uint256 _newPrice)external nonReentrant{
    _checkOrderInfo(_orderId,_price,_newPrice);

    Order storage order = orders[_orderId];
    require(order.direction == Direction.sell,'not sale order');
    order.price = _newPrice;
    emit UpdatePrice(_orderId, _price, _newPrice);
  }

  function makeDeal(uint256 _orderId,uint256 _price,uint256 _tokenId,address _nft)payable external nonReentrant{
    require(_orderId < orderIds.current(),'order does not exist');
    
    Order storage order = orders[_orderId];
    require(order.status == Status.open && block.timestamp <= order.deadline,'order closed');
    require(order.price == _price && order.tokenId == _tokenId && order.nft == _nft,'Order information has changed');
    require(order.creater != _msgSender(),'Cannot trade own orders');
    if(order.otherside != address(0)){
      require(_msgSender() == order.otherside,'you are not that person');
    }
    _checkNftIsAllowed(order);
    
    order.status = Status.close;
    if(order.direction == Direction.buy){
      IERC721(order.nft).safeTransferFrom(_msgSender(), order.creater, order.tokenId);
      require(payable(_msgSender()).send(order.price),'Failed to transfer eth');
    }else{
      IERC721(order.nft).safeTransferFrom(order.creater,_msgSender(), order.tokenId);
      require(payable(order.creater).send(order.price),'Failed to transfer eth');
    }
    emit Clinch(order.nft, order.tokenId, order.price, order.id);
  }

  function _createOrder(address _nft,uint256 _tokenId,uint256 _price,uint256 _deadline,address _otherside,Direction direction)internal{
    uint256 _id = orderIds.current();
    Order memory order =  Order({
      id: _id,
      tokenId: _tokenId,
      price: _price,
      deadline: _deadline,
      nft: _nft,
      otherside: _otherside,
      creater: _msgSender(),
      direction: direction,
      status: Status.open
    });
    orders[_id] = order;
    userOrders[_msgSender()].push(_id);

    orderIds.increment();
    emit CreateOrder(_msgSender(), _id, Direction.sell);
  }


  function _checkOrderInfo(uint256 _orderId,uint256 _price,uint256 _newPrice) internal view {
    require(_orderId < orderIds.current(),'order does not exist');
    require(_price != _newPrice,'why do it');

    Order memory order = orders[_orderId];
    require(order.status == Status.open && block.timestamp <= order.deadline,'order closed');
    require(order.price == _price ,'Order information has changed');
    require(order.creater == _msgSender(),'not your order');
  }

  
  

  function _checkNftIsAllowed(Order memory _order) internal view{
    address nftOwner = _msgSender();
    if(_order.direction == Direction.sell){
      nftOwner = _order.creater;
    }
    address ownerOf = IERC721(_order.nft).ownerOf(_order.tokenId);
    require(nftOwner == ownerOf,'nft does not exist');

    address approvedAddress = IERC721(_order.nft).getApproved(_order.tokenId);
    bool isOperator = IERC721(_order.nft).isApprovedForAll(ownerOf, address(this));
    require(approvedAddress == address(this) || isOperator,'not allowed');
  }
}