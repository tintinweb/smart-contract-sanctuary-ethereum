/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Data types - values and references

contract ValueTypes {

    bool public b = true;
    uint public u = 123;    // uint = uint256 0 to 2**256 1
                            //        uint8   0 to 2**8 1
                            //        uint16  0 to 2**16 1

    int public i = -123;    // int = int256    -2**255 to 2**255 1
                            //       int128    -2**127 to 2**127 - 1

    int public minInt = type (int).min;
    int public maxInt = type (int).max;
    address public addr = 0x5CB9B3c05e161a0e08f2E711215043Ba8e89125C; 
    bytes32 public b32 = 0xb30416b4684812992185a35db0b5831d94c11c01c0691116a6596ec218d83f9a;
}