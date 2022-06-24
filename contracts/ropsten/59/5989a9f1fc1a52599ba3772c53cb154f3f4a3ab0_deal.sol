/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract deal {

    address payable public immutable OWNER;

    mapping(address => uint) public customerOrder;

    struct Order {
        address customerAddress;
        uint orderNumber;
        uint amount;
        bool customerApprove;
        bool merchantApprove;
        bool isRefunded;
    }

    mapping(uint256 => Order) public orders;

    constructor() payable {
        OWNER = payable(msg.sender);
    }


    modifier onlyOwner() {
        require(payable(msg.sender) == OWNER, "Not owner");
        _;
    }

    modifier onlyCustomer(address customerAddress, uint orderNumber) {
        require(customerOrder[customerAddress] == orderNumber, "Customer does not have this order");
        _;
    }

    modifier withdraw(uint orderNumber) {
        _;
        uint amount = orders[orderNumber].amount;
        (bool success, ) = OWNER.call{value: amount}("");
        orders[orderNumber].amount = 0;
        require(success, "Failed to send Ether");
    }

    function pay(uint256 orderNumber) public payable {
        orders[orderNumber] = Order(msg.sender, orderNumber, msg.value, false, false ,false);
        customerOrder[msg.sender] = orderNumber;
    }

    function withdrawNoApprove(uint256 orderNumber) public onlyOwner withdraw(orderNumber)
    {}

    function withdrawOwnerApprove(uint256 orderNumber) public onlyOwner withdraw(orderNumber) {
        require(orders[orderNumber].merchantApprove, "You are not approved this order");
    }

    function withdrawBothApprove(uint256 orderNumber) public onlyOwner withdraw(orderNumber) {
        require(orders[orderNumber].merchantApprove, "You are not approved this order");
        require(orders[orderNumber].customerApprove, "Customer is not approved this order");

    }

    function getOrderData(uint256 orderNumber) public view returns (Order memory) {
        return orders[orderNumber];
    }

    function merchantApprov(uint256 orderNumber) public onlyOwner {
        orders[orderNumber].merchantApprove = true;
    }

    function customerApprove(uint256 orderNumber) public onlyCustomer(msg.sender, orderNumber) {
        orders[orderNumber].customerApprove = true;
    }

    function refund(uint256 orderNumber) public onlyOwner {
        orders[orderNumber].isRefunded = true;
    }

    function claimMoney(uint256 orderNumber) public onlyCustomer(msg.sender, orderNumber) {
        require(orders[orderNumber].isRefunded, "Failed to send Ether");
        address payable claimCustomerAddress = payable(msg.sender);
        uint256 amount = orders[orderNumber].amount;
        orders[orderNumber].amount = 0;
        (bool success, ) = claimCustomerAddress.call{value: amount}("");

        require(success, "Failed to send Ether");
    }
}