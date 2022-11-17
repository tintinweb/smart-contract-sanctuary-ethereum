// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Test.sol";

contract Voting is Test {
    mapping(address => bool) public hasVoted;
    mapping(address => uint256) public votesReceived;
    mapping(address => bool) public isRegistered;

    function register() public override(Test) {
        require(!isRegistered[msg.sender], "Already registered");
        isRegistered[msg.sender] = true;
    }

    function voteFor(address _candidate) public override(Test) canVote {
        require(isRegistered[_candidate], "Candidate not registered");
        require(_candidate != msg.sender, "Cannot vote for yourself");
        hasVoted[msg.sender] = true;
        votesReceived[_candidate] += 1;
    }

    function numberOfVotesReceivedFor(address _candidate)
        public
        view
        override(Test)
        returns (uint)
    {
        return votesReceived[_candidate];
    }

    modifier canVote() {
        require(isRegistered[msg.sender], "You are not registered");
        require(!hasVoted[msg.sender], "You can only vote once");
        _;
    }
}