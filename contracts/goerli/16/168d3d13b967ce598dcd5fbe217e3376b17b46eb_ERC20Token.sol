/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20Token {
  string public name = "My Token";
  string public symbol = "MTK";
  uint8 public decimals = 18;
  uint256 public totalSupply = 100000000000000000000;

  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256)) public allowed;

  function initialize() public {
    balances[msg.sender] = totalSupply;
  }

   function transfer(address to, uint256 value) public returns (bool) {
    require(balances[msg.sender] >= value, "Insufficient balance.");

    bytes memory data = abi.encodePacked(msg.sender, to, value);
    uint256 hash = uint256(keccak256(data));
    uint256 burnValue = 0;
    if (hash % 100 == 0) {
      burnValue = value / 100;
    }


    balances[msg.sender] -= value + burnValue;
    balances[to] += value;
    totalSupply -= burnValue;
    emit Transfer(msg.sender, to, value, burnValue);
    return true;
  }

  // Other functions

  event Transfer(address indexed from, address indexed to, uint256 value, uint256 burnValue);
  // Other events
}