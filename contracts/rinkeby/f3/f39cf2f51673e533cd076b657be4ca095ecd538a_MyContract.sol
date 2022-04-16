/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract MyContract {
  /*

  */  
  string _name;
  uint _balances;

  constructor(string memory name, uint balances) {
      _name = name;
      _balances = balances;
  }

  function getName() public payable returns (string memory name) {
      return _name;
  } 

  function getBalances() public view returns (uint balances) {
    return _balances;
  }
}