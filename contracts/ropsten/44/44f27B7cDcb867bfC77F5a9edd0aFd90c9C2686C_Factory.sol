/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract Factory {
  string private _word;

  constructor(string memory word) {
    _word = word;
  }

  function printWord() public view returns (string memory) {
    return _word;
  }
}