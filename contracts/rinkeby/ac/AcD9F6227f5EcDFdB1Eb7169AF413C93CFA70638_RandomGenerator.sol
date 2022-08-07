// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract RandomGenerator {
  constructor() {}

  function getRandom(uint input1, uint input2) external view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            block.difficulty,
            block.timestamp,
            keccak256(abi.encodePacked(tx.origin, block.coinbase, input1)),
            input2
          )
        )
      );
  }
}