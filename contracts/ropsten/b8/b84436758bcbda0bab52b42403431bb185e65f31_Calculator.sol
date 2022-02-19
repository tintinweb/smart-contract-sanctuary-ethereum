/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

    contract Calculator {
        string public sonam = "my first deployment";
        function add (uint a, uint b ) public pure returns (uint){
            return a + b ;
        }
         
function substract (uint x, uint y ) public pure returns (uint){
    return x - y ;
}
function multiply (uint e, uint f ) public pure returns (uint){
    return e * f ;
}
function divide (uint g, uint h) public pure returns (uint){
    return g / h ;
}       

    }