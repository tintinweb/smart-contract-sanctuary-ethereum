// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract TestContract {
  address public immutable immutableDeployer;
  address public deployer;
  uint256 age;

  constructor() {
    deployer = msg.sender;
    immutableDeployer = msg.sender;
    // New Database
    age = 22;
    // LAs
  }

  function foo() external pure returns (string memory) {
    return "bar";
  }
}