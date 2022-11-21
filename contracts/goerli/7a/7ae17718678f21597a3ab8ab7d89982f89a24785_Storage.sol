/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; 


contract Storage{

    mapping(address=>uint256) value_map; //make the "template" to convert uint from adress 

    function ReadAdres(address read_adress) public view returns(uint256 value){
    value = value_map[read_adress];     //using a "template" and save value
    }
    
    function WriteValue(uint256 NewValue) public{
        value_map[msg.sender] = NewValue;  //write a new value to template to "our" msg.sender
    }
}
//extra notes