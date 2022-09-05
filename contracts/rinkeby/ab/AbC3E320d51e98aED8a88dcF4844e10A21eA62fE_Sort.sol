/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT 
 
pragma solidity 0.8.16; 

library Sorting {
    function bubbleSort(uint[] memory _array) public pure returns(uint[] memory) {
        require(_array.length > 0, "nothing to sort");
         for(uint i = 0; i < _array.length - 1; i++) {
             for(uint j = 0; j < _array.length - i - 1; j++) {
                if(_array[j] > _array[j+1]) {
                    (_array[j], _array[j+1]) = (_array[j+1], _array[j]);
                }
             }
         }
         return _array;
    }

    function bubbleSortDesc(uint[] memory _array) public pure returns(uint[] memory) {
        require(_array.length > 0, "nothing to sort");
         for(uint i = 0; i < _array.length - 1; i++) {
             for(uint j = 0; j < _array.length - i - 1; j++) {
                if(_array[j] < _array[j+1]) {
                    (_array[j], _array[j+1]) = (_array[j+1], _array[j]);
                }
             }
         }
         return _array;
    }
}

contract Sort {
    using Sorting for uint[];
    function get(uint[] memory _a) public pure returns(uint[] memory){
        return _a.bubbleSortDesc();
    }
}