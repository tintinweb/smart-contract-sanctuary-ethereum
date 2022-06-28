/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract AAA {

    uint[] soldOutOccupation = [3,6,7];
  
    function updateBlindBoxTypeArrayLength(uint256 _arrayLength) public view returns(uint[] memory blindBoxTypeArray) {
        blindBoxTypeArray = new uint[](_arrayLength);
        for (uint i = 0; i < _arrayLength; i++) {  
            blindBoxTypeArray[i] = i+1;
        }
        uint lastId = blindBoxTypeArray.length - 1; 
        uint length = blindBoxTypeArray.length;
        for (uint i = 0; i < soldOutOccupation.length; i++) { 
            for (uint j = 0; j < length; j++) { 
                if(blindBoxTypeArray[j] == soldOutOccupation[i]){
                    blindBoxTypeArray[j] = blindBoxTypeArray[lastId];
                    length = length - 1;
                }
            }
        }
        return blindBoxTypeArray;
    }
}