// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Polling {
    address public owner;
    uint public winningPoll;

    struct Voter {
        address _address;
        uint timesVoted;
    }

    struct Poller {
        address _address;
    }

    struct Poll {
        address creator;
        string idea;
        uint votes;
        uint id;
    }

    mapping(address => Voter) public voters;
    mapping(address => Poller) public pollers;
    Poll[] public pollsArray;
    mapping(uint => Poll) public polls;

    constructor() {
        owner = msg.sender;
        Voter memory newVoter = Voter({_address: msg.sender, timesVoted: 0});
        voters[newVoter._address] = newVoter;
    }

    function becomePoller() public {
        require(
            pollers[msg.sender]._address != msg.sender,
            "You are already a poller"
        );
        Poller memory newPoller = Poller({_address: msg.sender});
        pollers[newPoller._address] = newPoller;
    }

    function createPoll(string memory _idea) public {
        require(
            pollers[msg.sender]._address == msg.sender,
            "You cannot create a poll if you arent a poller"
        );
        Poll memory newPoll = Poll({
            creator: msg.sender,
            idea: _idea,
            votes: 3,
            id: pollsArray.length
        });
        pollsArray.push(newPoll);
        polls[newPoll.id] = newPoll;
    }

    function votePoll(uint pollId) public {
        Poll storage poll = polls[pollId];
        Poll storage pollFromArray = pollsArray[pollId];
        Voter storage voter = voters[msg.sender];

        require(
            voter._address != poll.creator,
            "You cannot vote your own poll!"
        );
        require(voter.timesVoted == 0, "You have already voted");

        poll.votes++;
        voter.timesVoted++;
        pollFromArray.votes++;
    }

    function withdrawVotes() public {
        require(owner == msg.sender, "You arent allowed to withdraw");
        for (uint i = 0; i < pollsArray.length; i++) {
            Poll memory poll = polls[i];
            if (poll.votes > winningPoll) {
                winningPoll = poll.id;
            }
        }
    }

    function getPolls() public view returns (Poll[] memory) {
        return pollsArray;
    }

    function isAddressPoller() public view returns (bool) {
        Poller memory poller = pollers[msg.sender];
        if (poller._address == msg.sender) {
            return true;
        } else {
            return false;
        }
    }
}