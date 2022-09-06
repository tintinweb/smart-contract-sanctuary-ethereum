/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {

    uint256 public value;

    function incrementByValue(uint256 x) public {
        value += x;
    }

    function increment() public {
        value += 1;
    }
}