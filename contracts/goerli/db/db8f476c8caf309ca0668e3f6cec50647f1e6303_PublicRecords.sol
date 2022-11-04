// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPublicRecords {
  // ::::: EVENTS :::::

  event PostRecord(string record, uint256 indexed number, address indexed poster);

  // ::::: FUNCTIONS :::::

  function post(string calldata record) external;
}

contract PublicRecords is IPublicRecords {
  // ::::: STORAGE :::::

  string[] public records;

  // ::::: ERRORS :::::
  
  error TakeItBackHomie();

  // ::::: VIEW FUNCTIONS :::::

  function count() public view returns (uint256) {
    return records.length;
  }

  function lastRecord() public view returns (string memory) {
    return records[records.length - 1];
  }

  // ::::: EXTERNAL FUNCTIONS :::::

  function post(string calldata record) external {
    records.push(record);
    emit PostRecord(record, records.length - 1, msg.sender);
  }

  // ::::: FALLBACK FUNCTIONS :::::

  receive() external payable {
    revert TakeItBackHomie();
  }

  fallback() external payable {
    revert TakeItBackHomie();
  }
}