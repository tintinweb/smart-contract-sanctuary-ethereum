/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract AAA {

    uint[] soldOutOccupation;

    function init(uint[] memory _array) public {
        soldOutOccupation = _array;
    }
  
    function updateBlindBoxTypeArrayLength(uint256 _arrayLength) public view returns(uint[] memory blindBoxTypeArray) {
        blindBoxTypeArray = new uint[](_arrayLength);
        for (uint i = 0; i < _arrayLength; i++) {  
            blindBoxTypeArray[i] = i+1;
        }
        for (uint i = 0; i < soldOutOccupation.length; i++) { 
            for (uint j = 0; j < blindBoxTypeArray.length; j++) { 
                if(j == 0){
                    blindBoxTypeArray[j] = blindBoxTypeArray[j+1];
                }
                if(blindBoxTypeArray[j] == soldOutOccupation[i]){
                    blindBoxTypeArray[j] = blindBoxTypeArray[j-1];
                }
            }
        }
        return blindBoxTypeArray;
    }
}