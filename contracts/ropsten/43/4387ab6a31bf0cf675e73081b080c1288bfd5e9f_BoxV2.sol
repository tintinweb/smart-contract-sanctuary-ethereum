/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract BoxV2 {
    uint256 public val;

    // function init(uint256 _val) {
    //     val = _val;
    // }
    
    function inc() external{
        val += 1;
    }
}