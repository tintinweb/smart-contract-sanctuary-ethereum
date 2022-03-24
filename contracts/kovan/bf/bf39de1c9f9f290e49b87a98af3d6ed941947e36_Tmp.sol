/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Tmp{
    string public name;

    function setName(string memory _name) public{
        name= _name;
    }
}