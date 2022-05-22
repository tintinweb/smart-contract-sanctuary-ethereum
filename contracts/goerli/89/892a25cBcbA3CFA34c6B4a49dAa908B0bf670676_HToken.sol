// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract HToken {
  string public tokenName = "Hardhat Token";
  string public tokenSymbol = "HHT";
  address public owner;
  uint256 public maxSupply = 10000;
  mapping(address => uint256) balances;

  constructor() {
    owner = msg.sender;
    balances[owner] = maxSupply;
  }

  function balanceOf(address _walletAddr) external view returns (uint256) {
    return balances[_walletAddr];
  }

  function transfer(address _to, uint256 _amount) external {
    require(balances[msg.sender] >= _amount, "not enough tokens");
    balances[msg.sender] -= _amount;
    balances[_to] += _amount;
  }
}