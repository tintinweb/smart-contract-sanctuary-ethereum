// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

contract Vikoin {
    string public name = "Vikoin";
    string public symbol = "VIK";
    uint256 public totalSupply = 1000000000 * 10 ** 18;
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }
}