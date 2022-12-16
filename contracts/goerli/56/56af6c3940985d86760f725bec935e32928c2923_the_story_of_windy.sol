/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract the_story_of_windy{
    
    string count = "the story of storm";

    function windy_story_button_1() public view returns(string memory){
        return count;
    }

    function windy_story_button_2(string memory txt) public{
        count = string.concat(count, " ", "dead");
        count = string.concat(count, " ", txt);
        count = string.concat(count, " ", "Resurrection");
        count = string.concat(count, " ", "1");
        count = string.concat(count, " ", "2");
        count = string.concat(count, " ", "3");
        count = string.concat(count, " ", "4");
        count = string.concat(count, " ", txt);
    }
}