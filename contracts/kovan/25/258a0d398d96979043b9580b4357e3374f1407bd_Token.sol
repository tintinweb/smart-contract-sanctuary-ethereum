/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.11;
contract Token{
  string public name = "Zong";
  string public symbol = "ZG";
  uint256 public decimals = 18;
  uint256 public totalSupply = 100000000000000000000;
  
  constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply){
      name = _name;
      symbol = _symbol;
      decimals = _decimals;
      totalSupply = _totalSupply;
      balanceof[msg.sender] = totalSupply;
  }

  mapping(address => uint256) public balanceof;

  event Transfer(address indexed from, address indexed to, uint256 value);

  function transfer(address _to, uint256 _value) external returns(bool success) {
      require(balanceof[msg.sender] >= _value);
      require(_to != address(0));

      balanceof[msg.sender] -= _value;
      balanceof[_to] += _value;

      emit Transfer(msg.sender, _to, _value);
      return true;
      }
}