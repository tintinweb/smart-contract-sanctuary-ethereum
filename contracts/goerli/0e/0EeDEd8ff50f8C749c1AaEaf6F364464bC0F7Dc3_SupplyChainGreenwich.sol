// SPDX-License-Identifier: Undefined
pragma solidity 0.8.17;

contract SupplyChainGreenwich {


    // RANDOM ADDRESSES!!
    // Tesco: 0xaA1ff6275788BA755bECEeb1161e24c3164072c9
    // Waitrose: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // Sainsbury's: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
    // Morrisons: 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB



    mapping (address => Order[]) public orders;
    mapping(string => address) public companies;

    struct Order {
        uint timestamp;
        string name;
        uint256 priceGBP;
        string status;
    }

    constructor() {

        //Assign company names
        companies["Tesco"] = 0xaA1ff6275788BA755bECEeb1161e24c3164072c9;
        companies["Waitrose"] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        companies["Sainsbury's"] = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        companies["Morrisons"] = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;


        //Random Tesco orders
        orders[companies["Tesco"]].push(Order(block.timestamp, "Milk", 7500, "In transit"));
        orders[companies["Tesco"]].push(Order(block.timestamp, "Bread", 10250, "Delivered"));
        orders[companies["Tesco"]].push(Order(block.timestamp, "Eggs", 2500, "Delivered"));
        orders[companies["Tesco"]].push(Order(block.timestamp, "Butter", 1250, "In transit"));       

        //Random Waitrose orders
        orders[companies["Waitrose"]].push(Order(block.timestamp, "Coca-Cola", 1200, "In transit"));
        orders[companies["Waitrose"]].push(Order(block.timestamp, "Sugar", 3000, "In transit"));
        orders[companies["Waitrose"]].push(Order(block.timestamp, "Nutella", 5000, "Delivered"));  
        orders[companies["Waitrose"]].push(Order(block.timestamp, "Bananas", 750, "Delivered")); 

        // Random Sainsbury's orders
        orders[companies["Sainsbury's"]].push(Order(block.timestamp, "Chicken", 5000, "In transit"));
        orders[companies["Sainsbury's"]].push(Order(block.timestamp, "Pork", 7500, "Delivered"));
        orders[companies["Sainsbury's"]].push(Order(block.timestamp, "Beef", 10000, "Delivered"));
        orders[companies["Sainsbury's"]].push(Order(block.timestamp, "Lamb", 12500, "In transit"));

        // Random Morrisons orders
        orders[companies["Morrisons"]].push(Order(block.timestamp, "Pasta", 2500, "In transit"));
        orders[companies["Morrisons"]].push(Order(block.timestamp, "Rice", 3000, "Delivered"));
        orders[companies["Morrisons"]].push(Order(block.timestamp, "Tomatoes", 5000, "Delivered"));
        orders[companies["Morrisons"]].push(Order(block.timestamp, "Potatoes", 7500, "In transit"));
    }



    function addNewOrder(
        string calldata _name,
        uint256 _priceGBP, 
        string calldata status
        ) 
        public 
    {
        Order memory newOrder = Order(block.timestamp, _name, _priceGBP, status);

        // We are Tesco
        orders[msg.sender].push(newOrder);
    }


}