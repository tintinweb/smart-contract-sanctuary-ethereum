/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.12;

contract FirstClass {

    string count = "Thank you. very much!";

    function function_read() public view returns(string memory){
       return count;
    }

    function function_hi() public{
       count;
    }

    function function_buy() public payable{
       count;
    }

}