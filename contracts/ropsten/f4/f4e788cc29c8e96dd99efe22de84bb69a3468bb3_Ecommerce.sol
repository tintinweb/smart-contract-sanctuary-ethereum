/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

contract Ecommerce{
    struct  Product{

        // product title , product description, seller's address, price of item, buyer address, deliver
        string title;
        string description;
        address payable seller;
        uint productId;
        uint price;
        address buyer;
        bool delivered;

    }
    uint counter = 1;
    Product[] public products;
    address payable manager;

    bool Destroyed = false;
    modifier isNotDestroyed{
        require(!Destroyed, "contract does not exist");
        _;
    }

    constructor(){
        manager=payable(msg.sender);
    }

    // event to show registered product, price , address and delivery

    event registered(string title, uint productId, address seller);
    event bought (uint productId, address buyer);
    event delivered(uint productId);

    // function to register a product

    function registerProduct(string memory _title, string memory _description, uint _price)public isNotDestroyed{
        require(_price >0, "Product price should be greater than zero" );
        Product memory tempProduct;
        tempProduct.title = _title;
        tempProduct.description = _description;
        tempProduct.price = _price *10**18;
        tempProduct.seller = payable(msg.sender);
        tempProduct.productId = counter;
        products.push(tempProduct);
        counter ++;
        emit registered(_title, tempProduct.productId, msg.sender);

    }

    function buy(uint _productId) public payable isNotDestroyed{
        require (products[_productId-1].price==msg.value, "pay the exact amount for the item");
        // to check if buyer is not seller
         require (products[_productId-1].seller!=msg.sender, "Seller cant be buyer");
         // to check if buyer is true
        products[_productId-1].buyer=msg.sender;
         emit bought(_productId, msg.sender);
    }


    function deliver(uint _productId)public isNotDestroyed{
        require(products[_productId-1].buyer == msg.sender, "only buyer can confirm delivery");
        products[_productId].delivered = true;
        products[_productId-1].seller.transfer(products[_productId-1].price);
        emit delivered (_productId);
    }

    // function Destroy()public{
    //     require(msg.sender==manager, "only manager can call this function");
    //     selfdestruct(manager);
    // }

    function Destroy()public isNotDestroyed{
        require(manager==msg.sender);
        manager.transfer(address(this).balance);
        Destroyed=true;
    }

    fallback ()payable external{
        payable(msg.sender).transfer(msg.value);
    }
}