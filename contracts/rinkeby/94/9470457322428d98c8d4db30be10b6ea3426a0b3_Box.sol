/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Box {
    uint public val;

    function initialize(uint _val) external {
        val = _val;
    }

}