/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;

contract SimpleStorage {
string storedData;


function set(string memory x) public {
   storedData = x;
  }

  function get() public view returns (string memory) {
    return storedData;
  }
}