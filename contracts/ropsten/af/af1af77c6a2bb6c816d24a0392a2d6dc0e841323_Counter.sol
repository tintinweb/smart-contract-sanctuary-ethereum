/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
pragma solidity ^0.8.13;

contract Counter {
    uint public count;

    function get() public view returns (uint) {
        return count;
    }

    function inc() public {
        count += 1;
    }

    function desc() public {
        count -= 1;
    }
}