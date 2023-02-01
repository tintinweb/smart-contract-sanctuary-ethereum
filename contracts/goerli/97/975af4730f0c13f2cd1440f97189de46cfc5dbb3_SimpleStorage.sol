/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {

    uint256 public storedValue;
    function setStoredValue(uint256 newStoredValue) public {
        storedValue = newStoredValue;
    }
}