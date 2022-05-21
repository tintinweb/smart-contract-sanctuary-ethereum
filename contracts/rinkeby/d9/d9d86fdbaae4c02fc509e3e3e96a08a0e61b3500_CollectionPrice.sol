/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract CollectionPrice {
    uint256 public price;

    constructor() {
        price = 1000;
    }

    function changePrice(uint256 _price) external {
        price = _price;
    }
}