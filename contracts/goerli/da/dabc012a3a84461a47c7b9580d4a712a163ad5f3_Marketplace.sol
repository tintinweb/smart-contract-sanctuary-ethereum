/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Marketplace {
    string public name;
    address public admin;
    //Variable to track the number of total products on the blockchain
    uint public productCount = 0;
    //Mapping on solidity works like associative arrays with key and value pairs. They provide a place to store the "products" in this case on the blockchain. In this case, a product id will return a product value just like in databases.
    mapping(uint => Product) public products;



    //Solidity allows you to create your own data structures. Here the product struct is akin to a table in a database, to store all the attributes of a product.
    struct Product {
        uint id;
        string name;
        uint price;
        address payable owner;
        bool purchased;
    }

    event ProductCreated(
        uint id,
        string name,
        uint price,
        address payable owner,
        bool purchased
    );

    event ProductPurchased(
        uint id,
        string name,
        uint price,
        address payable owner,
        bool purchased
    );

    constructor(string memory _name, address _admin) {
        name = _name;
        admin = _admin;
    }

    function createProduct(string memory _name, uint _price) public {
        
        //Check that product parameters are correct
        require(bytes(_name).length > 0);
        require(_price > 0);
        //Increment productCount 
        productCount ++;
        //msg is a global keyword in solidity and sender allows you to get the address value of the person who called the function
        products[productCount] = Product(productCount, _name, _price, payable(msg.sender), false);
        //Trigger an event
        emit ProductCreated(productCount, _name, _price, payable(msg.sender), false);
    }

    function purchaseProduct(uint _id) public payable{
        //Fetch product
        Product memory _product = products[_id];
        //Fetch owner
        address payable _seller = _product.owner;
        //Make sure product is valid
        require(_product.id > 0 && _product.id <= productCount);
        require(msg.value >= _product.price);
        require(!_product.purchased);
        require(_seller != payable(msg.sender));
        //Transfer ownership to the buyer
        _product.owner = payable(msg.sender);
        //Mark as purchased
        _product.purchased = true;
        //Update product in mapping
        products[_id] = _product;
        //Pay seller by sending Ether
        (bool succes, bytes memory data) = address(_seller).call{value:msg.value}("");
        require(succes, "fail to send eth");
        //Trigger event
        emit ProductPurchased(productCount, _product.name, _product.price, payable(msg.sender), true);
    }
}