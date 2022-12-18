/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// File: class.sol





pragma solidity ^0.8.12;



    contract Lets_get_it_on{



        string story = "once upon a time";



        function this_is_your_story() public view returns(string memory) {

            return story;

        }



        function write_down_here(string memory your_story) public {

            story = string.concat(story, " ", your_story);

        }

}