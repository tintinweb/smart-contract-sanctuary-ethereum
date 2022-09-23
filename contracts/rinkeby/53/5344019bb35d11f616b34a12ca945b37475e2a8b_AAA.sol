/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;


contract AAA {
    string[] sstring;

    function setName(string memory _name) public {
        sstring.push(_name);
    }

    function getLength() public view returns(uint){
        return sstring.length;
    }

    function getName(uint a) public view returns(string memory){
        return sstring[a];
    }

}