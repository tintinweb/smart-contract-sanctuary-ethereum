// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import './Random.sol';

contract Setup {
  Random public random;

  constructor() {
    random = new Random();
  }

  function isSolved() public view returns (bool) {
    return random.solved();
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

contract Random {
  bool public solved = false;

  function _getRandomNumber() internal pure returns (uint256) {
    // chosen by fair dice roll.
    return 4; // guaranteed to be random.
  }

  function solve(uint256 guess) public {
    require(guess == _getRandomNumber());
    solved = true;
  }
}