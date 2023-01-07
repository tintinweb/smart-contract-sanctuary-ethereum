/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract Owner{
    address owner;
    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "you ar enot owner");
        _;
    }
}