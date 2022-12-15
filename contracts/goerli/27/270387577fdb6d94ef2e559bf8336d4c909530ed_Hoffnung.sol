/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
contract Hoffnung {
    string count = "";
    function my_function1() public view returns(string memory){
        return count;
    } 
    function my_function2(string memory txt) public {
        count = string.concat(count, txt);
    }
}