/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract student   {
    string public name="Muslim";
    uint public age=23;

function  changeValue(string memory newName, uint newAge) public   {
  
    name=newName;
    age=newAge;
    

 
}

function studentRecord()private returns(string memory class,uint number) {
    name=class;
    
   
    return(class,number);
    }
    
}