/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SecondHandMarket {
    address public owner;
    uint256 public contractBalance;

    //owner is contract deployer
    constructor() {
        owner = msg.sender;
    }

    //struct for product properties
    struct Product {
        string productName;
        bool isSold;
        uint256 price;
        address owner;
        string shippingStatus;
    }

    //Products array initialization
    Product[] public Products;

    //mapping for who owns the product
    mapping(uint256 => address) public productOwner;

    //event for a bought product
    event ProductBought(uint256 indexed productId, string productName, uint256 indexed price);

    //modifier sets owner to msg.sender to ensure contract safety
    modifier OwnerOnly() {
        require(msg.sender == owner, "You are not authorized");
        _;
    }
    
    //only owner can add product with name and price info
    function addProduct (string calldata _name, uint256 _price) OwnerOnly external {
        Products.push(Product({
            productName: _name,
            isSold: false,
            price: _price,
            shippingStatus: "not shipped",
            owner: 0x0000000000000000000000000000000000000000
        }));
    }

    //everybody can buy the product with given id, isSold property is changed to true so there will be only one owner of the product
    function buyProduct(uint256 _id) external payable {
        require(msg.value >= Products[_id].price, "Insufficient fund sent");
        require(Products[_id].isSold == false, "Products is already sold");
        contractBalance += msg.value;
        Products[_id].isSold = true;
        Products[_id].owner = msg.sender;
        productOwner[_id] = msg.sender;
        emit ProductBought(_id, Products[_id].productName, msg.value);
    }

    //if someone bought an item they can check the shipping status
    function checkShippingStatus(uint256 _productId) external view returns(string memory){
        require(Products[_productId].isSold == true, "Product is not sold");
        Product memory productCopy = Products[_productId];
        return (productCopy.shippingStatus);
    }

    //only owner can change the shipping status also item must be sold to change status
    function changeShippingStatus(uint256 _productId, string calldata _status) OwnerOnly external {
        require(Products[_productId].isSold == true, "Product is not sold" );
        Products[_productId].shippingStatus = _status;
    }

    //only owner can withdraw funds either himself or to another address
    function witdraw(uint256 _amount, address payable _to ) OwnerOnly public  {
         require(_amount <= contractBalance, "Insufficient funds");
         _to.transfer(_amount);
         contractBalance -= _amount;
    }
}