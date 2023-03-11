// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Counter{

    address public owner;

    uint256 public count;

    constructor(){
        count = 0;
        owner = msg.sender;    
    }

    function add() public{
        require(owner == msg.sender, "not owner");
        count = count + 1;
    }
}