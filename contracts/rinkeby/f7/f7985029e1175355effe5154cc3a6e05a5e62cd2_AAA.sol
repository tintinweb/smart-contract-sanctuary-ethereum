/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract AAA {

    uint[] soldOutOccupation = [3,6,9];

    function updateBlindBoxTypeArrayLength(uint256 _arrayLength) public view returns(uint[] memory blindBoxTypeArray) {
        blindBoxTypeArray = new uint[](_arrayLength);
        for (uint i = 0; i < _arrayLength; i++) {  
            blindBoxTypeArray[i] = i+1;
        }
        uint lastId = blindBoxTypeArray.length - 1;  
        for (uint i = 0; i < blindBoxTypeArray.length; i++) { 
            for (uint j = 0; j < soldOutOccupation.length; j++) { 
                if(blindBoxTypeArray[i] == soldOutOccupation[j]){
                    blindBoxTypeArray[i] = blindBoxTypeArray[lastId];
                }
            }
        }
        return blindBoxTypeArray;
    }
}