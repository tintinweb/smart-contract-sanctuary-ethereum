/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Collector {
    uint[] public numbers;

    function numbersPush(uint num) public {
        numbers.push(num);
    }
}