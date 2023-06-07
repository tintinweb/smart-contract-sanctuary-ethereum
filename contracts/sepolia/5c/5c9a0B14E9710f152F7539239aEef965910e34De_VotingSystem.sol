/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract VotingSystem {
    address private _owner;
    address[] public candidates;
    uint256 internal _start_time;
    uint256 internal _end_time;
    mapping(address => uint8) private voice_box;
    mapping(address => address) private voters;
    address[] private voter_addresses;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner allowed");
        _;
    }

    function setVotingPeriod(uint128 start_time, uint128 end_time)
        public
        onlyOwner
    {
        _start_time = start_time;
        _end_time = end_time;
    }

    function addCandidate(address candidate_address) public onlyOwner {
        require(voice_box[candidate_address] <= 0, "Candidate already exist");
        voice_box[candidate_address] = 0;
        candidates.push(candidate_address);
    }

    function getTotalVotersOf(address candidate_address)
        public
        view
        returns (uint8)
    {
        return voice_box[candidate_address];
    }

    function doVoteFor(address candidate_address) public {
        require(msg.sender != _owner, "Owner is not allowed to vote");
        require(
            msg.sender != candidate_address,
            "Candidate is not allowed to theirself"
        );
        require(
            voice_box[candidate_address] >= 0,
            "No candidate with your request registered"
        );
        require(block.timestamp >= _start_time, "Voting period is not started");
        require(block.timestamp < _end_time, "Voting period has been closed");
        require(
            voters[msg.sender] == address(0),
            "Your address is already took a vote"
        );
        voters[msg.sender] = candidate_address;
        voter_addresses.push(msg.sender);
        voice_box[candidate_address] = voice_box[candidate_address] + 1;
    }

    function transferOwnership(address new_owner) public onlyOwner {
        require(_owner != msg.sender, "Can't assign the same address");
        _owner = new_owner;
    }

    function giveReward() public view onlyOwner {
        require(block.timestamp >= _end_time && block.timestamp >= _start_time, "Voting period is still active");
        address highestCandidate;
        uint8 totalCounted;
        address[] memory whoVoteTheHighestCandidate;
        uint16 filteredCounted = 0;

        for (uint8 i = 0; i < candidates.length; i++) 
        {
            if(voice_box[candidates[i]] > totalCounted) {
                highestCandidate = candidates[i];
                totalCounted = voice_box[candidates[i]];
            }
        }

        for (uint j = 0; j < voter_addresses.length; j++) 
        {
            if(voters[voter_addresses[j]] == highestCandidate) {
                whoVoteTheHighestCandidate[filteredCounted] = voter_addresses[j];
            }
        }

        // get 'randomIdx' = random number of range based on length of 'whoVoteTheHighestCandidate'
        // return whoVoteTheHighestCandidate[randomIdx]
    }
}