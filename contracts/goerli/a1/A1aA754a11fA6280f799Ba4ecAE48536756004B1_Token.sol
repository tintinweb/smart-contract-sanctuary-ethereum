// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

contract Token {
    string public name = "Endor Hardhat Token";
    string public symbol = "ENDOR";

    uint256 public totalSupply = 10000;
    address public owner;

    mapping(address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 value) external {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}