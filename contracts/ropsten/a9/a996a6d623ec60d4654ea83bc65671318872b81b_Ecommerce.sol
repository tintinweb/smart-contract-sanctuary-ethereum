/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
    //compiler version of smart
contract Ecommerce {

    // @notice This contract implements a simple store that can interact with
    // registered customers.
    // @title Widgets Store
    // @author usamakofficial
    address public owner;
    /**
    @notice Contract for maintaining ownership
    */
    constructor (address _owner){
        owner = _owner;
    }
    /**
        @notice Represents a product:
        Product id: @id
        Product name: @title
        Decription: @description
        Amount of items in a single product: @default_amount
    */
    struct product{
        string title;
        string desc;
        address payable seller;
        uint productId;
        uint price;
        address buyer;
        bool delivered;
    }
    uint counter = 1;
    product[] public products;
    event registered(string title, uint productId, address seller);
    event productRemoved(uint productId);
    event bought(uint productId, address buyer);
    event delivered(uint productId);

        // @notice register product here
        // Product id: @id
        // Product name: @name
        // Decription: @description
        // Amount of items in a single product: @default_amount

    function registerProduct (string memory _title, string memory _desc, uint _price) public {
        product memory tempProduct;
        tempProduct.title = _title;
        tempProduct.desc = _desc;
        tempProduct.price = _price * 10**18;
        tempProduct.seller = payable(msg.sender);
        tempProduct.productId = counter;
        products.push(tempProduct);
        counter++;
        emit registered(_title, tempProduct.productId, msg.sender);
    }

        // @notice client buy anything from available stock:
        // Product id: @id
        // Product name: @name
        // Decription: @description
        // Amount of items in a single product: @default_amount
    function buy(uint _productId) payable public{
        require(products[_productId-1].price==msg.value, "please pay the exact price");
        require(products[_productId-1].seller!=msg.sender, "Seller cannot be the buyer");
        products[_productId-1].buyer==msg.sender;
        emit bought(_productId, msg.sender);
    }
    
}