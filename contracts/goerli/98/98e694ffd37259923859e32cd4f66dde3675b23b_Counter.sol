// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../interfaces/ICounter.sol';

contract Counter is ICounter {
  uint private counter;
  address public deployer;

  modifier onlyOwner () {
    require(msg.sender == deployer);
    _;
  }

  constructor() {
    counter = 0;
    deployer = msg.sender;
  }

  function increment() external {
    counter += 1;
  }

  function getCounter() public view returns (uint) {
    return counter;
  }

  function resetCounter() external onlyOwner {
    counter = 0;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICounter {
  function increment() external;
  function getCounter() external view returns (uint count);
  function resetCounter() external;
}