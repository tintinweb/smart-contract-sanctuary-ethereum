/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
 
contract Register {
  string private info;
   
  function getInfo() public view returns (string memory) {
      return info;
  }
 
  function setInfo(string memory _info) public {
      info = _info;
  }
}