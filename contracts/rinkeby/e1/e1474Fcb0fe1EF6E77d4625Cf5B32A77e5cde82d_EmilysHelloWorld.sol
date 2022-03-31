// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

contract EmilysHelloWorld {

  string name;

  constructor(string memory _name) {
    name = _name;
  }

  function hello() external view returns (string memory) {
    return string(abi.encodePacked('hello, ', name, '!'));
  }
}