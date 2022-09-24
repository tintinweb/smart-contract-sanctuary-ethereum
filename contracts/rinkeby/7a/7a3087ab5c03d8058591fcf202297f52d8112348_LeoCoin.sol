/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract LeoCoin {

    string public name = "LeoCoin";
    string public symbol = "LCN";
    mapping(address => uint) public balances;
    uint totalSupply = 0;
    
    function mint(uint256 money) public{
        balances[msg.sender] += money;
        totalSupply += money;
    }

    function burn(uint256 money) public {
        balances[msg.sender] -= money;
        totalSupply -= money;
    }

    function transfer(uint256 money, address recipient) public {
        balances[msg.sender] -= money;
        balances[recipient] += money;
    }
}