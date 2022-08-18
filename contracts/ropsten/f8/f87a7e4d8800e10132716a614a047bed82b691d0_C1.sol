/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

pragma solidity ^0.4.26; 
contract C1 {
function f()   {
g(8) ;    // simply passing an integer to another function
}
function g( uint x)  returns (uint )
{
   uint b = x ;
   return b ;    
}
}