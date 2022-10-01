// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract StoreV2 {

    uint256 private number;

    /**
     * @dev initialize value in variable
     * @param num value to store
     */
    function initialize(uint256 num) public {
        number = num;
    }

    // === Added in V2 ===
    /**
     * @dev Return value
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }

    /**
     * @dev Increment value
     */
    function inc() public {
        number++;
    }
}