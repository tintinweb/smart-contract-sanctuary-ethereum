//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library UtilsUint {
    /*
     Creates an array of uint with one element.
     @param element:    Uint to create an array of.
     */
    function asSingleton(uint element) external pure returns (uint[] memory) {
        uint[] memory array = new uint[](1);
        array[0] = element;
        return array;
    }

    /*
     Handles up to 2 decimal places.
     @param pool_amount:    Total amount to get a percentage of
     @param shares:         Multiply shares by 100 e.g. 5% => 500, 30% => 3000, 25.25% => 2525
     */
    function split(uint pool_amount, uint shares) external pure returns (uint) {
        uint bp = 10000;    // Base point
        require(pool_amount >= bp, "Too small to compute");
        return pool_amount * shares / bp;
    }
}