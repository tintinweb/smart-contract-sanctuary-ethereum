/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract WriteonChain{
    
    mapping(uint => string) public inputData;
    
    uint public indexCount;
    constructor(){
    indexCount = 0;
    }
    //========================

    function writeData(string memory _inputString) public{
        indexCount += 1;
        inputData[indexCount] = _inputString;
    }
}