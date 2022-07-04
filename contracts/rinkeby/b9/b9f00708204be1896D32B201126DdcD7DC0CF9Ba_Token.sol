/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.9.0;



contract Token {
    string public name = "USXT Token";
    string public symbol = "USXT";
    uint256 public totalSupply = 10000;

    address public owner;

    mapping(address => uint256) balances;

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        
        require(balances[msg.sender] >= amount, "Not enough tokens");
        balances[msg.sender] -= amount; //balances[msg.sender]=balances[msg.sender]-amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}