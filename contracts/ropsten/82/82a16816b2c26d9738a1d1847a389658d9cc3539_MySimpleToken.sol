/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MySimpleToken {
    string public name = "My Simple Token";
    string public symbol = "MST";
    uint8 public decimal = 3;
    mapping ( address => uint256) public balances;
    uint256 public totalSupply;
    event Transfer(address indexed _from, address indexed _to, uint256 value);

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function _mint(address account, uint256 value) public {
        totalSupply += value;
        balances[account] += value;
        emit Transfer(address(0), account, value);
    }
}