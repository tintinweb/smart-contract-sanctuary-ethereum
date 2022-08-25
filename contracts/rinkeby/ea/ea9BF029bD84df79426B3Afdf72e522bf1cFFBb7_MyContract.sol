/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File contracts/MyContract.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract MyContract {
  string private name;

  constructor(string memory _name) {
    name = _name;
  }

  function changeName(string memory _name) public {
    name = _name;
  }

  function getName() public view returns (string memory) {
    return name;
  }
}