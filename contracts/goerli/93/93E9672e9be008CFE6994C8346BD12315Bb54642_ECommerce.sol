//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ECommerce {

    struct Product {
        uint256 price;
        address sellerAddress;
        string productName;
        string description;
    }

    event productPurchased(uint256 indexed id, address indexed buyerAddress);

    mapping(uint256 => Product) private productList;
    uint256 productId;

    constructor() {
        productId = 0;
    }

    function listProduct(uint256 price, string memory productName, string memory description) external {
        productList[productId] = Product(price, msg.sender, productName, description);
        productId++;
    }

    function buyProduct(uint256 id) external payable {
       Product memory product = productList[id];
       address seller = product.sellerAddress;
       uint256 price = product.price;
       (bool success, ) = seller.call{value: price}("");
       require(success, "Transaction failed");
    }

    function knowProducts(uint256 id) external view returns (Product memory product) {
        return productList[id];
    }
}