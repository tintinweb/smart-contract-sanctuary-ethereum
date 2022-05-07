// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract T {
  string public vvv;

  constructor() {
    vvv = "hello";
  }

  function updateVvv(string memory _vvv) external {
    vvv = _vvv;
  }
}