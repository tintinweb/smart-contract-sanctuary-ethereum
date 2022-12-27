/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract Firstphone{  

        function simple() public payable {

        }    

        function inchool() public {

            address payable to = payable(msg.sender);
            to.transfer(address(this).balance);




        }   








}