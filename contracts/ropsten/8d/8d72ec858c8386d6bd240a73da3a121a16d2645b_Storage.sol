/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256[] numbers = [1, 2, 3];

    /**
     * @dev Store value in variable
     * @param nums value to store
     */
    function store(uint256[] memory nums) public {
        numbers = nums;
    }
}