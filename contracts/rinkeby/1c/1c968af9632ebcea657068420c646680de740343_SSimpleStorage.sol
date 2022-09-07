/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract SSimpleStorage {
    uint256 storedNumber;

    function storeNumber(uint256 newNumber) external {
        storedNumber = newNumber;
    }

    function readNumber() external view returns (uint256) {
        return storedNumber;
    }
}