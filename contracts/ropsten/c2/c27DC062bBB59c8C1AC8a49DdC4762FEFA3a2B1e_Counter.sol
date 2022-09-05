/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Counter {
    uint public count;
    function get() public view returns (uint) {
        return count;
    }
    function inc() public{
        count += 1;
    }
    function dec() public{
        count -= 1;
    }
}