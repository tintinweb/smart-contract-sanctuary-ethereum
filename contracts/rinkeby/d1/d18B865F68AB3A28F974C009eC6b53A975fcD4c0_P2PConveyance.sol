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

    event logOrderStatusChanged(
        uint256 id,
        Item[] items,
        Restaurant restaurant,
        Customer customer,
        DeliveryAgent deliveryAgent,
        uint256 restPrice,
        uint256 delPrice,
        bool hasBeenDelivered
    );

    //find utility of this
    mapping(uint256 => OrderInfo) private orders;
    uint256[] private orderIds;

    mapping(address => uint256) private deliveryAgentOwedBalance;

    function confirmOrderSubmission(
        Item[] memory items,
        Restaurant memory restaurant,
        Customer memory customer,
        DeliveryAgent memory deliveryAgent,
        uint256 restPrice,
        uint256 delPrice,
        address _restaurant,
        address _deliveryAgent
    ) public payable {
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
        orderIds.push(counter);

        //possible error is that restPrice and delPrice are not in the proper format for payment
        payable(_restaurant).transfer(restPrice);

        deliveryAgentOwedBalance[_deliveryAgent] += delPrice;
        //for the above we need to add facility to transfer new ERC20 token

        emit logOrderStatusChanged(
            counter,
            items,
            restaurant,
            customer,
            deliveryAgent,
            restPrice,
            delPrice,
            false
        );
        counter++;
    }

    function confirmOrderDelivery(uint256 id) public {
        require(
            deliveryAgentOwedBalance[msg.sender] > 0,
            "You have already been paid the owed amount!"
        );

        orders[id].hasBeenDelivered = true;
        uint256 amount = deliveryAgentOwedBalance[msg.sender];
        payable(msg.sender).transfer(amount);
        deliveryAgentOwedBalance[msg.sender] = 0;

        emit logOrderStatusChanged(
            id,
            orders[id].items,
            orders[id].restaurant,
            orders[id].customer,
            orders[id].deliveryAgent,
            orders[id].restPrice,
            orders[id].delPrice,
            true
        );
    }

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
}