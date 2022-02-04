/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

contract HelloWorld {
  
  string private _what = "hello world";

  function greet() public view returns (string memory) {
    return _what;
  }

  function setWhat(string memory newWhat) public {
    _what = newWhat;
  }
}