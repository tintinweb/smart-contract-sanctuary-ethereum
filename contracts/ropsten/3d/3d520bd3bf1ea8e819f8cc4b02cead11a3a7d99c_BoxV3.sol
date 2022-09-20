/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxV3 {
    uint256 public val;
    uint256 public valAlt;

    // function initialize(uint256 _val) external {
    //     val = _val;
    // }

    function inc() external {
        val += 1;
    }
}