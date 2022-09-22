//SDPX-License-Identifier: MIT

pragma solidity 0.6.0;

contract Librarian {
  address public timeZone1Library;
  address public timeZone2Library;
  address public owner;
  uint256 storedTime;

  function setTime(uint256) public {
    owner = address(tx.origin);
  }
}