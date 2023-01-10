/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract sample {

    string storedData;


    function set(string memory x) public {
   storedData = x;
  }

  function get() public view returns (string memory) {
    return storedData;
  }
}