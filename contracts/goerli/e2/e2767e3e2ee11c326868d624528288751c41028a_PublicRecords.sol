// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PublicRecords {
  // STORAGE

  string[] public records;

  // ERRORS
  
  error TakeItBackHomie();

  // EXTERNAL FUNCTIONS

  function post(string calldata record) external {
    records.push(record);
  }

  receive() external payable {
    revert TakeItBackHomie();
  }

  fallback() external payable {
    revert TakeItBackHomie();
  }
}