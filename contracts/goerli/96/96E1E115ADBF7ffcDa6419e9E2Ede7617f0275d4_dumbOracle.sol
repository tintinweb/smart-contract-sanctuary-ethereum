/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: GNU

pragma solidity 0.8.14;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract dumbOracle {
    //stores last value given (the fear and greed index) and a counter for how many times it has been updated.

    uint256 public updates;
    uint256 public fng_index;

    /**
     * @dev updates the value and increments updates
     * @param value value to store as fng_index
     */
    function udpate(uint256 value) external {
        fng_index = value;
        updates += 1;
    }

}