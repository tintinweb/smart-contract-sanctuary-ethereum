/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: AFL-1.1

pragma solidity ^0.8.17;

contract Contador {
    uint256 public num = 0;
    address public owner;

    constructor() {
        owner = msg.sender;
    } 

    function incrementNumber() external {
        num += 1;
    }

    function decrementNumber() external {
        num -= 1;
    }
}