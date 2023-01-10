/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;

interface IStrategy {
    function harvest() external;
}

contract KeeperWrapper {
    function harvest(address _strategy) external {
        IStrategy(_strategy).harvest();
    }
}