/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

contract BoxV2 {
    uint public val; // initializing value directly is not allowed in upgradeable proxy
    //Constructor is not allowed in upgradeable proxy

    // function initialize(uint _val) external {
    //     val = _val;
    // }
    function modify(uint incrementBy) external {
        val -= incrementBy;
    }
}