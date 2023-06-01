/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

contract ProductContract {
    struct Product {
        uint256 productId;
        string productName;
        string productDescription;
        bytes32 productHash;
    }

    mapping(uint256 => Product) public products;

    function uploadProduct(uint256 productId, string memory productName, string memory productDescription) public {
        bytes32 productHash = keccak256(abi.encodePacked(productId, productName, productDescription));
        products[productId] = Product(productId, productName, productDescription,productHash);
    }
    function getHash(uint256 productId) public view returns (bytes32) {
        return products[productId].productHash;
    }
}