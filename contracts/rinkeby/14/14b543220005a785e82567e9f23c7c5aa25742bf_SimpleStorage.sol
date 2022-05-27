/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;


/// @title  this is a hello world contract

contract SimpleStorage {
    string public name1 = "hello";
    string public name2 = "world";

    function updateName(string memory _newName) public {
        name1 = _newName;
    }




}