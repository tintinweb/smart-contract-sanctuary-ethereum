//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract For3stICDemo {
  string public name = "For3st IC Demo";
  string public symbol = "FOR3ST";

  uint256 public example;

  uint256 public totalSupply = 10000000;

  address public owner;

  mapping(address => uint256) balances;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  constructor(uint256 exampleConstructor) {
    balances[msg.sender] = totalSupply;
    owner = msg.sender;

    example = exampleConstructor;
  }

  function transfer(address to, uint256 amount) external {
    require(balances[msg.sender] >= amount, "Not enough tokens");

    balances[msg.sender] -= amount;
    balances[to] += amount;

    emit Transfer(msg.sender, to, amount);
  }

  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }
}