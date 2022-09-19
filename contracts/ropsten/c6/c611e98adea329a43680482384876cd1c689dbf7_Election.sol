/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

//SPDX-License-Identifier:MIT


pragma solidity 0.8.15;

contract Election{
    //Store Candidate
    //Read  Candidate
    string public candidate;
    //Constructor
    function vote() public {
        candidate = "Candidate 1";
    }
}