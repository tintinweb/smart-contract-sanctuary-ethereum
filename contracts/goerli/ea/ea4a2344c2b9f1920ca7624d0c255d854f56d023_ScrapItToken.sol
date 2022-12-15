/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: GPL-3.0
// @scrapit:dev-run-script 

pragma solidity ^0.8.0;

contract ScrapItToken {
  // ...
  string public name = "Scrap-It Token";
  string public symbol = "SCRAP";
  uint8 public decimals = 18;
  uint256 public totalSupply = 1000000 * 10 ** uint256(decimals);

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor()  {
    balanceOf[msg.sender] = totalSupply;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0), "Invalid address");
    require(_value <= balanceOf[msg.sender], "Insufficient balance");
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowance[msg.sender][_spender] = _value;
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0), "Invalid address");
    require(_value <= balanceOf[_from], "Insufficient balance");
    require(_value <= allowance[_from][msg.sender], "Insufficient allowance");
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    return true;
  }
}