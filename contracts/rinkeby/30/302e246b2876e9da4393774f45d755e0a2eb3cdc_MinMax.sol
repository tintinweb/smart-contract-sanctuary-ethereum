/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

contract MinMax {

    // uint public min;
    // uint public max;
    uint[] array;

    function inputArray(uint[] memory array_) public returns(uint) {
        array = array_;
        return(5);
    }    
        
    function Min_Max() public view returns(uint min, uint max){
        min = array[0];
        uint i;
        for(i; i < array.length; i++){
            if(array[i] > max){
                max = array[i];
            }
            if(array[i] < min){
                min = array[i];
            }
        }
        return (min,max);
    }
}