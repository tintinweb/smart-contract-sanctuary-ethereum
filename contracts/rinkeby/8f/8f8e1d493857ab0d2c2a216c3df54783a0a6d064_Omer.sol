/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// File: contracts/Omer.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Omer {

    struct Product{
        address seller;
        uint256 price;
        string name;
    }

    mapping(uint256 => Product) public products;
    uint256 public productId=0;

    function createProduct(string calldata name,uint256 price) external returns(uint256) {
        require(keccak256(abi.encodePacked(name)) != keccak256(abi.encodePacked("")),"name can't be empty");
        products[productId]=Product(
            msg.sender,
            price,
            name
        );
        productId+=1;
        return productId;
    } 

    function sellProduct(uint256 _productId) external payable{
        require(msg.value>=products[_productId].price,"price not enough");
        (bool success, ) = products[_productId].seller.call{value:products[_productId].price}("");
        require(success,"transaction failed miserably unfortunately");
        products[_productId] = Product(
            msg.sender,
            1 ether,
            products[_productId].name
        );
    }

    function setName(uint256 _productId,string calldata newName) external{
        require(_productId<=productId,"this product doesn't exist");
        require(msg.sender == products[_productId].seller,"you arent' alowed to change the name");
        products[_productId].name=newName;
    }

    function setPrice(uint256 _productId, uint256 newPrice) external{
        require(_productId<=productId,"this product doesn't exist");
        require(msg.sender == products[_productId].seller,"you arent' alowed to change the name");
        products[_productId].price=newPrice;
    }

}