/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract McDonaldsApp {
    mapping(address => bool) public applicants;

    event ApplicationReceived(address applicant);

    // Stores a new value in the contract
    function register() public {
        applicants[msg.sender] = true;
        emit ApplicationReceived(msg.sender);
    }
}