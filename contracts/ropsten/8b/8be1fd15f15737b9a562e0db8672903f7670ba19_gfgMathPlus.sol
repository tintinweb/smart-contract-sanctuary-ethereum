/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// Solidity program to
// SPDX-License-Identifier: MIT
// demonstrate addition
pragma solidity >=0.7.0 <0.9.0;
contract gfgMathPlus
{
    // Declaring the state
    // variables
    uint256 public cc ;
 
 
    // Defining the function
    // to add the two variables
    function hi(uint128 firstNo ,uint128 secondNo) public returns (uint256)
    {
        cc = firstNo + secondNo ;
         
        // Sum of two variables
        return cc;
    }
}