/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

contract SplitPayment{

    address public owner;

    constructor(address _owner){
        owner= _owner;
    }

    function send(address payable[] memory to, uint[] memory amount) payable onlyOwner public{
        require(to.length == amount.length, "to and amount arrays must have same length ");
        for(uint i=0; i<to.length;i++){
            to[i].transfer(amount[i]);
        }
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner cand send the transfer");
        _;
    }
}