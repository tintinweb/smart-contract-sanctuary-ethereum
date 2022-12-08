pragma solidity ^0.8.9;

/* SPDX-License-Identifier: UNLICENSED */

/**
 * @title Test implementation of Beacon chain oracle
 */
contract TestBeaconChainOracle {
    /// @notice Foundation validator's indexes
    string public validatorIndexes;

    constructor() {
        validatorIndexes = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20";
    }

    function balanceByEpoch(uint256 _epoch) external pure returns (uint256) {
        return 200 ether;
    }
}