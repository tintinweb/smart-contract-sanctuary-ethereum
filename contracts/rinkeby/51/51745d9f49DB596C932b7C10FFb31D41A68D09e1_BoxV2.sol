// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract BoxV2 {
    uint public cval;

    function increament() external {
        cval += 2;
    }
}