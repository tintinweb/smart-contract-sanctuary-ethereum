// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract BoxV3 {
    uint public val;

    // function initialize(uint _val) external {
    //     val = _val;
    // }
    function inc3() external {
        val += 3;
    }
}