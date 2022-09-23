/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


contract AAA {
    
        string [] name;
    

    function pushName(string memory _name) public {
        name.push(_name);
        
    }
    
    function getName(uint a)public view returns(string memory){
        return name[a-1];
    }

    function getNameLength() public view returns(uint){
        return name.length-1;
    }
}