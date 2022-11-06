// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IOrderEscrow.sol';
import './OrderFixed.sol';
import './IOrderFixed.sol';
import './OrderEscrow.sol';
import './OtcErrors.sol';

contract OtcExchange is IOrderEscrow, IOrderFixed, Ownable, ReentrancyGuard {
  uint256 public _platformFee;
  uint256 public _platformFeeDivider;
  uint64 private _totalTrades;
  uint64 private _totalOrders;
  uint64 public lastOrderID;

  // address

  address private _feeReceiver;
  address DEAD = address(0x0000000000000000000000000000000000000000);
  address zero = address(0x000000000000000000000000000000000000dEaD);

  // mappings
  mapping(address => bool) public availableBaseTokens;
  mapping(address => bool) public availableQuoteTokens;
  //  mapping(uint256 => Order) public orders;

  mapping(uint64 => OrderEscrow) private marketsEscrow;
  mapping(uint64 => OrderFixed) private marketsFixed;

  // return wether an order is available or not
  mapping(uint64 => bool) public availableOrderIDs;
  
  event UpdatedAvailableTokenBase(address indexed tokenBase);
  event UpdatedAvailableTokenQuote(address indexed tokenQuote);
  // modifiers

  modifier canCreateOrder(address tokenBase, address tokenQuote) {
    if (!availableBaseTokens[tokenBase]) revert BaseTokenNotAllowed(tokenBase);
    if (!availableQuoteTokens[tokenQuote])
      revert QuoteTokenNotAllowed(tokenQuote);
    _;
  }

  modifier canTakeOrder(uint64 orderID, bool orderClass) {
    if (!isActive(orderID, orderClass))
      revert OrderNotActive(orderID, orderClass);

    if (msg.sender == getMaker(orderID, orderClass))
      revert InvalidTaker(orderID, orderClass, 'You cant take your own order');
    _;
  }

  modifier canCancelOrder(uint64 orderID, bool orderClass) {
    if (msg.sender != getMaker(orderID, orderClass))
      revert InvalidOwner(orderID, orderClass);

    _;
  }

  modifier canUpdateOrder(
    uint64 orderID,
    uint256 amountBase,
    uint256 amountQuote,
    bool orderClass
  ) {
    if (!isActive(orderID, orderClass))
      revert OrderNotActive(orderID, orderClass);
    if (msg.sender != getMaker(orderID, orderClass))
      revert InvalidOwner(orderID, orderClass);
    if (amountBase <= 0) revert InvalidAmount(orderID, orderClass);

    if (orderClass) {
      // updating a fixed order
 
      OrderFixed memory _order = marketsFixed[orderID];

      if (
        _order.orderType &&
        amountQuote > ERC20(_order.tokenQuote).balanceOf(msg.sender)
      ) {
        // buy order, check if maker has enough tokenQuote
        revert InsufficientFunds(
          _order.tokenQuote,
          amountQuote,
          ERC20(_order.tokenQuote).balanceOf(msg.sender)
        );
      } else if (
        !_order.orderType &&
        amountBase > ERC20(_order.tokenBase).balanceOf(msg.sender)
      ) {
        // sell order, check amountBase
        revert InsufficientFunds(
          _order.tokenBase,
          amountBase,
          ERC20(_order.tokenBase).balanceOf(msg.sender)
        );
      }

      if (
        _order.orderType &&
        amountQuote >
        ERC20(_order.tokenQuote).allowance(msg.sender, address(this))
      )
        revert InsufficientAllowance(
          _order.tokenQuote,
          amountQuote,
          ERC20(_order.tokenQuote).balanceOf(msg.sender)
        );

      if (
        !_order.orderType &&
        amountBase >
        ERC20(_order.tokenBase).allowance(msg.sender, address(this))
      )
        revert InsufficientAllowance(
          _order.tokenBase,
          amountBase,
          ERC20(_order.tokenBase).balanceOf(msg.sender)
        );
    }
    _;
  }

  constructor() {
    // to be changed
    _platformFee = 10;
    _platformFeeDivider = 1000;
  }

  function createOrderFixed(
    address tokenBase,
    address tokenQuote,
    uint256 amountBase,
    uint256 amountQuote,
    bool orderType,
    uint64 expirationTime
  )
    external
    nonReentrant
    canCreateOrder(tokenBase, tokenQuote)
    returns (bool success)
  {
    uint64 thisOrderID = lastOrderID + 1;

    // take into account the possibility of trading tokens with different decimals than 18
    uint256 price = ((amountQuote * 10**(18 - ERC20(tokenQuote).decimals())) *
      1e18) / (amountBase * 10**(18 - ERC20(tokenBase).decimals()));

    if (orderType) {
      // buy order
      IERC20 tokenQuoteERC = IERC20(tokenQuote);
      uint256 userBalance = tokenQuoteERC.balanceOf(msg.sender);

      if (userBalance < amountQuote) {
        revert InsufficientFunds(tokenQuote, amountQuote, userBalance);
      }

      if (tokenQuoteERC.allowance(msg.sender, address(this)) < amountQuote)
        revert InsufficientAllowance(
          tokenQuote,
          amountQuote,
          tokenQuoteERC.allowance(msg.sender, address(this))
        );

      emit OrderFixedBuyCreated(
        thisOrderID,
        tokenBase,
        tokenQuote,
        amountBase,
        amountQuote,
        expirationTime
      );
    } else {
      //sell order
      IERC20 tokenBaseERC = IERC20(tokenBase);
      uint256 userBalance = tokenBaseERC.balanceOf(address(msg.sender));
      if (userBalance < amountBase) {
        revert InsufficientFunds(tokenBase, amountBase, userBalance);
      }

      if (tokenBaseERC.allowance(msg.sender, address(this)) < amountBase)
        revert InsufficientAllowance(
          tokenBase,
          amountBase,
          tokenBaseERC.allowance(msg.sender, address(this))
        );

      emit OrderFixedSellCreated(
        thisOrderID,
        tokenBase,
        tokenQuote,
        amountBase,
        amountQuote
      );
    }

    marketsFixed[thisOrderID] = OrderFixed(
      orderType,
      uint64(thisOrderID),
      tokenBase,
      uint64(block.timestamp),
      tokenQuote,
      uint64(expirationTime),
      msg.sender,
      price,
      amountBase,
      amountQuote
      );
    lastOrderID = thisOrderID;

    availableOrderIDs[thisOrderID] = true;
    _totalOrders = _totalOrders + 1;

    return true;
  }

  function takeOrderFixed(uint64 orderID)
    external
    canTakeOrder(orderID, true)
    nonReentrant
    returns (bool success)
  {
    OrderFixed memory orderSelected = marketsFixed[orderID];

    IERC20 tokenQuoteERC = IERC20(orderSelected.tokenQuote);
    IERC20 tokenBaseERC = IERC20(orderSelected.tokenBase);

    if (orderSelected.orderType) {
      // buy order
      if (
        tokenBaseERC.balanceOf(msg.sender) <= orderSelected.amountBase ||
        tokenQuoteERC.balanceOf(orderSelected.maker) <=
        orderSelected.amountQuote
      )
        revert InsufficientFundsOnTakeOrderFixed(
          orderSelected.tokenBase,
          orderSelected.tokenQuote,
          tokenBaseERC.balanceOf(msg.sender),
          tokenQuoteERC.balanceOf(orderSelected.maker),
          orderSelected.orderType
        );

      // transfer the base tokens to the buyer minus the fees

      tokenBaseERC.transferFrom(
        msg.sender,
        orderSelected.maker,
        orderSelected.amountBase -
          ((orderSelected.amountBase * _platformFee) / _platformFeeDivider)
      );

      // transfer the quote token to the seller minus the fees
      tokenQuoteERC.transferFrom(
        orderSelected.maker,
        msg.sender,
        orderSelected.amountQuote -
          ((orderSelected.amountQuote * _platformFee) / _platformFeeDivider)
      );

      // transfer the fees to the platform

      tokenBaseERC.transferFrom(
        msg.sender,
        _feeReceiver,
        ((orderSelected.amountBase * _platformFee) / _platformFeeDivider)
      );

      tokenQuoteERC.transferFrom(
        orderSelected.maker,
        _feeReceiver,
        orderSelected.amountQuote -
          ((orderSelected.amountQuote * _platformFee) / _platformFeeDivider)
      );

      // order fulfilled, delete from the market orders
      delete marketsFixed[orderID];
      delete availableOrderIDs[orderID];

      _totalOrders = _totalOrders - 1;

      emit OrderFixedFulFilled(
        orderID,
        orderSelected.tokenBase,
        orderSelected.tokenQuote
      );

      return true;
    } else {
      // sell order
      if (
        tokenBaseERC.balanceOf(orderSelected.maker) <=
        orderSelected.amountBase ||
        tokenQuoteERC.balanceOf(msg.sender) <= orderSelected.amountQuote
      )
        revert InsufficientFundsOnTakeOrderFixed(
          orderSelected.tokenBase,
          orderSelected.tokenQuote,
          tokenBaseERC.balanceOf(orderSelected.maker),
          tokenQuoteERC.balanceOf(msg.sender),
          orderSelected.orderType
        );

      // transfer the quote token to the seller (maker)
      tokenQuoteERC.transferFrom(
        msg.sender,
        orderSelected.maker,
        orderSelected.amountQuote -
          ((orderSelected.amountQuote * _platformFee) / _platformFeeDivider)
      );

      // transfer the base tokens to the buyer (sender)
      tokenBaseERC.transferFrom(
        orderSelected.maker,
        msg.sender,
        orderSelected.amountBase -
          ((orderSelected.amountBase * _platformFee) / _platformFeeDivider)
      );

      // transfer the fees to the platform

      tokenBaseERC.transferFrom(
        orderSelected.maker,
        _feeReceiver,
        ((orderSelected.amountBase * _platformFee) / _platformFeeDivider)
      );

      tokenQuoteERC.transferFrom(
        msg.sender,
        _feeReceiver,
        ((orderSelected.amountQuote * _platformFee) / _platformFeeDivider)
      );

      // check if order is fully filled
      delete marketsEscrow[orderID];
      delete availableOrderIDs[orderID];

      emit OrderFixedFulFilled(
        orderID,
        orderSelected.tokenBase,
        orderSelected.tokenQuote
      );
      return true;
    }
  }

  function cancelOrderFixed(uint64 orderID)
    external
    canCancelOrder(orderID, true)
    nonReentrant
    returns (bool success)
  {
    OrderFixed memory _orderToBeCancelled = marketsFixed[orderID];
    delete marketsFixed[orderID];
    delete availableOrderIDs[orderID];
    _totalOrders = _totalOrders - 1;

    emit OrderFixedCancelled(
      orderID,
      _orderToBeCancelled.tokenBase,
      _orderToBeCancelled.tokenQuote
    );
    return true;
  }

  function updateOrderFixed(
    uint64 orderID,
    uint256 amountBase,
    uint256 amountQuote,
    uint64 expirationTime
  )
    external
    canUpdateOrder(orderID, amountBase, amountQuote, true)
    nonReentrant
    returns (bool success)
  {
    OrderFixed memory oldOrder = marketsFixed[orderID];

    uint256 price = ((amountQuote *
      10**(18 - ERC20(oldOrder.tokenQuote).decimals())) * 1e18) /
      (amountBase * 10**(18 - ERC20(oldOrder.tokenQuote).decimals()));

    marketsFixed[orderID] = OrderFixed(
      oldOrder.orderType,
      orderID,
      oldOrder.tokenBase,
      uint64(block.timestamp),
      oldOrder.tokenQuote,
      expirationTime,
      oldOrder.maker,
      price,
      amountBase,
      amountQuote
      );

    emit OrderFixedUpdated(
      orderID,
      oldOrder.tokenBase,
      oldOrder.tokenQuote,
      amountBase,
      price,
      oldOrder.orderType,
      uint64(block.timestamp),
      expirationTime
    );
    return true;
  }

  function createOrderEscrow(
    address tokenBase,
    address tokenQuote,
    uint256 amountBase,
    uint256 amountQuote,
    bool orderType
  ) external nonReentrant returns (bool success) {

    if (!availableBaseTokens[tokenBase]) 
      revert BaseTokenNotAllowed(tokenBase);
    if (!availableQuoteTokens[tokenQuote])
      revert QuoteTokenNotAllowed(tokenQuote);

    uint64 thisOrderID = lastOrderID + 1;

    uint256 price = ((amountQuote * 10**(18 - ERC20(tokenQuote).decimals())) *
      1e18) / (amountBase * 10**(18 - ERC20(tokenBase).decimals()));

    if (orderType) {
      IERC20 tokenQuoteERC = IERC20(tokenQuote);
      uint256 userBalance = tokenQuoteERC.balanceOf(address(msg.sender));
      if (userBalance < amountQuote) {
        revert InsufficientFunds(tokenQuote, amountQuote, userBalance);
      }

      // transfer funds
      tokenQuoteERC.transferFrom(msg.sender, address(this), amountQuote);

      emit OrderEscrowBuyCreated(
        thisOrderID,
        tokenBase,
        tokenQuote,
        amountBase,
        amountQuote
      );
    } else {
      IERC20 tokenBaseERC = IERC20(tokenBase);
      uint256 userBalance = tokenBaseERC.balanceOf(address(msg.sender));
      if (userBalance < amountBase) {
        revert InsufficientFunds(tokenBase, amountBase, userBalance);
      }

      tokenBaseERC.transferFrom(msg.sender, address(this), amountBase);

      emit OrderEscrowSellCreated(
        thisOrderID,
        tokenBase,
        tokenQuote,
        amountBase,
        amountQuote
      );
    }

    marketsEscrow[thisOrderID] = OrderEscrow(
      orderType,
      thisOrderID,
      tokenBase,
      tokenQuote,
      uint64(block.timestamp),
      msg.sender,
      price,
      amountBase,
      amountQuote
    );

    lastOrderID = thisOrderID;
    availableOrderIDs[thisOrderID] = true;
    _totalOrders = _totalOrders + 1;

    return true;
  }

  function takeOrderEscrow(uint64 orderID, uint256 amountToken)
    external
    canTakeOrder(orderID, false)
    nonReentrant
    returns (bool success)
  {

    OrderEscrow memory orderSelected = marketsEscrow[orderID];
    ERC20 tokenQuoteERC = ERC20(orderSelected.tokenQuote);
    ERC20 tokenBaseERC = ERC20(orderSelected.tokenBase);

    uint256 quoteDecimals = tokenQuoteERC.decimals();
    uint256 baseDecimals = tokenBaseERC.decimals();

    if (orderSelected.orderType) {
      /// buy order
      if (amountToken < 0 || amountToken > orderSelected.amountBase)
        revert InvalidAmount(orderID, orderSelected.orderType);

      // amountToken is the amount of tokenBase I want to buy
      uint256 amountQuote = amountToken * orderSelected.price;



      // adapt to any type of decimal's combination
      if ( 
          quoteDecimals > baseDecimals
        )
      {
        amountQuote = amountQuote / 10 ** ( 18 - (quoteDecimals - baseDecimals));
      }
      else
      {
        amountQuote = amountQuote / 10 ** ( 18 - (baseDecimals - quoteDecimals));
      }

      
      if (amountToken > tokenBaseERC.balanceOf(msg.sender))
        revert InsufficientFunds(
          orderSelected.tokenBase,
          amountToken,
          tokenBaseERC.balanceOf(msg.sender)
        );

      tokenBaseERC.transferFrom(
        msg.sender,
        orderSelected.maker,
        amountToken - ((amountToken * _platformFee) / _platformFeeDivider)
      );

      tokenQuoteERC.transfer(
        msg.sender,
        amountQuote - ((amountQuote * _platformFee) / _platformFeeDivider)
      );

      // take fees

      tokenQuoteERC.transfer(
        _feeReceiver,
        (amountQuote * _platformFee) / _platformFeeDivider
      );

      tokenBaseERC.transferFrom(
        msg.sender,
        _feeReceiver,
        ((amountToken * _platformFee) / _platformFeeDivider)
      );

      // check if order is fully filled

      marketsEscrow[orderID].amountBase =
        orderSelected.amountBase -
        amountToken;

      marketsEscrow[orderID].amountQuote =
        orderSelected.amountQuote -
        amountQuote;

      if (orderSelected.amountBase == 0) {
        delete marketsEscrow[orderID];

        delete availableOrderIDs[orderID];
        emit OrderEscrowFulFilled(
          orderID,
          orderSelected.tokenBase,
          orderSelected.tokenQuote
        );

        _totalOrders = _totalOrders - 1;
        _totalTrades = _totalTrades + 1;

        return true;
      }

      emit OrderEscrowPartialFilled(
        orderID,
        amountToken,
        orderSelected.amountBase
      );

      return true;
    } else {
      // sell order

      if (amountToken < 0 || amountToken > orderSelected.amountQuote)
        revert InvalidAmount(orderID, orderSelected.orderType);

      //  amountToken is the amount of tokenQuote I want to get by selling
      uint256 amountBase = (amountToken * 1e18) / orderSelected.price;

      if ( 
          quoteDecimals > baseDecimals
        )
      {
         amountBase = amountBase / 10 ** ( 18 - (quoteDecimals - baseDecimals));
      }
      else if (
          baseDecimals > quoteDecimals
        )
      {
        amountBase = amountBase  / 10 ** ( 18 - (baseDecimals - quoteDecimals));
      } 

      if (amountToken > tokenQuoteERC.balanceOf(msg.sender))
        revert InsufficientFunds(
          orderSelected.tokenQuote,
          amountToken,
          tokenQuoteERC.balanceOf(msg.sender)
        );

      tokenQuoteERC.transferFrom(
        msg.sender,
        orderSelected.maker,
        amountToken - ((amountToken * _platformFee) / _platformFeeDivider)
      );

      tokenBaseERC.transfer(
        msg.sender,
        amountBase - ((amountBase * _platformFee) / _platformFeeDivider)
      );

      // take fees

      tokenBaseERC.transfer(
        _feeReceiver,
        ((amountBase * _platformFee) / _platformFeeDivider)
      );

      tokenQuoteERC.transferFrom(
        msg.sender,
        _feeReceiver,
        ((amountToken * _platformFee) / _platformFeeDivider)
      );

      marketsEscrow[orderID].amountBase =
        orderSelected.amountBase -
        amountBase;

      marketsEscrow[orderID].amountQuote =
        marketsEscrow[orderID].amountQuote -
        amountToken;

      if (marketsEscrow[orderID].amountQuote == 0) {
        delete marketsEscrow[orderID];
        delete availableOrderIDs[orderID];
        emit OrderEscrowFulFilled(
          orderID,
          orderSelected.tokenBase,
          orderSelected.tokenQuote
        );
        _totalOrders = _totalOrders - 1;
        _totalTrades = _totalTrades + 1;

        return true;
      }

      emit OrderEscrowPartialFilled(
        orderID,
        marketsEscrow[orderID].amountBase,
        marketsEscrow[orderID].amountQuote
      );

      _totalTrades = _totalTrades + 1;

      return true;
    }
  }

  function cancelOrderEscrow(uint64 orderID)
    external
    canCancelOrder(orderID, false)
    nonReentrant
    returns (bool success)
  {
    OrderEscrow memory _orderToBeDeleted = marketsEscrow[orderID];

    if (_orderToBeDeleted.orderType) {
      // buy order

      IERC20 tokenQuoteERC = IERC20(_orderToBeDeleted.tokenQuote);
      tokenQuoteERC.transfer(msg.sender, _orderToBeDeleted.amountQuote);
    } else {
      // sell order

      IERC20 tokenBaseERC = IERC20(_orderToBeDeleted.tokenBase);
      tokenBaseERC.transfer(msg.sender, _orderToBeDeleted.amountBase);
    }

    delete marketsEscrow[orderID];
    delete availableOrderIDs[orderID];
    _totalOrders = _totalOrders - 1;

    emit OrderEscrowCancelled(
      orderID,
      _orderToBeDeleted.tokenBase,
      _orderToBeDeleted.tokenQuote
    );

    return true;
  }

  function updateOrderEscrow(
    uint64 orderID,
    uint256 amountBase,
    uint256 amountQuote
  )
    external
    canUpdateOrder(orderID, amountBase, amountQuote, false)
    nonReentrant
    returns (bool success)
  {
    if (!availableOrderIDs[orderID]) {
      revert OrderIDDoesNotExists({orderID: orderID});
    }

    OrderEscrow memory oldOrder = marketsEscrow[orderID];

    uint256 price = ((amountQuote *
      10**(18 - ERC20(oldOrder.tokenQuote).decimals())) * 1e18) /
      (amountBase * 10**(18 - ERC20(oldOrder.tokenBase).decimals()));

    if (oldOrder.orderType) {
      // buy order

      if (amountQuote > oldOrder.amountQuote) {
        IERC20(oldOrder.tokenQuote).transferFrom(
          msg.sender,
          address(this),
          (amountQuote - oldOrder.amountQuote)
        );
      } else {
        IERC20(oldOrder.tokenQuote).transfer(
          msg.sender,
          (oldOrder.amountQuote - amountQuote)
        );
      }
    } else {
      // sell order
      if (amountBase > oldOrder.amountBase) {
        IERC20(oldOrder.tokenBase).transferFrom(
          msg.sender,
          address(this),
          (amountBase - oldOrder.amountBase)
        );
      } else {
        IERC20(oldOrder.tokenBase).transfer(
          msg.sender,
          (oldOrder.amountBase - amountBase)
        );
      }
    }

    marketsEscrow[orderID] = OrderEscrow(
      oldOrder.orderType,
      orderID,
      oldOrder.tokenBase,
      oldOrder.tokenQuote,
      uint64(block.timestamp),
      oldOrder.maker,
      price,
      amountBase,
      amountQuote
    );

    emit OrderEscrowUpdated(
      orderID,
      oldOrder.tokenBase,
      oldOrder.tokenQuote,
      amountBase,
      price,
      oldOrder.orderType,
      uint64(block.timestamp)
    );

    return true;
  }

  // getter functions

  /**
   *   @dev Return the address of the platform's fees reciever.
   */
  function getfeeReceiver() external view returns (address feeReceiver) {
    return _feeReceiver;
  }

  /**
   *   @dev Function that returns the total amount of orders divided by type and the
   *   total amount of trades.
   */
  function getPlatformStatistics()
    external
    view
    returns (uint64 totalOrders, uint64 totalTrades)
  {
    return (_totalOrders, _totalTrades);
  }

  // setter functions

  /**
   *   @dev Set the reciever of the escrow platform fees
   *   @param feeReceiver address of the wallet recieving the platform fees
   */
  function setfeeReceiver(address feeReceiver) external onlyOwner {
    if (feeReceiver == DEAD || feeReceiver == zero)
      revert InvalidFeesReceiver(feeReceiver);

    _feeReceiver = feeReceiver;
  }

  /**
   *   @dev Set the amount of fees taken by the escrow platform
   *   @param platformFee quantity of fees for going to the platform
   */
  function setFees(uint256 platformFee) external onlyOwner {
    if (platformFee > 20) revert FeesTooHigh(platformFee);

    _platformFee = platformFee;
  }

  /**
   *   @dev Add a Token to the list of available traded tokens
   *   @param newTokenBase The address of the new token available for trading
   *   @param state true if the token is available, else false
   *   Emits a {AddedTokenBase} event
   */
  function setAvailableTokenBase(address newTokenBase, bool state)
    external
    onlyOwner
  {
    availableBaseTokens[newTokenBase] = state;

    emit UpdatedAvailableTokenBase(newTokenBase);
  }

  /**
   *   @dev Add a Token to the list of available quote tokens (that can be paired with each base token)
   *   @param newTokenQuote The address of the new token available for trading
   *   @param state true if the token is available, else false
   *   Emits a {AddedTokenQuote} event
   */
  function setAvailableTokenQuote(address newTokenQuote, bool state)
    external
    onlyOwner
  {
    availableQuoteTokens[newTokenQuote] = state;

    emit UpdatedAvailableTokenQuote(newTokenQuote);
  }

  /**
   *   @dev Check wether a certain fixed order is active or wether a certain escrow order exists
   *   @param orderID ID of the examined order
   *   @param orderClass type of order (true = fixed , false = escrow)
   *   @return true if the fixed order with "orderID" is active or the escrow order exists
   */
  function isActive(uint64 orderID, bool orderClass)
    internal
    view
    returns (bool)
  {
    if (orderClass) {
      // fixed order
      return (marketsFixed[orderID].expirationTime > block.timestamp);
    } else {
      return (availableOrderIDs[orderID]);
    }
  }

  /**
   *   @dev Return the maker of a selected order
   *   @param orderID ID of the examined order
   *   @param orderClass type of order (true = fixed , false = escrow)
   *   @return maker the order maker address
   *
   */
  function getMaker(uint64 orderID, bool orderClass)
    internal
    view
    returns (address maker)
  {
    if (orderClass) {
      // fixed order
      return (marketsFixed[orderID].maker);
    } else {
      // escrow order
      return (marketsEscrow[orderID].maker);
    }
  }

  function getOrderFixed(uint64 orderID)
    external
    view
    returns (OrderFixed memory orderSelected)
  {
    return marketsFixed[orderID];
  }

  function getOrderEscrow(uint64 orderID)
    external
    view
    returns (OrderEscrow memory orderSelected)
  {
    return marketsEscrow[orderID];
  }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;



/**
 * @dev structure definining a Fixed order 
 * A fixed order DOES NOT requires the maker to send his funds to the contract.
 * It has an expiration time, after that the order will be marked as inactive.
 * It can only be fulfilled by one taker that must fill the whole amount. 
 * Attributes:
 * - tokenBase : address of the main token in the pair 
 * - tokenQuote : address of the quate token in the pair 
 * - amountBase : amount of the base token 
 * - amountQuote : amount of the quote token
 * - price: price of the base token, with 18 decimals
 * - orderID : unique ID of the order
 * - orderType: type of the order, true if it is either a buy order , otherwise false.
 * - createdAt: timestamp of the order's creation date
 * - expirationTime: expiration time of the order
 */
struct OrderFixed {
    bool orderType;
    uint64 orderID;
    address tokenBase;
    uint64 createdAt;
    address tokenQuote;
    uint64 expirationTime;
    address maker;
    uint256 price;
    uint256 amountBase;
    uint256 amountQuote;
    }

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./OrderFixed.sol";


interface IOrderFixed {


    event OrderFixedBuyCreated(
        uint64 orderID,
        address indexed tokenBase,
        address indexed tokenQuote,
        uint256 amountBase,
        uint256 amountQuote,
        uint128 expirationTime
    );
    event OrderFixedSellCreated(
        uint64 orderID,
        address indexed tokenBase,
        address indexed tokenQuote,
        uint256 amountBase,
        uint256 amountQuote
    );
    event OrderFixedFulFilled(
        uint64 orderID,
        address indexed tokenBase,
        address indexed tokenQuote
    );

    event OrderFixedCancelled(
        uint64 orderID,
        address indexed tokenBase,
        address indexed tokenQuote
    );

    event OrderFixedUpdated(
        uint64 orderID,
        address indexed tokenBase,
        address indexed tokenQuote,
        uint256 amountBase,
        uint256 price,
        bool orderType,
        uint128 creationTimestamp,
        uint128 expirationTime
    );

    /**
    *   @dev create an Escrew Order
    *
    *   @param tokenBase : address of the main token in the pair
    *   @param tokenQuote : address of the token being exchanged for the main token
    *   @param amountBase : amount of base tokens 
    *   @param amountQuote : amount of tokens exchanged for the main token
    *   @param orderType : type of the order (true: buy, false: sell)
    *   @param expirationTime : expiration timestamp of the order 
    *
    *   Emits a {OrderEscrowBuyCreated} event
    *   Emits a {OrderEscrowSellCreated} event
    */
    function createOrderFixed(
        address tokenBase,
        address tokenQuote,
        uint256 amountBase,
        uint256 amountQuote,
        bool orderType,
        uint64 expirationTime
    ) external returns (bool success);


    /**
    *   @dev Take an fixed Order (only total order filling is allowed)
    *
    *   @param orderID : unique id of the order being canceled
    *
    *   Emits a {OrderFixedFulFilled} event
    */
    function takeOrderFixed(
        uint64 orderID
    ) external returns (bool success);
    


    /**
    *   @dev Cancel a order already created
    *
    *   @param orderID : unique id of the order being canceled
    *
    *   Emits a {OrderEscrowCancelled} event
    */
    function cancelOrderFixed(
        uint64 orderID
    ) external returns (bool success);

    /**
    *   @dev Update a selected fixed order 
    * 
    *   @param orderID : unique id of the order being created
    *   @param amountBase : amount of base tokens 
    *   @param amountQuote : amount of the quote token
    *   @param expirationTime : expiration time of the fixed order 
    *   @return success : true if the order has been successfully created
    *   Emits a {OrderFixedUpdated} event
    */
    function updateOrderFixed(
        uint64 orderID, 
        uint256 amountBase, 
        uint256 amountQuote,
        uint64 expirationTime
    ) external returns (bool success);


    /**
     *   @dev Return a selected fixed order
     *   @param orderID : ID of the examined order
     *   @return orderSelected : the order being selected
     */
    function getOrderFixed(
        uint64 orderID
    ) external view returns (OrderFixed memory orderSelected);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './OrderEscrow.sol';

/**
 * @dev Interface of the Escrow order
 *
 */
interface IOrderEscrow {
  event OrderEscrowBuyCreated(
    uint64 orderID,
    address indexed tokenBase,
    address indexed tokenQuote,
    uint256 amountBase,
    uint256 amountQuote
  );
  event OrderEscrowSellCreated(
    uint64 orderID,
    address indexed tokenBase,
    address indexed tokenQuote,
    uint256 amountBase,
    uint256 amountQuote
  );
  event OrderEscrowPartialFilled(
    uint64  orderID,
    uint256 amountLastBase,
    uint256 amountLastQuote
  );
  event OrderEscrowFulFilled(
    uint64 orderID,
    address indexed tokenBase,
    address indexed tokenQuote
  );

  event OrderEscrowCancelled(
    uint64 orderID,
    address indexed tokenBase,
    address indexed tokenQuote
  );

  event OrderEscrowUpdated(
    uint64 orderID,
    address indexed tokenBase,
    address indexed tokenQuote,
    uint256 amountBase,
    uint256 price,
    bool orderType,
    uint64 creationTimestamp
  );

  /**
   *   @dev create an Escrew Order
   *
   *   @param tokenBase : address of the main token in the pair
   *   @param tokenQuote : address of the token being exchanged for the main token
   *   @param amountBase : amount of base tokens
   *   @param amountQuote : amount of tokens exchanged for the main token
   *   @param orderType : type of the order (true: buy, false: sell)
   *   @return success : true if the order has been successfully created
   *
   *   Emits a {OrderEscrowBuyCreated} event
   *   Emits a {OrderEscrowSellCreated} event
   */
  function createOrderEscrow(
    address tokenBase,
    address tokenQuote,
    uint256 amountBase,
    uint256 amountQuote,
    bool orderType
  ) external returns (bool success);

  /**
    *   @dev Take an escrow Order (only total order filling is allowed)
    *
    *   @param orderID : unique id of the order being canceled
    *   @param amountToken  : amount of tokens being either purchased or sold
    *                         if the order is a buy order amountToken is the token base 
    *                         else amountToken is the token quote
    *   @return success : true if the order has been successfully taken
    *   Emits a {OrderEscrowPartialFilled} event if the order has been partially filled
    *   Emits a {OrderEscrowFulFilled} event if the order has been fulfilled

    */
  function takeOrderEscrow(uint64 orderID, uint256 amountToken)
    external
    returns (bool success);

  /**
   *   @dev Cancel a order already created
   *
   *   @param orderID : unique id of the order being canceled
   *
   *   Emits a {OrderEscrowCancelled} event
   */
  function cancelOrderEscrow(uint64 orderID) external returns (bool success);

  /**
   *   @dev Update a selected fixed order
   *
   *   @param orderID : unique id of the order being created
   *   @param amountBase : amount of base tokens
   *   @param amountQuote : amount of quote tokens
   *   @return success : true if the order has been successfully created
   *   Emits a {OrderFixedUpdated} event
   */
  function updateOrderEscrow(
    uint64 orderID,
    uint256 amountBase,
    uint256 amountQuote
  ) external returns (bool success);

  /**
   *   @dev Return a selected escrow order
   *   @param orderID ID of the examined order
   */
  function getOrderEscrow(uint64 orderID)
    external
    view
    returns (OrderEscrow memory orderSelected);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


/**
 * @dev structure definining an Escrow order 
 * An escrow order requires the maker to send his funds to the contract.
 * It can be partially filled by one or more takers 
 * Attributes:
 * - tokenBase : address of the main token in the pair 
 * - tokenQuote : address of the quate token in the pair 
 * - amountBase : amount of the base token 
 * - amountQuote : amount of the quote token
 * - price: price of the base token, with 18 decimals
 * - orderID : unique ID of the order
 * - orderType: type of the order, true if it is either a buy order , otherwise false.
 * - createdAt: timestamp of the order's creation date
 */
struct OrderEscrow{
    bool orderType;
    uint64 orderID;
    address tokenBase;
    address tokenQuote;
    uint64 createdAt;
    address maker;
    uint256 price;
    uint256 amountBase;
    uint256 amountQuote;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
    

error BaseTokenNotAllowed(address tokenBase);
error QuoteTokenNotAllowed(address tokenQuote);
error OrderIDDoesNotExists(
    uint64 orderID
    );
error InsufficientFunds(
    address tokenAddress, 
    uint256 tokenAmount, 
    uint256 tokenFunds
    );
error OrderNotActive(
    uint64 orderID, 
    bool orderClass
    );
error InvalidOwner(
    uint64 orderID, 
    bool orderClass
    );
error InvalidAmount(
    uint64 orderID, 
    bool orderClass
    );
error InsufficientFundsOnTakeOrderFixed(
    address tokenBase, 
    address tokenQuote, 
    uint256 senderBalance, 
    uint256 makerBalance, 
    bool orderType
    );
error InsufficientAllowance(
    address tokenAddress,
    uint256 tokenAmount,
    uint256 allowance
);
error InvalidTaker(
    uint64 orderID, 
    bool orderClass, 
    string msgError
    );
error InvalidFeesReceiver(address feesReceiver);
error FeesTooHigh(uint256 platformFees);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}