// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract HelloWorld {
  string hello = "hello";

  function helloWorld() public returns (string memory) {
    return hello;
  }
}