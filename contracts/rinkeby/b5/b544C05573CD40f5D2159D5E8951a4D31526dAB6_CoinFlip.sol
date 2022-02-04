// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './SafeMath.sol';

contract CoinFlip {

  using SafeMath for uint256;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  function flip() public view returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number.sub(1)));
    uint256 coinFlip = blockValue.div(FACTOR);
    bool side = coinFlip == 1 ? true : false;
    return side;
  }
}