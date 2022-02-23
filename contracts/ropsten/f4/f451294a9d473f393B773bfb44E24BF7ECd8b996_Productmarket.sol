/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.5.0;

contract Productmarket{
    uint public productCount=0;
    mapping(uint => Product) public products;
    struct Product{
        uint id;
        string pname;
        uint price;
        address payable owner;
        bool purchased;
    }
    event ProductCreated(
         uint id,
        string pname,
        uint price,
        address payable owner,
        bool purchased
    );
    event productPurchased(
        uint id,
        string pname,
        uint price,
        address payable owner,
        bool purchased
    );

    function createProduct(string memory _pname, uint _price) public payable{
        require(bytes(_pname).length>0);
        require(_price>0);

        productCount++;
        products[productCount]= Product(productCount, _pname,_price,msg.sender,false);
        emit ProductCreated(productCount, _pname,_price,msg.sender,false);
    }


    function purchaseProduct(uint _id) public payable{
        Product memory _product = products[_id];
        address payable _seller = _product.owner;

        require(_product.id>0 && _product.id < productCount);
        require(!_product.purchased);
        require(_seller !=msg.sender);
        _product.owner =msg.sender;
        _product.purchased =true;

        _product.owner = msg.sender;
        _product.purchased = true;
        products[_id]= _product;
        address(_seller).transfer(msg.value);
        emit productPurchased(productCount, _product.pname,_product.price,msg.sender,false);
    }

    
}