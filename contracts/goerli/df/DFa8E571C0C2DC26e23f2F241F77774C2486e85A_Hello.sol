// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Hello {
    uint256 value;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        value = num;
    }

    /**
     * @dev Return value
     * @return value of 'value'
     */
    function retrieve() public view returns (uint256) {
        return value;
    }
}