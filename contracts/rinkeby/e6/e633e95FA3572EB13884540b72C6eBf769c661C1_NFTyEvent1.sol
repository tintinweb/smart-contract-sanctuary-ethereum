/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFTyEvent1 {
    event mintEvent(address indexed contractAddress, uint256 indexed tokenId, uint256 indexed count);
    uint256 tokenId = 1;

    constructor() {}

    function mint() external {
        tokenId = 10101;
        emit mintEvent(msg.sender, tokenId, 123);
    }
}