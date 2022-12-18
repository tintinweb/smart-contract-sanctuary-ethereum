/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// File: class.sol





pragma solidity ^0.8.12;



    contract Practice_yoyo {



       string story = "write down" ;



       function button() public view returns(string memory){

           return story;

       }

    

        function button2(string memory txt) public {

            story = string.concat(story, txt);

        }





}