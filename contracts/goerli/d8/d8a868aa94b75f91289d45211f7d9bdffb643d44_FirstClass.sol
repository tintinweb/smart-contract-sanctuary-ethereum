/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract FirstClass {

    string count = "oscar winsteel";

    function my_function1() public view returns(string memory){
        return count;
    }

}