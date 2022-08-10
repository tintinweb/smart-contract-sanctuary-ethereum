/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract KeepersSample  {
    function compoundVault() external returns (bool success) { }
    function compoundVaultId(uint vaultId) external returns (bool success) { }
    function rebaseToken() external returns (bool success) { }
    function startNextRound() external returns (bool success) { }
    function distributeRewards() external returns (bool success) { }
    function distributeFees() external returns (bool success) { }
    function startLottery() external returns (bool success) { }
    function startRaffle() external returns (bool success) { }
    function rebalanceIndex() external returns (bool success) { }
    function rebalanceIndexId(uint indexId) external returns (bool success) { }
    function rebalancePositionId(uint indexId) external returns (bool success) { }
    function updateTWAP(uint indexId) external returns (bool success) { }  
}