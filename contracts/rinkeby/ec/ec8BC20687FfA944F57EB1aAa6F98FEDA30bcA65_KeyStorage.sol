// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract KeyStorage {

  mapping (address => bytes) public map;
  
  constructor() {}

  function Store(bytes memory ethEncKey) public {
    bytes memory existingValue = bytes(map[msg.sender]);
    require(existingValue.length <= 0, "Stored value cannot be overwritten");
    map[msg.sender] = ethEncKey;
  }
}