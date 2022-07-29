/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract testing{
    string yourName;
    uint256 public yourAge;
    bool public clicked=false;
    mapping (string => uint256) public NameToAge;

    function set(string memory name, uint256 age) public{
        yourName = name;
        yourAge = age;
        NameToAge[yourName] = yourAge;
    }
    function hello() view public returns (string memory){
        return yourName;
    }
    function clickbool() public{
        clicked = true;
    }
}