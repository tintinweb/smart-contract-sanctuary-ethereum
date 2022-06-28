/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract AAA {
    function updateBlindBoxTypeArrayLength(uint256 _arrayLength) public pure returns(uint[] memory blindBoxTypeArray) {
        blindBoxTypeArray = new uint[](_arrayLength);
        for (uint i = 0; i < _arrayLength; i++) {  
            blindBoxTypeArray[i] = i+1;
        }
        return blindBoxTypeArray;
    }
}