pragma solidity ^0.8.9;

/* SPDX-License-Identifier: UNLICENSED */

/**
 * @title Test implementation of execution layer oracle.
 */
contract TestExecutionLayerOracle {
    /// @notice validator's address collecting fees
    address public validatorAddress;

    constructor() {
        validatorAddress = address(0xe7cf7C3BA875Dd3884Ed6a9082d342cb4FBb1f1b);
    }

    function balanceByEpoch(uint256 _epoch) external pure returns (uint256) {
        return 200 ether;
    }
}