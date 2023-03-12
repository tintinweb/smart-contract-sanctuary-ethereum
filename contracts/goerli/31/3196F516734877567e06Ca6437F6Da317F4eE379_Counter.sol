/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Counter{
    uint public cnt;
    address public owner;

    constructor(){
        owner = msg.sender;
    }
    function add(uint number) public {
        cnt += number;
    }

    function count() onlyOwner public view returns(uint){
        return cnt;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only owner can call count function");
        _;
    }
}