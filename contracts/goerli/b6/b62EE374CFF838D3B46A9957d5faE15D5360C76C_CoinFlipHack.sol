/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlipHack {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    function flip() public view returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number-1));
        uint256 coinFlip = blockValue / FACTOR;
        return (coinFlip == 1);
    }
}