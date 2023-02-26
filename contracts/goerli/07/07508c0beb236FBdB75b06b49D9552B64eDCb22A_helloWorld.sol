/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract helloWorld {
  string public text = "Hola Mundo3";

  function callHelloWorld() public view returns (string memory) {
    return text;
  }
}