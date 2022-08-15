/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

//SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.9;

contract Token{
    string public name = "My Hardhat Token";
    string public symbol = "MHT";

    uint public totalSupply = 1000000;

    address public owner;
    mapping(address => uint) balances;

    event Transfer(address indexed _from, address _to, uint _value);

    constructor(){
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint amount) external{
        require(balances[msg.sender]>= amount, "Not enough Token");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    function balancesOf(address account) external view returns (uint256){
        return balances[account];
    }

}