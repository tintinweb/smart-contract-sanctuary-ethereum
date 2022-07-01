/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract UpkeepCounterFire {
  bool public checkFlag = true;
  bool public performFlag = true;
  uint256 public immutable interval;
  uint256 public lastTimeStamp;
  uint256 public counter;
  uint256 public simCounter;

  constructor(uint256 updateInterval) {
    interval = updateInterval;
    lastTimeStamp = block.timestamp;
    counter = 0;
    simCounter = 0;
  }

  function setCheckFlag(bool _checkFlag) external {
    checkFlag = _checkFlag;
  }

  function setPerformFlag(bool _performFlag) external {
    performFlag = _performFlag;
  }

  function resetCounters() external {
    counter = 0;
    simCounter = 0;
  }

  function checkUpkeep(bytes calldata data) external returns (bool, bytes memory) {
    bool upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    return (checkFlag && upkeepNeeded, data);
  }

  function performUpkeep(bytes calldata performData) external {
    if (!performFlag) {
      require(tx.origin == address(0), "only for simulated backend");
      simCounter = simCounter + 1;
    } else {
      lastTimeStamp = block.timestamp;
      counter = counter + 1;
    }
  }
}