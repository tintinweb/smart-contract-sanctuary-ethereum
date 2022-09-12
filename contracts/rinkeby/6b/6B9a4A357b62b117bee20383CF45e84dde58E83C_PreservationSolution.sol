// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract PreservationSolution {
  address public timeZone1Library;
  address public timeZone2Library;
  address public owner;
  uint storedTime;
  
  function setTime(uint _time) public {
    owner = 0xC06dECc1ccfeE676Ddd3d16Ce24ae99866c552C0;
    storedTime = _time;
  }

  function getUint(address addr) pure public returns (uint) {
    return uint256(addr);
  }

  function getAddress(uint256 number) pure public returns (address) {
    return address(number);
  }
}