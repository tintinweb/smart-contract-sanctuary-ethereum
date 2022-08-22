/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BoxV2 {
    uint public val;

    string public name ;

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() external {
        val += 1;
    }

    function setName() external {
        name = "snow";
    }
}