//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BoxV2 {
    uint public val;

    // no constructors for upgradable contracts
    // constructor(uint _val) external {
    //     val = _val;
    // }
    

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() external {
        val += 1;
    }
}