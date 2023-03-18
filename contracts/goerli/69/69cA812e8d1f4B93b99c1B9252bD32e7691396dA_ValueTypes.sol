/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ValueTypes {
    bool public b = true;
    uint public u = 123; // 0 -> 2**256 - 1
    int public i = -123; // -2**255 - 1 -> 2**255 - 1
    int public minInt = type(int).min;
    int public maxInt = type(int).max;
    address public addr = 0xc0213aFd672926DC218615CFfce784485e67b79E;
    bytes32 public b32 = 0x9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08;
}