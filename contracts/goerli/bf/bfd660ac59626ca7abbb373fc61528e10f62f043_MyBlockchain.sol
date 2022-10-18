/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract MyBlockchain  {
   
    struct NumInfo {
        uint number ;
        uint lastupdated ;
    }
    
    NumInfo _numInfo ;
    
    function newNumInfo (uint _newNumber) public  { 
        _numInfo = NumInfo (_newNumber, block.timestamp) ; 
     }
    
    function getNumInfo() public view returns (uint, uint) {
        return (_numInfo.number, _numInfo.lastupdated) ;
    }
}