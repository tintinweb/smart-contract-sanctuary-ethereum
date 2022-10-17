/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract MyBlockchain  {
   
    struct NumInfo {
        uint newNumber ;
        uint lastupdated ;
    }
    
    
    NumInfo[] public _numInfo ; 
    
     function newNumInfo (uint newNumber) public  { 
        uint lastupdated = block.timestamp ; 
        _numInfo.push(NumInfo(newNumber, lastupdated)) ;
     }
}