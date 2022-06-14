/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.10;

contract Box {
    uint public val;
    function initialize(uint _val) external {
        val = _val;
    }
}