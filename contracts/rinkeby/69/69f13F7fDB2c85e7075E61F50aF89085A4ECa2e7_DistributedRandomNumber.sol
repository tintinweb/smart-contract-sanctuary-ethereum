// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

library DistributedRandomNumber {
  uint256 constant private DECIMALS = 18;

  struct Distribution {
    Number[] numbers;
    mapping(uint256 => uint256) indexes;
    uint256 sum;
    uint256 counter;
  }

  struct Number {
    uint256 value;
    uint256 distribution;
  }

  function _createRandomNumber(Distribution storage self) private returns (uint256) {
    self.counter++;
    return uint256(keccak256(abi.encodePacked(
      self.counter,
      block.timestamp,
      msg.sender
    )));
  }

  function add(Distribution storage self, Number memory number) internal {
    self.numbers.push(number);
    self.indexes[number.value] = self.numbers.length;
    self.sum += number.distribution;
  }

  function remove(Distribution storage self, Number memory number) internal {
    uint256 valueIndex = self.indexes[number.value];
    if (valueIndex != 0) {
      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = self.numbers.length - 1;
      if (lastIndex != toDeleteIndex) {
        Number memory lastValue = self.numbers[lastIndex];
        self.indexes[lastValue.value] = valueIndex;
      }
      self.numbers.pop();
      delete self.indexes[number.value];
      self.sum -= number.distribution;
    }
  }

  function reset(Distribution storage self) internal {
    for (uint256 i = 0; i < self.numbers.length; i++) {
      delete self.indexes[i];
    }
    delete self.numbers;
    self.sum = 0;
    self.counter = 0;
  }

  function numberOf(Distribution storage self, uint256 value) internal view returns (Number memory) {
    uint256 i = self.indexes[value];
    return self.numbers[i];
  }

  function contains(Distribution storage self, Number memory number) internal view returns (bool) {
    return self.indexes[number.value] != 0;
  }

  function getDistributedRandomNumber(Distribution storage self) public returns(uint256) {
    uint256 rand = _createRandomNumber(self) % (10 ** DECIMALS);
    // console.log("Distributed Random Number", rand, distributions.length, msg.sender);
    uint256 tempDist = 0;
    for (uint256 i = 0; i < self.numbers.length; i++) {
      tempDist += self.numbers[i].distribution;
      // console.log("TempDist", tempDist);
      if (rand <= tempDist) {
        return self.numbers[i].value;
      }
    }
    return 0;
  }
}