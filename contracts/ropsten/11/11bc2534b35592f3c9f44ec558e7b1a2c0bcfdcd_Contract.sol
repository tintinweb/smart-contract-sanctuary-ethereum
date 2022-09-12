/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT

 pragma solidity ^0.8.0;
  
   contract Contract 
   {

     constructor (string memory name_, string memory symbol_) 
     {
          
        _name = name_ ;
        _symbol = symbol_ ;

     }

    string _name ;
    
    string _symbol ;

    
    function name () public view returns ( string memory ) 
    {
        
        return _name ;
    }

    function symbol () public view returns ( string memory ) 
    {

        return _symbol ;
    }




   }