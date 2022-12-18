/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract firstclass{
    string count = "";
    
    function main_story() public view returns(string memory){
        return count;
        }

    
    function story_write(string memory txt) public{
        count = string.concat(count, txt);
    }
}