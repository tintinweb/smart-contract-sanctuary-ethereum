// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract EscrowSimple {
  uint256 num = 43;
  
  function getNumber() public view returns(uint256) {
      return num;
  }
}