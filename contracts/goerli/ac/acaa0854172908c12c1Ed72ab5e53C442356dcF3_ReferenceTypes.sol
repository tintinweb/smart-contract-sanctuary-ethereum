/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract ReferenceTypes {
    struct Product {
        uint256 price;
        string name;
        bool isAvailable;
    }

    Product public currentProduct;
    Product[] public products;

    uint256 public currentOrder;
    uint256[] public prices;
    string[] public names;

    mapping(uint256 => address) public buyers;
    mapping(string => mapping(address => uint256)) public orders;

    function addProduct(
        uint256 _price,
        string memory _name,
        bool _isAvailable
    ) public {
        Product memory product = Product(_price, _name, _isAvailable);
        currentProduct = product;
        prices.push(_price);
        names.push(_name);
        products.push(product);
    }

    function makeAnOrder(string memory _name) public {
        buyers[++currentOrder] = msg.sender;
        orders[_name][msg.sender]++;
    }

    function getProducts() public view returns(Product[] memory){
        return products;
    }

    function getPrices() public view returns(uint[] memory){
        return prices;
    }

    function getNames() public view returns(string[] memory){
        return names;
    }
}