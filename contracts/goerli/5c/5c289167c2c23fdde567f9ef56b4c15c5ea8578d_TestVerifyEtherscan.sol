/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
/// @custom:security-contact [email protected]
contract TestVerifyEtherscan {
    uint256 public lastId;
    constructor() {
        lastId = 1337;
    }
    function setLastId() external{
        lastId = lastId++;

    }

    function sumOf(uint256 b) external view returns (uint256) {
        return lastId*b;
    }
}