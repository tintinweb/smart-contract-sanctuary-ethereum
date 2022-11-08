/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract Counter {
    
    uint public count;

    function inc() public {
        count += 1;
    }

    function get() public view returns (uint) {
        return count;
    }
}