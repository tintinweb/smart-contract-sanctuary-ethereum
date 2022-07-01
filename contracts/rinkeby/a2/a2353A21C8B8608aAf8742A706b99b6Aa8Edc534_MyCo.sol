/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity >=0.7.0 <0.9.0;contract MyCo {
  address private owner;
  string name;  constructor() {
    owner = msg.sender;
  }  

  function cName(string memory newName) public {
    name = newName;
  }  
  
  function sName() public view returns(string memory) {
    return name;
  }
}