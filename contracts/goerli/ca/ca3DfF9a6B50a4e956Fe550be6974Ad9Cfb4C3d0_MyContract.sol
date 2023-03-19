/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MyContract {
    bool public b = true;
    uint256 public u = 123; // uint256  0 to 2**256 - 1
    int256 public i = -123; // int256   -2*255 to 2**255 - 1

    int256 public minInt = type(int256).min;
    int256 public maxInt = type(int256).max;

    address public addr = 0x91a68Df374fc3Feec5c8F8FD4F6b1209247A5445;
    bytes32 public b32 =
        0x68656c6c6f000000000000000000000000000000000000000000000000000000; // hello
}