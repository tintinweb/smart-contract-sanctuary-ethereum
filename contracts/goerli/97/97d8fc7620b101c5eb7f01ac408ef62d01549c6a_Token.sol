/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Token {

    event Transfer(address from, address to, uint256 value);

    uint public totalSupply = 1000 * (10 ** 18);
    string public name = "Puan Chan";
    string public symbol = "PCN";
    uint8 public decimals = 18;

    mapping(address => uint) balance;

    constructor() {
        balance[msg.sender] = totalSupply;
    }

    function balanceOf(address _addr) external view returns (uint) {
        return balance[_addr];
    }

    function transfer(address _to, uint _value) public returns (bool) {
        require(balance[msg.sender] >= _value);
        balance[msg.sender] -= _value;
        balance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}