// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

contract CounterSimple {
  uint256 public count = 0;

  function increment() public returns (uint256) {
    count += 1;
    return count;
  }

  function addInteger(uint256 intToAdd) public returns (uint256) {
    count += intToAdd;
    return count;
  }

  function incrementWithArray(uint256[] calldata unused) public returns (uint256) {
    count += 1;
    return count;
  }

  function incrementWithBytes(bytes calldata unused) public returns (uint256) {
    count += 1;
    return count;
  }

  function reset() public returns (uint256) {
    count = 0;
    return count;
  }
}