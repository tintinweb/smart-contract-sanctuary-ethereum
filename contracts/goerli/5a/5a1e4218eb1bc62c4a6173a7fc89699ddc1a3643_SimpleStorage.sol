/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17 ;  // ^0.8.17 tells that any version equal and above 0.8.17 is acceptable
                           // ">=0.8.7 <0.9.0" tell the compiler that allowed range is from 0.8.7 to 0.8.9

contract SimpleStorage
{
    uint256  public  nuu = 99 ;

    struct people 
    {
      uint256 num ;
      string name ;
    }
    
     people[] public person ;
     mapping (string => uint256) public num1 ;

     function putt(uint256 nu ,  string memory naam) public
     {
       person.push(people(nu,naam));
       num1[naam] = nu ;
     }
    
   function store(uint256 ourval) public
   {         nuu = ourval ;
          }

    function so()  public view  returns (uint256)
   {
     return nuu ;
   }

   

}