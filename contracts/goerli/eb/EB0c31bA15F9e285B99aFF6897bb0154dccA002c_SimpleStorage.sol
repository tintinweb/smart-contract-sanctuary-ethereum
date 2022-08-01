/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint public startTime;
    uint public endTime;

    struct Voter {
        address voterAddress;
        bool voted;
        string voteHash;
    }
    mapping(address => Voter) private voters;

    constructor() {
        startTime = block.timestamp;
        endTime = startTime + 10 minutes;
    }

    modifier withinTimeLimit() {
        require(block.timestamp < endTime);
        _;
    }

    function vote(string memory voteHash) public withinTimeLimit {
        require(!voters[msg.sender].voted);
        voters[msg.sender].voteHash = voteHash;
        voters[msg.sender].voted = true;
    }
}