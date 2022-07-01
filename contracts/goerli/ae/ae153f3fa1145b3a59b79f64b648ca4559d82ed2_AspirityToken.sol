/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

contract AspirityToken {
    string public name = "Aspirity Token";
    string public symbol = "ASPT";
    uint256 public totalSupply = 100003;
    uint8 public decimals = 2;
    address public owner;

    mapping (address => uint256) balances;

    constructor()
    {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) external
    {
        require(balances[msg.sender] >= _value, "Not enough funds");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }

    function balanceOf(address addr) external view returns (uint256 balance)
    {
        return balances[addr];
    }
}