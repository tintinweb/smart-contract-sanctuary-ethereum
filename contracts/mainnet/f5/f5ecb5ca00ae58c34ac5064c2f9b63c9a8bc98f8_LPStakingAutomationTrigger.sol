/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface KeeperCompatibleInterface {
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
  function performUpkeep(bytes calldata performData) external;
}

interface LPStakingAutomation {
    function rewardNumber() external view returns (uint256);
    function notifyRewards() external;
}

contract LPStakingAutomationTrigger is KeeperCompatibleInterface {
    address public constant lpStakingAutomation = 0x8e039371b4b604000dE50ee5600C29E758446C48;

    function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
        return (getTimestamp(LPStakingAutomation(lpStakingAutomation).rewardNumber()) <= block.timestamp, "0x");
    }

    function performUpkeep(bytes calldata ) external override {
        LPStakingAutomation(lpStakingAutomation).notifyRewards();
    }

    function getTimestamp(uint256 index) private pure returns (uint256 timestamp) {
        timestamp = 1635379200 + index * 1 weeks;
    }
}