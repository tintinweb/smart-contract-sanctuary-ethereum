/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract FirstClass {

    string count="first story";

    function my_function1() public view returns(string memory){
        return count;
    }

}