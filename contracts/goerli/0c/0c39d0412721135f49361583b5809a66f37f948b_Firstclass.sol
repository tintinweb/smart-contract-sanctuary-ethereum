/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Firstclass{
    //uint count = 3;
    string countt = "Mong";
    string count = " Hee";

    function my_function1() public view returns(string memory){
       return countt;
    }
    function addLine(string memory added_text) public {
        countt = string.concat(countt,added_text);
    }
    // function my_function2() public {
    //     countt = string.concat(countt,count);
    // }
}