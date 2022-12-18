/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract FirstClass_homework {

    string count = "";

    function homework_guest_book() public view returns(string memory){
        return count;
    }

    function guest_book(string memory txt) public{
        count = string.concat(count, txt);
    }

}