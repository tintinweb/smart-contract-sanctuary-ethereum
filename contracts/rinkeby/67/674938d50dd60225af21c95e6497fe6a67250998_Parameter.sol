/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Parameter {
    uint8 public hello;
    function foo(uint8 _hello) external {
        hello = _hello;
    }
}