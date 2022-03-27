/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// File: Counter.sol

contract Counter {
    uint256 count;

    constructor() public {
        count = 0;
    }

    function getCount() public view returns (uint256) {
        return count;
    }

    function updateCount() public {
        count = count + 1;
    }
}