/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Token {
    string token = "Hardhat";
    string Symbal = "HHT";
    uint public totalsupply = 1000;

    address public owner;

    mapping(address=>uint) balance;

    constructor(){
        balance[msg.sender] = totalsupply;
        owner = msg.sender;
    }

    function transfer(address to, uint amount) external{
        require(balance[msg.sender]>=amount, "Not Enought Token");
        balance[msg.sender] -= amount;
        balance[to] += amount;
    }

    function balanceof(address account) external view returns(uint){
        return balance[account];
    }
}