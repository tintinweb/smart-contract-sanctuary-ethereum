/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


contract Anna_event{

    event Named(address user, string name); 

    mapping(address => string) public name;
    function setName(string memory _name ) public {
        name[msg.sender]=_name;
        emit Named(msg.sender, _name); 
   
    }

}