/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld{
    string private str;

    constructor (string memory _str){
        str=_str;
    }
    function getStr() public view returns(string memory){
        return str;
    }
    function setStr(string memory _str) public {
        str = _str;
    }
}