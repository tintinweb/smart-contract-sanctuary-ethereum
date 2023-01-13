/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

pragma solidity ^0.8.0;

interface Product {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract Names {
    constructor() {}

    function names(Product[] memory products) external {
        for (uint256 i = 0; i < products.length; i++) {
            products[i].name();
            products[i].symbol();
        }
    }
}