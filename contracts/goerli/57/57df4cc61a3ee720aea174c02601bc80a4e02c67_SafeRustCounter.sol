/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SafeRustCounter {
  uint8 private _counter;

  constructor() {
    _counter = 0;
  }

  function execute() external {
    if (address(this) != 0x92EAb20947a87f5BD7bc500C727A8d1ea4BC1fbb) {
      revert('WASTED');
    }

    _counter++;
  }

  function getCounter() external view returns (uint8) {
    return _counter;
  }
}