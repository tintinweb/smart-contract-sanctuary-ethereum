//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BoxV2 {
    uint256 public val;

    // function initialize(uint256 _val) public {
    //     val = _val;
    // }

    function inc() external {
        val += 1;
    }
}