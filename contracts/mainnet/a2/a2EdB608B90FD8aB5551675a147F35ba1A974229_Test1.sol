/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Test1 {

  uint public myNumber;

  function setNumber(uint _number) public {
    myNumber = _number;
  }

  function doubleNumber() public {
    myNumber = myNumber * 2;
  }


}