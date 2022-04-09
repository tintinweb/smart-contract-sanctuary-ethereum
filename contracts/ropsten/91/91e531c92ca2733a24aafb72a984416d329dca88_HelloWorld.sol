/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.8.0;

contract HelloWorld {
    string public str1;
    string public str2;

    constructor() {
        str1 = "Initial string 1";
        str2 = "Initial string 2";
    }

    function setStrings(string memory _str1, string memory _str2) public returns(bool){
        str1 = _str1;
        str2 = _str2;
        return true;
    }

    function getStrings() public view returns(string memory){
        return string(abi.encodePacked(str1, " ", str2));
    }

}