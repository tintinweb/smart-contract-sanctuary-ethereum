// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// @dev Arrays Library for pop elements
library Arrays {

    function popUint256( uint256[] memory array, uint256 element ) internal pure returns( uint256[] memory ){

        uint256[] memory poppedArray = new uint256[]( array.length - 1);
        uint x = 0;
        for (uint256 i = 0; i < array.length; i++ ) {
            if (array[i] != element) {
                poppedArray[x] = array[i];
                x++;
            }
        }
        return poppedArray;
    }

    function popAddress( address[] memory array, address element ) internal pure returns( address[] memory ){

        address[] memory poppedArray = new address[]( array.length - 1);
        uint x = 0;
        for (uint256 i = 0; i < array.length; i++ ) {
            if (array[i] != element) {
                poppedArray[x] = array[i];
                x++;
            }
        }
        return poppedArray;
    }
}