/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Counter{
    uint256 counter;
    address owner;

    constructor(uint256 x){
        counter = x;
        owner = msg.sender;
    }

    function count() public {
        require(msg.sender == owner,"invalid call !");
        counter +=1; 
    }

}