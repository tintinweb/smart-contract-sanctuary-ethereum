/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.7;    

contract helloworld2 {

    string name;
    uint age;

    function getname() public view returns (string memory) 
    {
        return name;
    }

    function getage() public view returns (uint) 
    {
        return age;
    }

    function setname(string memory newname) public {
        name = newname;
    }



}