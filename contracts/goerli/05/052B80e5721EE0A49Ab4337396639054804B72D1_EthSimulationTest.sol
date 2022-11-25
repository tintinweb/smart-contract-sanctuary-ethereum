pragma solidity ^0.7.6;

contract EthSimulationTest {
  uint256 public counter;

  constructor() {
    counter=0;
  }

  function getCounter() public view returns (uint256) {
    return counter;
  }

  function getBlockNumber() public view returns (uint256) {
    return block.number;
  }

  function incrementCounter() external {
    counter++;
  }
}