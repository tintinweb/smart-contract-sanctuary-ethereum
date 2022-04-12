// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contract for Loyalty Points 
/// @author Gunasundaram
/// @notice Customer can earn enroll for a loyalty program, earn loyalty points when purchasing an item and view balance loyalty points
/// @dev More functions to be added later 

contract Loyalty {
  address payable public owner;
  address payable public buyer;
  uint public itemSequence;
  uint public orderSequence;

  struct item {
    uint itemId;
    string itemName;
    uint price;
    uint points;
    address supplierAddress;
  }

  struct customer {
    address customerAddress;
    bool isEnrolled;
    uint pointsEarned;
  }

  struct order {
    uint orderId;
    uint itemId;
    address customerAddress;
  } 
  
  mapping (uint => item) public items;
  item[] public allItems; 

  mapping (address => customer) public customers;
  customer[] public allCustomers;

  mapping (uint => order) public orders;
  order[] public allOrders;

  constructor (address _buyer) {
    owner = payable(msg.sender);
    buyer = payable(_buyer);
  }

  modifier isOwner() {
    require (msg.sender == owner, "Not the Owner!");
    _;
  }

  modifier isEnrolled(address payable _buyerAddress) {
    require (customers[_buyerAddress].isEnrolled, "Not Enrolled");
    _;
  }

  modifier paidEnough(uint _itemId) {
    uint _price = items[_itemId].price; 
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _itemId, address payable _buyerAddress) {
    _;
    uint _price = items[_itemId].price;
    uint _amountToRefund = msg.value - _price;
    _buyerAddress.transfer(_amountToRefund);
  }

  /// @notice Emitted when customer enrolls for loyalty program
  event ItemAdded(uint itemId, string itemName, uint price, uint points, address sellerAddress);

  /// @notice Emitted when customer buys an item  
  event ItemOrdered(uint orderId, uint itemId, string itemName, uint price, uint points, address buyerAddress, address sellerAddress);

  /// @notice Emitted when customer enrolls for loyalty program
  event CustomerEnrolled(address buyerAddress, bool isEnrolled);
  
  /// @notice Emitted when customer earns loyalty points
  event CustomerEarnedLoyaltyPoints(address buyerAddress, uint points);

  /// @notice Add Item 
  function addItem(string memory _itemName, uint _price, uint _points) public returns (uint) {
    item memory _newItem;
    uint _newItemId = ++itemSequence;
    
    _newItem = item(_newItemId, _itemName, _price, _points, owner);
    items[_newItemId] = _newItem;

    emit ItemAdded(_newItemId, _itemName, _price, _points, owner); 
    allItems.push(_newItem);

    return _newItemId;
  }

  /// @notice Returns Item
  function getItem(uint _itemId) public view returns (uint itemId, string memory itemName, uint price, uint points, address sellerAddress) { 
     itemId = items[_itemId].itemId; 
     itemName = items[_itemId].itemName; 
     price = items[_itemId].price; 
     points = items[_itemId].points;
     return (itemId, itemName, price, points, owner); 
  } 

  /// @notice Order item and if customer has enrolled and loyalty points applicable, it is earned by the customer
  function buyItem(uint _itemId) payable public 
    returns(uint orderId, uint itemId, string memory itemName, uint price, uint points, address buyerAddress, address supplierAddress) {
    
    string memory _itemName;
    uint _points;
    uint _price;
    order memory _newOrder;
    uint _newOrderId = ++orderSequence;

    //Purchased Item
    _itemName = items[_itemId].itemName;
    _price = items[_itemId].price;
    _points = items[_itemId].points;

    //msg.sender must be "buyer" and the price must be equal to the msg.value
    require(msg.sender == buyer);

    //transfer the price 

    (bool success,) = owner.call{value : _price}("");

    //Order 
    _newOrder = order(_newOrderId, _itemId, msg.sender);
    orders[_newOrderId] = _newOrder;

    //increment the loyalty points earned by the customer 
    customers[msg.sender].pointsEarned += _points; 
    emit CustomerEarnedLoyaltyPoints(msg.sender, _points);

    //Emit ItemOrdered event and add the order
    emit ItemOrdered(_newOrderId, _itemId, _itemName, _price, _points, msg.sender, owner);
    allOrders.push(_newOrder);

    //Return the order information
    return (_newOrderId, _itemId, _itemName, _price, _points, msg.sender, owner);
  }

  /// @notice Customer enrolls for loyalty program
  function enroll(address _customer) public returns (bool){
    require (!customers[_customer].isEnrolled, "Customer Already Enrolled");
    customers[_customer] = customer(_customer, true, 0);
    emit CustomerEnrolled(_customer, true);
    return true;
  }

  /// @notice Checks whether Customer enrolled for the loyalty program
  function isCustomerEnrolled(address _customer) public view returns (bool) {
    require (customers[_customer].customerAddress == _customer, "Invalid Customer");
    if (customers[_customer].isEnrolled) 
      return true;
    else 
      return false;
  }

  /// @notice Returns Customer information
  function getCustomer(address _customer) public view returns (address customerAccount, bool enrolled, uint pointsEarned) { 
    customerAccount = customers[_customer].customerAddress; 
    enrolled = customers[_customer].isEnrolled; 
    pointsEarned = customers[_customer].pointsEarned; 
    return (customerAccount, enrolled, pointsEarned);
  }

  /// @notice Returns Loyalty Points
  function getBalanceLoyaltyPoints() public view returns (uint) {
    return customers[msg.sender].pointsEarned; 
  }

  function getBalance(address account) public view returns (uint256) {
    return account.balance;
  }

  function transferFunds() public payable returns (bool) {
    uint256 amount;
    amount = 1000;
    (bool success,) = owner.call{value : amount}("");
    return success;
  }

}