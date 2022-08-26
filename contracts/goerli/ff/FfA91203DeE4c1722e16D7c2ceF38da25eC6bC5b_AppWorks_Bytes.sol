// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract AppWorks_Bytes {
    bytes one_byte = new bytes(0);
    // OR
    bytes1 one_byteV2;

    constructor(){
        // Assign the value
        one_byte = 'a';     // hex(61)
        one_byteV2 = 'b';   // hex(62)
    }
}