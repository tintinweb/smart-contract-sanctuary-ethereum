/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract UpkeepCounterFire {
  bool public checkFlag = false;
  bool public performFlag = true;
  uint256 public immutable interval;
  uint256 public lastTimeStamp;

  bool comingFromCheck = false;

  constructor(uint256 updateInterval) {
    interval = updateInterval;
    lastTimeStamp = block.timestamp;
  }

  function setCheckFlag(bool _checkFlag) external {
    checkFlag = _checkFlag;
  }

  function setPerformFlag(bool _performFlag) external {
    performFlag = _performFlag;
  }

  function checkUpkeep(bytes calldata data) external returns (bool, bytes memory) {
    bool upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    comingFromCheck = true;
    return (checkFlag && upkeepNeeded, data);
  }

  function performUpkeep(bytes calldata performData) external {
    if (!performFlag) {
      require(comingFromCheck == true, "only succeed in simulation");
    }
    lastTimeStamp = block.timestamp;
  }
}