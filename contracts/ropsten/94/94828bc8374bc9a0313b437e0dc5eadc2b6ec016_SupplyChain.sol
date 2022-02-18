/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract SupplyChain {
    
   enum Status {Created, Delivering, Delivered, Accepted, Declined}

   Order[] orders;

   struct Order {
       string title;
       string description;
       address supplier;
       address deliveryCompany;
       address customer;
       Status status;
   }

   modifier onlyOrderDeliveryCompany(uint256 _index){
       require(orders[_index].deliveryCompany == msg.sender);
       _;
   }

   modifier onlyCustomer(uint256 _index){
       require(orders[_index].customer == msg.sender);
       _;
   }

   modifier orderCreated(uint256 _index){
       require(orders[_index].status == Status.Created);
       _;
   }

   modifier orderDelivering(uint256 _index){
       require(orders[_index].status == Status.Delivering);
       _;
   }

   modifier orderDelivered(uint256 _index){
       require(orders[_index].status == Status.Delivering);
       _;
   }

   function getOrdersLenght() public view returns (uint256){
       return orders.length;
   }

   function getOrder(
       uint256 _index
   ) public view returns (string memory, string memory, address, address, address, Status){
       Order memory order = orders[_index];
       return (
           order.title,
           order.description, 
           order.supplier, 
           order.deliveryCompany, 
           order.customer, 
           order.status
        );

   }

   function createOrder(
       string memory _title,
       string memory _description,
       address _deliveryCompany,
       address _cutomer
   ) public {
       Order memory order = Order({
           title: _title,
           description: _description,
           supplier: msg.sender,
           deliveryCompany: _deliveryCompany,
           customer: _cutomer,
           status: Status.Created
       });

       orders.push(order);
   }

   function startDeliveryOrder(
       uint256 _index
   ) public onlyOrderDeliveryCompany(_index) orderCreated(_index){
       Order storage order = orders[_index];
       order.status = Status.Delivering;
   }

   function stopDeliveringOrder(
       uint256 _index
   ) public onlyOrderDeliveryCompany(_index) orderDelivering(_index){
       Order storage order = orders[_index];
       order.status = Status.Delivered;
   }

   function acceptOrder(
       uint256 _index
   ) public onlyCustomer(_index) orderDelivered(_index){
       orders[_index].status = Status.Accepted;
   }

   function declineOrder(
       uint256 _index
   ) public onlyCustomer(_index) orderDelivered(_index){
       orders[_index].status = Status.Declined;
   }

}