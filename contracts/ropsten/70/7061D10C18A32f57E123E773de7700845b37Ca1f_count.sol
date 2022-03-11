/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library count{
    struct hold{
        uint a;
     
    }
    
    function subUint(hold storage s, uint b) public  view returns(uint){
        
        require(s.a >= b); // Make sure it doesn't return a negative value.
        return s.a - b;
        
    }
    function addUint(uint a , uint b) public  pure  returns(uint){
        
        uint c = a + b;
        
        require(c >= a);   // Makre sure the right computation was made
        return c;
    }
}