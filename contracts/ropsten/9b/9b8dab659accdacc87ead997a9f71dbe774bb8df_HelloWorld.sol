/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract HelloWorld{
    string public myString = "hello world";
    function showMyString() public view returns(string memory){
        return myString;
    }
    function setMyString(string memory _str) public{
        myString = _str;
    }
}