/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract AppWorks_Bytes {
    bytes one_byte = new bytes(0);
    // OR
    bytes1 one_byteV2;

    bytes1 one_byteV3;  // Will packed?

    constructor(){
        // Assign the value
        one_byte = "a";     // hex(61)
        one_byteV2 = 'b';   // hex(62)
        one_byteV3 = 'c';   // hex(63)
    }

    function read1() public view returns(bytes memory){
        return one_byte;
    }


    function read2() public view returns(bytes1){
        return one_byteV2;
    }

    function read3() public view returns(bytes1){
        return one_byteV3;
    }
}