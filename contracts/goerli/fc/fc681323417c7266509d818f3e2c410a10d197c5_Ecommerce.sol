/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Ecommerce{
    struct Product{
        string title;
        string desc;
        address payable seller;
        uint productId;
        uint price;
        address buyer;
        bool delivered;
    }

    uint counter = 1;
    Product[] public products;

    event registered(string title, uint productId, address seller);
    event bought(uint productId, address buyer);
    event delivered(uint productId);

    function registerProduct(string memory _title, string memory _desc, uint _price) public {
        require(_price>0, "price should be greater than 0");
       
       Product memory temProduct;

       temProduct.title = _title;
       temProduct.desc = _desc;
       temProduct.price = _price * 10**8;
       temProduct.seller = payable(msg.sender);
       temProduct.productId = counter;
       products.push(temProduct);
       counter++;
       emit registered(_title, temProduct.productId, msg.sender);


    }

    function buy(uint _productId) payable public{
        require(products[_productId-1].price==msg.value, "please pay the exact price");
        require(products[_productId-1].seller!=msg.sender, "seller can't be the buyer");
        products[_productId-1].buyer =msg.sender;
        emit bought(_productId, msg.sender);
    }

    function delivery(uint _productId) public{
        require(products[_productId-1].buyer == msg.sender, "Only buyer can be deliver");
        products[_productId-1].delivered = true;
        products[_productId-1].seller.transfer(products[_productId-1].price);
        emit delivered(_productId);
    }
  
}