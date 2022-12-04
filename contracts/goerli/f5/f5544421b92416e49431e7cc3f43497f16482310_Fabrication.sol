/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// File: contracts/LabWork.sol


pragma solidity >=0.7.0 <0.9.0;

// Author: Pedro Adrian Rodriguez Carballares
// Date: 03/13/2022
// Simple SmartContract to control the number of units manufactured and the orders to send these dummy products.
// Main ideas:
// 1. The owner can add and remove admins and can initialize the stock, the orders and the time to change the stock.
// 2. Owner and admins can set the current stock, add new units, mark completed orders and remove users.
// 3. New users can be registered when they are not registered on the map yet.
// 3. Users can increment a new order paying with Ether and can remove themselves from the registration map.
// 4. Anyone can trigger the withdrawal of the balance to the owner

contract Fabrication {
    /** Storage */
    // We need to force a rule, with an owner
    address payable public owner;
    // Number of units manufactured
    uint256 public stockOfUnits;
    // Number of product orders
    uint256 public orders;
    // Admins that have privileges to modify the stock or the orders
    mapping (address => bool) public admins;
    // Registered users that can buy the product
    mapping (address => bool) public users;
    // UNIX Time of the last unit modification
    uint256 public lastChangeTimestamp;
    // Minimum Time to set again units or orders in seconds
    uint256 public minTimestampToSetUnits;

    modifier isOwner() {
        // Better use require than if. Ensures that if it is does not fullfiled we can roll back
        // Only the owner can do this
        require(msg.sender == owner, "You are not the owner of this SmartContract!");
        _; // Put the code of the function that is being modified
    }

    modifier isAuthorized() {
        require(msg.sender == owner || admins[msg.sender] == true, "You are not authorized!");
        _; // The logic of the modified function
    }

    modifier isNotRegistered() {
        require(users[msg.sender] == false, "You are already registered!");
        _; // The logic of the modified function
    }


    modifier isRegistered() {
        require(users[msg.sender] == true, "You are not registered yet!");
        _; // The logic of the modified function
    }

    modifier isAllowed() {
        require(users[msg.sender] == true || msg.sender == owner || admins[msg.sender] == true, "You are not allowed to remove a user!");
        _; // The logic of the modified function
    }

    constructor(uint256 _initialStock, uint256 _minSecondsToSetStock, uint256 _currentOrders) {
        stockOfUnits = _initialStock;
        minTimestampToSetUnits = _minSecondsToSetStock;
        orders = _currentOrders;
        owner = payable(msg.sender);
    }

    function setCurrentStockOfUnits(uint256 _units) isAuthorized public {
        require(block.timestamp > lastChangeTimestamp + minTimestampToSetUnits, "Too early to change units");
        stockOfUnits = _units;
        lastChangeTimestamp = block.timestamp;
    }

    function incrementUnits(uint256 _inc) isAuthorized public {
        stockOfUnits += _inc;
    }

    function completedOrders(uint256 _completedOrders) isAuthorized public {
        require(block.timestamp > lastChangeTimestamp + minTimestampToSetUnits, "Too early to change the completed orders");
        stockOfUnits -=  _completedOrders;
        orders -=  _completedOrders;
    }

    function setOrders(uint256 _orders) isAuthorized public {
        require(block.timestamp > lastChangeTimestamp + minTimestampToSetUnits, "Too early to change orders");
        require(_orders <= stockOfUnits, "Not enough units manufactured!");
        orders = _orders;
        lastChangeTimestamp = block.timestamp;
    }

    function incrementOrders(uint256 _inc) isRegistered payable public {
        require(msg.value >= _inc * 1 ether, "Not enough ethers to increment Orders");
        require(_inc + orders <= stockOfUnits, "Not enough units manufactured!");
        orders += _inc;
    }

    function addAdmin(address _admin) isOwner public {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) isOwner public {
        admins[_admin] = false;
    }

    function registerUser(address _user) isNotRegistered public {
        users[_user] = true;
    }

    function removeUser(address _user) isAllowed public {
        users[_user] = false;
    }

    function balance() private view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public {
        owner.transfer(balance());
    }
}