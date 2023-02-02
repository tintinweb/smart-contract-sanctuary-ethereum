// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title Counter
 * @author Someone idk
 * @notice I just want the natspec comments to show up lol
 */
contract Counter {

    /**
     * @notice Some number
     * @dev Set using the `increment()` function
     */
    uint256 public number;

    /**
     * @notice Testing whether natspec works with forge verify
     * @dev These comments should show up on etherscan
     * @param newNumber Just a number
     */
    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    /**
     * @notice This should also show up
     * @dev And this should too
     */
    function increment() public {
        number++;
    }
}