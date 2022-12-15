/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract AA {
  uint number;

  function changeNumber(uint _n) public returns(uint){
    number = _n;
    return number;
  }

}