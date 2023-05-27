// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TrueChain {
    uint COUNTER = 0;

    constructor() {}

    struct Product {
        uint id;
        uint price;
        string name;
        string description;
        address owner;
    }
    mapping(uint => Product) products;

    function addProduct(
        uint _id,
        uint _price,
        string memory _name,
        string memory _description
    ) public {
        products[COUNTER] = Product(
            _id,
            _price,
            _name,
            _description,
            msg.sender
        );
        COUNTER++;
    }

    function getAllProducts() public view returns (Product[] memory) {
        Product[] memory allProducts = new Product[](COUNTER);
        for (uint i = 0; i < COUNTER; i++) {
            allProducts[i] = products[i];
        }
        return allProducts;
    }

    function getProduct(uint _productId) public view returns (Product memory) {
        Product memory product = products[_productId];
        return product;
    }

    function buyProduct(uint _productId) public payable {
        require(msg.value == products[_productId].price, "Enter a valid price");
        payable(address(this)).transfer(msg.value);
        products[_productId].owner = msg.sender;
    }
}