// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract P2PConveyance {
    uint256 private counter;

    constructor() {
        counter = 0;
    }

    struct Item {
        string itemName;
        uint256 itemQuantity;
        uint256 itemPrice;
    }

    struct Restaurant {
        string name;
        string lat;
        string long;
        string contact;
    }

    struct Customer {
        string name;
        string lat;
        string long;
        string contact;
    }

    struct DeliveryAgent {
        string name;
        string contact;
    }

    struct OrderInfo {
        uint256 id;
        Item[] items;
        Restaurant restaurant;
        Customer customer;
        DeliveryAgent deliveryAgent;
        uint256 restPrice;
        uint256 delPrice;
        bool hasBeenDelivered;
    }

    event orderStatusChanged(
        uint256 id,
        string restaurantName,
        string customerName,
        string deliveryAgentName,
        bool hasBeenDelivered
    );

    //find utility of this
    mapping(uint256 => OrderInfo) private orders;
    // uint256[] private orderIds;

    mapping(address => uint256) private deliveryAgentOwedBalance;

    // add more require checks with orderIds array (check presence before accessing)
    function confirmOrderSubmission(
        Item[] memory items,
        Restaurant memory restaurant,
        Customer memory customer,
        DeliveryAgent memory deliveryAgent,
        uint256 restPrice,
        uint256 delPrice,
        address _restaurant,
        address _deliveryAgent
    ) public payable returns (uint256) {
        require(
            (restPrice + delPrice) == msg.value,
            "You must pay the exact amount required for order completion!"
        );

        OrderInfo storage newOrder = orders[counter];

        for (uint256 i = 0; i < items.length; i++) {
            newOrder.items.push(items[i]);
        }

        //possible error is need for pointer that persists i.e create a new function that returns persistent restaurant etc pointers
        newOrder.restaurant = restaurant;
        newOrder.deliveryAgent = deliveryAgent;
        newOrder.customer = customer;
        newOrder.restPrice = restPrice;
        newOrder.delPrice = delPrice;
        newOrder.hasBeenDelivered = false;
        newOrder.id = counter;
        // orderIds.push(counter);

        //possible error is that restPrice and delPrice are not in the proper format for payment
        payable(_restaurant).transfer(restPrice);

        deliveryAgentOwedBalance[_deliveryAgent] += delPrice;
        //for the above we need to add facility to transfer new ERC20 token

        // event: might have to destructure the attributes below for the moralis database to understand (try it first)
        // add indexing for restaurant, customer and delivery agent
        emit orderStatusChanged(
            counter,
            newOrder.restaurant.name,
            newOrder.customer.name,
            newOrder.deliveryAgent.name,
            false
        );
        counter++;

        return (counter - 1);
    }

    function confirmOrderDelivery(uint256 id) public payable {
        require(
            deliveryAgentOwedBalance[msg.sender] > 0,
            "You have already been paid the owed amount!"
        );

        orders[id].hasBeenDelivered = true;
        uint256 amount = deliveryAgentOwedBalance[msg.sender];
        payable(msg.sender).transfer(orders[id].delPrice);
        amount -= orders[id].delPrice;
        deliveryAgentOwedBalance[msg.sender] = amount;

        // event: might have to destructure the attributes below for the moralis database to understand (try it first)
        // add indexing for restaurant, customer and delivery agent
        emit orderStatusChanged(
            id,
            orders[id].restaurant.name,
            orders[id].customer.name,
            orders[id].deliveryAgent.name,
            true
        );

        // add functionality to delete the order created, to not make it persist (costly)
    }

    // ---order fields---
    // uint256 id;
    // Item[] items;
    // string restaurantName;
    // string restaurantLat;
    // string restaurantLong;
    // string restaurantContact;
    // string customerName;
    // string customerLat;
    // string customerLong;
    // string customerContact;
    // string deliveryAgentName;
    // string deliveryAgentContact;
    // uint256 restPrice;
    // uint256 delPrice;
    // bool hasBeenDelivered;

    function getOrder(uint256 id) public view returns (OrderInfo memory) {
        require(id < counter, "No such Order!");
        return orders[id];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getDeliveryAgentOwedBalance(address _deliveryAgent)
        public
        view
        returns (uint256)
    {
        return deliveryAgentOwedBalance[_deliveryAgent];
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }

    function getOrderHasBeenDelivered(uint256 id) public view returns (bool) {
        return orders[id].hasBeenDelivered;
    }
}