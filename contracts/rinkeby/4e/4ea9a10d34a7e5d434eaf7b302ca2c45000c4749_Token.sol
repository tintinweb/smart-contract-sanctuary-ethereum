/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

contract Token{
  address private owner;

  string public constant name = 'MyToken';

  mapping(address => uint256) private balances;

  uint256 private totalSupply;

  constructor(uint256 _totalSupply){
    totalSupply = _totalSupply;
    owner = msg.sender;
    balances[owner] = _totalSupply;
  }

  function transfer(uint256 amount, address to) external {
    require(balances[msg.sender] >= amount, 'Not enough funds in the account');
    balances[msg.sender] -= amount;
    balances[to] += amount;
  }

  function balanceOf(address _address) view public returns (uint256) {
    return balances[_address];
  }

  function getTotalSupply() view public returns (uint256) {
    return totalSupply;
  }




}