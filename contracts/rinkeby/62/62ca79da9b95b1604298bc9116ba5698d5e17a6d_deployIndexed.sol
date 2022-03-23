/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.7;

contract deployIndexed {

uint public id; 
string public happy; 

event test(uint indexed id, string happy);

    function testFunction(uint _id, string memory _happy) external {
        id = _id; 
        happy = _happy;
        emit test(id, happy);
    }

}