/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;
contract GovernorBravoDelegatorStorage {
    // @notice Administrator for this contract
    address public admin;
    // @notice Pending administrator for this contract
    address public pendingAdmin;
    // @notice Active brains of Governor
    address public implementation;
}