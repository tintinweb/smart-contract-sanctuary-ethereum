// SPDX-License-Identifier: NONE
pragma solidity ^0.8.18;

contract TestChangeState {
  bool public contractStatus;

  constructor() {
    contractStatus = false;
  }

  function changeContractStatus() public {
    contractStatus = !contractStatus;
  }
}