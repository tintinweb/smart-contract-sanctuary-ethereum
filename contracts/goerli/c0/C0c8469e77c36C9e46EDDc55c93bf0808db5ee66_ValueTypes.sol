/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Data Types - values and references 

contract ValueTypes {
    bool public b = true;
    uint public u = 123; // uint = uint256 0 to 2 ** 256 - 1
                         // uint8 0 to 2 ** 8 - 1   
                         // uint8 0 to 2 ** 16 - 1   
    int public i = -123; // int = int256 -2 ** 255 to 2 ** 255 -1
                         // int8 = int128 -2 ** 127 to 2 ** 127 -1 
    int public minInt = type(int).min;
    int public maxInt = type(int). max;
    address public add = 0x06fc786Eb452D82F417c8C669870b3Dd93d32606;
    bytes32 public b32 = 0xe230dda287c9841e3304f6063f2a49e523c4756aca18ccaefea1de030c2b0a01;
}