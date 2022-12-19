/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

//SPDX-License-Identifier: MIT
//This is a simple pgm which shows how to put value in a variable by using a  function
pragma solidity 0.8.17 ;  // ^0.8.17 tells that any version equal and above 0.8.17 is acceptable
                           // ">=0.8.7 <0.9.0" tell the compiler that allowed range is from 0.8.7 to 0.8.9

contract SimpleStorage
{
     uint256  nu  ;  // not assigning any value defaults it to 0
                          // declaring variable inside the contract puts it into global scope , it can be accessed anywhere in the Smart contract

   function store(uint256 ourval) public
   {
     
     //  uint   tt  = 9;
         nu = ourval ;
         so();
   }

    function so()  public view returns (uint256)
   {
     return nu ;
   }

   

}