// SPDX-License-Identifier: Undefined
pragma solidity 0.8.17;

contract SupplyChainGreenwich {

    constructor() {
        
    }

    struct Order {
        uint256 id;
        string name;
        uint256 quantity;
        uint256 price;
        string status;
        string date;
    }

    Order[] public orders;

    function addNewOrder(
        string calldata _name, 
        uint256 _quantity, 
        uint256 _price, 
        string calldata _date
        ) 
        public 
    {
        Order memory newOrder = Order(block.timestamp, _name, _quantity, _price, "Pending", _date);
        orders.push(newOrder);
    }


}