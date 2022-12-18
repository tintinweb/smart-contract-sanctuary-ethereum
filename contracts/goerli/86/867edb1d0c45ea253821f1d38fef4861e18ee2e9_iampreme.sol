/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract iampreme {

    string count = "NFTTTTTT";

    function my_function1() public view returns(string memory){
        return count;
    }

    function myfunction2(string memory txt) public {
        count = string.concat(count, txt);
    }
}