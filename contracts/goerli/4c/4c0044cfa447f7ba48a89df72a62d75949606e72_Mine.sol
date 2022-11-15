/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

contract Mine {
    uint public myNumber;

    function increase() external {
        myNumber++;
    }
}