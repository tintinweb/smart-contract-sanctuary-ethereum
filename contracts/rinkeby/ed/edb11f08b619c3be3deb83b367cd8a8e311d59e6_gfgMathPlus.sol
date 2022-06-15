//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

contract gfgMathPlus
{

    // Declaring the state
    // variables
    uint256 public firstNo ;
    uint256 public secondNo ;

    constructor (uint256 _firstNo, uint256 _secondNo) {
        firstNo = _firstNo;
        secondNo = _secondNo;
    }
 
    // Defining the function
    // to set the value of the
    // first variable
    function firstNoSet(uint256 x) public
    {
        firstNo = x;
    }
 
    // Defining the function
    // to set the value of the
    // second variable
    function secondNoSet(uint256 y) public
    {
        secondNo = y;
    }
 
    // Defining the function
    // to add the two variables
    function add() view public returns (uint256)
    {
        uint256 Sum = firstNo + secondNo ;
         
        // Sum of two variables
        return Sum;
    }
}