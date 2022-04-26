/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract VotingApp{

    uint256 private Number1;
    uint256 private Number2;
    address private admin;

    constructor() {
        admin = msg.sender;        
        Number1 = 10;
        Number2 = 20;
    }

    // Checks if the person accessing contract has same address as admin from constructor
    modifier onlyAdmin() {
       require(msg.sender == admin, 
       "Function can be run only by user who created this contract, the administrator.");
       _;
    }

    function ChangeNumber1(uint256 _newNr) onlyAdmin public {
        Number1=_newNr;
    }

    function ChangeNumber2(uint256 _newNr) public {
        Number2=_newNr;
    }

     // Function to Check the Voting Stage Status
    function CheckNumber1() public view returns (uint256) {
        return Number1;       
    }

     // Function to Check the Voting Stage Status
    function CheckNumber2() public view returns (uint256) {
        return Number2;       
    }
}