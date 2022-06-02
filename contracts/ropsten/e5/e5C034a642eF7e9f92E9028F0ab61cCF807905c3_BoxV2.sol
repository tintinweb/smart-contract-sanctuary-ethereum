/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract BoxV2{
    uint public val;

    function inc() external {
        val += 1;
    }
}