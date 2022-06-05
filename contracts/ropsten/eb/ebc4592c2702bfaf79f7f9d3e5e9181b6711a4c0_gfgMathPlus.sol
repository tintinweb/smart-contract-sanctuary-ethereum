/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// Solidity program to
// demonstrate addition
pragma solidity >=0.7.0 <0.9.0;
contract gfgMathPlus
{
    // Declaring the state
    // variables
    uint firstNo ;
    uint secondNo ;
 
    // Defining the function
    // to set the value of the
    // first variable
    function firstNoSet(uint x) public
    {
        firstNo = x;
    }
 
    // Defining the function
    // to set the value of the
    // second variable
    function secondNoSet(uint y) public
    {
        secondNo = y;
    }
 
    // Defining the function
    // to add the two variables
    function add() view public returns (uint)
    {
        uint Sum = firstNo + secondNo ;
         
        // Sum of two variables
        return Sum;
    }
}