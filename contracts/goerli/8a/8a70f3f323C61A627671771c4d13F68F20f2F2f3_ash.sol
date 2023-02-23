/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract ash {

    //uint count = 11;
    string count = ""; //변수

    function read_story() public view returns(string memory){
        return count;
    }

    function write_story(string memory txt) public {
        count = string.concat(count, txt);
    }

}