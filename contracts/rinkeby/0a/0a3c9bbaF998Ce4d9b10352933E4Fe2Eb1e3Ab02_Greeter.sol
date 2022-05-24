/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;


contract Greeter {
    string public name = 'test6';
    string public symbol = "ts6";
    uint public totalsupply = 1000000;
    address public owner;
    mapping(address => uint) balances;

    constructor(){
    balances[msg.sender] = totalsupply;
    owner = msg.sender;
    }

    function transfer(address to, uint amount) external {
    require(balances[msg.sender] >= amount, "Not enough tokens sorry");
    balances[to] += amount; 
    }

    function balanceOf(address account) external view returns(uint) {
    return balances[account];
    }

}