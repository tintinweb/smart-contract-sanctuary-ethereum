/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-Lincense-Identifier: MIT
pragma solidity ^0.8.7;

contract Cron {

    bytes32 public currentPrice; 

    function someFunction(bytes32 _price) public {
        currentPrice = _price;
    }
}