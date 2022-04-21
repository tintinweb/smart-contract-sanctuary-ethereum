/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface KeeperCompatibleInterface {
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
  function performUpkeep(bytes calldata performData) external;
}

interface Faucet {
    function lastUpdateTime() external view returns (uint256);
    function distributeFodl() external returns (uint256 amount);
}

contract DailyXFodlDrip is KeeperCompatibleInterface {
    address public constant faucet = 0xbEb37ee33Df558E8BD57d94810a79DF8FfB1a7D2;

    function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
        return (block.timestamp - 1 days >= Faucet(faucet).lastUpdateTime(), "0x");
    }

    function performUpkeep(bytes calldata ) external override {
        Faucet(faucet).distributeFodl(); 
    }
}