/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//import section

contract Counter {
  uint public number;

  function sum() public {
    number = number + 1;
  }

}