/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract deal {

    address payable public immutable OWNER;

    mapping(uint => address) public customerOrder;

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

    //Modifiers
    modifier onlyOwner() {
        require(payable(msg.sender) == OWNER, "Not owner");
        _;
    }

    modifier onlyCustomer(address customerAddress, uint orderNumber) {
        require(customerOrder[orderNumber] == customerAddress, "Customer does not have this order");
        _;
    }

    modifier withdraw(uint orderNumber) {
        _;
        uint amount = orders[orderNumber].amount;
        (bool success, ) = OWNER.call{value: amount}("");
        orders[orderNumber].amount = 0;
        require(success, "Failed to send Ether");
    }

    event Payment(address indexed from, uint256 indexed orderId, uint256 value);

    function getOrderData(uint256 orderNumber) public view returns (address, uint, uint, bool, bool, bool) {
        return (
        orders[orderNumber].customerAddress,
        orders[orderNumber].orderNumber,
        orders[orderNumber].amount,
        orders[orderNumber].customerApprove,
        orders[orderNumber].merchantApprove,
        orders[orderNumber].isRefunded
        );
    }

    //client pay function
    function pay(uint256 orderNumber) public payable {
        orders[orderNumber] = Order(msg.sender, orderNumber, msg.value, false, false ,false);
        customerOrder[orderNumber] = msg.sender;

        emit Payment(msg.sender, orderNumber, msg.value);
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

    function withdrawAll() public onlyOwner
    {
        uint amount = address(this).balance;
        (bool success, ) = OWNER.call{value: amount}("");

        require(success, "Failed to send Ether");
    }

    function merchantApprove(uint256 orderNumber) public onlyOwner {
        orders[orderNumber].merchantApprove = true;
    }

    function customerApprove(uint256 orderNumber) public onlyCustomer(msg.sender, orderNumber) {
        orders[orderNumber].customerApprove = true;
    }

    function refund(uint256 orderNumber) public onlyOwner {
        orders[orderNumber].isRefunded = true;
    }

    function claimMoney(uint256 orderNumber) public onlyCustomer(msg.sender, orderNumber) {
        require(orders[orderNumber].isRefunded || !orders[orderNumber].merchantApprove, "Refund is not approved");
        address payable claimCustomerAddress = payable(msg.sender);
        uint256 amount = orders[orderNumber].amount;
        orders[orderNumber].amount = 0;
        (bool success, ) = claimCustomerAddress.call{value: amount}("");

        require(success, "Failed to send Ether");
    }
}