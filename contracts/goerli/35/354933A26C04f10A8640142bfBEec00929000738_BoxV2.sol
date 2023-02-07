// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// V2 implementation contract
contract BoxV2 {
    uint public val;

    /**
     not needed since it can only be called once and it was done v1 Box contract
     so we don't need it anymore

     function initialize(uint _val) {
        val = _val;
     }
     */

    // v2 added function
    function inc() external {
        val += 1;
    }
}