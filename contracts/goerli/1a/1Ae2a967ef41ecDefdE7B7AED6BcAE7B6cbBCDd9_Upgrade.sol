//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

contract Upgrade {
  uint private x;

  function getX() public view returns(uint) {
    return x;
  }

  function setX(uint _x) public {
    x = _x;
  }
}