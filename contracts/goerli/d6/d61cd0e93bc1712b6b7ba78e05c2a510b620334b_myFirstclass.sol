/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// File: class.sol





pragma solidity ^0.8.12;



    contract myFirstclass {



        string story = "";

        

        function button() public view returns(string memory){

            return story;

        }

        

        function button2() public {

            story = string.concat(story, "");

        }

    }