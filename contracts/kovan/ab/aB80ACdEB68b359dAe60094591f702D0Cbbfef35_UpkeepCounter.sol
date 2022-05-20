/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

pragma solidity ^0.7.6;

contract UpkeepCounter {
  bool public checkFlag = true;
  bool public performFlag = true;
  uint public immutable interval;
  uint public lastTimeStamp;

  constructor(uint updateInterval) {
      interval = updateInterval;
      lastTimeStamp = block.timestamp;

    }

  function setCheckFlag(bool _checkFlag) external {
    checkFlag = _checkFlag;
  }

  function setPerformFlag(bool _performFlag) external {
    performFlag = _performFlag;
  }

  function checkUpkeep(bytes calldata data) external view returns (bool, bytes memory) {
    bool upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    return (checkFlag && upkeepNeeded, data);
  }

  function performUpkeep(bytes calldata performData) external {
    if (!performFlag) {
      require(tx.gasprice == 0, "sim only");
    }
    lastTimeStamp = block.timestamp;
  }
}