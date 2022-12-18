/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// File: class.sol





pragma solidity ^0.8.12;



    contract firstclass {



        string story;



        function button_1() public view returns(string memory) {

            return story;

        } 



        function button_2(string memory this_is_test) public {

            story = this_is_test ;

        }

    }