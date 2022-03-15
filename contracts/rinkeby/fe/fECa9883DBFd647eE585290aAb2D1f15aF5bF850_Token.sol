/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

contract Token {
  address private owner;

  string public constant name = "My Token";

  uint private totalSupply;

  mapping(address => uint) private balances;

  constructor(uint _totalSupply) {
    owner = msg.sender;
    totalSupply = _totalSupply;
    balances[owner] = totalSupply;
  }

  function transfer(uint amount, address to) external {
    require(balances[msg.sender] >= amount, "Insufficient funds");
    balances[msg.sender] -= amount;
    balances[to] += amount;
  }

  function balanceOf(address _add) external view returns (uint) {
    return balances[_add];
  }

  function getTotalSupply() external view returns (uint) {
    return totalSupply;
  }
}