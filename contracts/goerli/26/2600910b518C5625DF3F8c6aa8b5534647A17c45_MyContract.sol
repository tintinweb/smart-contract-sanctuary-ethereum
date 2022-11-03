/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity >=0.7.0 <0.9.0;
contract MyContract {
  address private owner;
  string name;
  constructor() {
    owner = msg.sender;
  }
  function changeName(string memory newName) public {
    name = newName;
  }
  function showName() public view returns(string memory) {
    return name;
  }
}