/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SupplyChain {

    enum Status { Created, Delivering, Delivered, Accepted, Declined }

    Order[] public orders;

    struct Order {
        string title;
        string description;
        address supplier;
        address deliveryCompany;
        address customer;
        Status status;
    }

    function creaeOrder(
        string memory _title,
        string memory _description,
        address _deliveryCompany,
        address _customer
    ) public returns (uint256) {
        Order memory order = Order({
            title: _title,
            description: _description,
            supplier: msg.sender,
            deliveryCompany: _deliveryCompany,
            customer: _customer,
            status: Status.Created
        });
        uint256 index = orders.length + 1;
        orders[orders.length + 1] = order;

        return index;
    }

    modifier onlyOrderDeliveryCompany(uint256 _index) {
        require(orders[_index].deliveryCompany == msg.sender);
        _;
    }

    modifier onlyCustomer(uint256 _index) {
        require(orders[_index].customer == msg.sender);
        _;
    }

    modifier orderCreatedStatus(uint256 _index) {
        require(orders[_index].status == Status.Created);
        _;
    }

    modifier orderDeliveringStatus(uint256 _index) {
        require(orders[_index].status == Status.Delivering);
        _;
    }

    modifier orderDeliveredStatus(uint256 _index) {
        require(orders[_index].status == Status.Delivered);
        _;
    }

    modifier orderAcceptedStatus(uint256 _index) {
        require(orders[_index].status == Status.Accepted);
        _;
    }

    function startDeliveryOrder(
        uint256 _index
    ) public onlyOrderDeliveryCompany(_index) orderCreatedStatus(_index) {
        Order storage order = orders[_index];
        order.status = Status.Delivering;
    }

    function stopDeliveringOrder(
        uint256 _index
    ) public onlyOrderDeliveryCompany(_index) orderDeliveringStatus(_index) {
        Order storage order = orders[_index];
        order.status = Status.Delivered;
    }

    function acceptOrder(
        uint256 _index
    ) public onlyCustomer(_index) orderDeliveredStatus(_index) {
        orders[_index].status = Status.Accepted;
    }

    function declineOrder(
        uint256 _index
    ) public onlyCustomer(_index) orderDeliveredStatus(_index) {
        orders[_index].status = Status.Declined;
    }

}