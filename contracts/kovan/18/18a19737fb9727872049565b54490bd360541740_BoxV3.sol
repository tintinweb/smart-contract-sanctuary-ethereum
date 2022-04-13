// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

contract BoxV3 {

    uint256 public val;
    bool private initialized;

    function inc() external {
        val += 1;
    }

    function dec() external {
        val -= 1;
    }

    function initialize(uint _val) external {
        require(!initialized, "Already Initialized");
        initialized = true;
        val = _val;
    }
}