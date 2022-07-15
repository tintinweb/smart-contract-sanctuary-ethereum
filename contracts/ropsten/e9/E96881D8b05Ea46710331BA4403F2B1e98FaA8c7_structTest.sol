/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract structTest{

    struct student{
        uint grade;
        string name;
    }

    function mirror(student memory s) public returns (student memory) {
        return s;
    }
        
}