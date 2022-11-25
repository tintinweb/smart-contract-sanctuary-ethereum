pragma solidity ^0.7.6;

contract EthSimulationTest {
  uint256 public counter;

  constructor() {}

  function getCounter() external returns (uint256) {
    return counter;
  }

  function checkNumber() external returns (uint256) {
    return block.number;
  }

  function incrementCounter() external {
    counter++;
  }
}