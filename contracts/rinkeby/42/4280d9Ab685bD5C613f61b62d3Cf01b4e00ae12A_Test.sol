pragma solidity 0.8.13;

contract Test {
  uint256 public a;

  function initialize(uint256 _a) external {
    a = _a;
  }

  function test() external {
    a += 10;
  }
}