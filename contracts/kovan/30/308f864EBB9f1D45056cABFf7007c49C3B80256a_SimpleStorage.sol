/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract SimpleStorage {
  uint storedData;
  event dataStored(uint data,address addr);

  function set(uint x) public {
    storedData = x;
    emit dataStored(x,msg.sender);
  
  }

  function get() public view returns (uint) {
    return storedData;
  }
}