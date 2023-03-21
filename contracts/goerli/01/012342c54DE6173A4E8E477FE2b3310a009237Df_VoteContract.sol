/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VoteContract {
    mapping(address => bool) public voted;
    uint public yesVotes;
    uint public noVotes;
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function voteYes() public payable {
        require(!voted[msg.sender], "You have already voted.");
        voted[msg.sender] = true;
        yesVotes++;
    }
    
    function voteNo() public payable {
        require(!voted[msg.sender], "You have already voted.");
        voted[msg.sender] = true;
        noVotes++;
    }
}