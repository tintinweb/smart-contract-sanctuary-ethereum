// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract LuckyNumber {
  uint256 private luckyNumber;
  
  function setLuckyNumber(uint256 _luckyNumber) external {
    luckyNumber = _luckyNumber;
  }

  function getLuckyNumber() external view returns(uint256) {
    return luckyNumber;
  }

}