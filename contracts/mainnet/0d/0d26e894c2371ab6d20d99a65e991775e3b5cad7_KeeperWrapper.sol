/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;

interface IStrategy {
    function harvest() external;
}

/// @notice This contract allows anyone to harvest automated yearn strategies
/// @dev Automated yearn strategies do not swap tokens during harvests
contract KeeperWrapper {
    /// @notice Calls harvest on the strategy address entered
    /// @dev Will revert if the strategy's keeper is not set to this address
    /// @param _strategy Address of the strategy to harvest
    function harvest(address _strategy) external {
        IStrategy(_strategy).harvest();
    }
}