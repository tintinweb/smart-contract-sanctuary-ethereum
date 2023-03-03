// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

interface IStrategy {
    function harvest() external;
}

contract KeeperWrapper {
    function harvestStrategy(address _strategy) external {
        IStrategy(_strategy).harvest();
    }
}