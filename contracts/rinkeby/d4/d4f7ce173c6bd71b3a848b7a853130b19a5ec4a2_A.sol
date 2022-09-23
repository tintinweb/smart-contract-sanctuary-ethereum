/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract A {
    
    string[] name;
    function pushName(string memory _name) public {
        name.push(_name);
    }

    function getName(uint _n) public view returns(string memory){
        return name[_n];
    }

    function getNameLen() public view returns(uint){
        return name.length;
    }

}