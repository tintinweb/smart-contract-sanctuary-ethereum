/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Token {
    // Some string type variables to identify the token.
    string public name = "My Hardhat Token";
    string public symbol = "MHT";
    uint256 public totalSupply = 100003;
    address public owner;

    mapping(address => uint256) balances;

    function decimals() public pure returns (uint8){
        return 2;
    }

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}