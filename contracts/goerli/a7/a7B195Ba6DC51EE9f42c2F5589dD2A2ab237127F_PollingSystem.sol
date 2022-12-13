// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PollingSystem {
    constructor() {
        Voter memory newVoter = Voter({
            voterAddress: msg.sender,
            timesVoted: 0
        });
        voters[newVoter.voterAddress] = newVoter;
    }

    struct Poll {
        address pollCreator;
        uint votes;
        string idea;
        uint pollID;
    }
    struct Poller {
        address pollerAddress;
    }
    struct Voter {
        address voterAddress;
        uint timesVoted;
    }

    mapping(string => Poll) public polls;
    mapping(address => Poller) public pollers;
    mapping(address => Voter) public voters;

    function becomePoller() public {
        require(
            pollers[msg.sender].pollerAddress != msg.sender,
            "You are already a poller"
        );
        Poller memory newPoller = Poller({pollerAddress: msg.sender});
        pollers[newPoller.pollerAddress] = newPoller;
    }

    function createPoll(string memory _idea) public {
        require(
            pollers[msg.sender].pollerAddress == msg.sender,
            "You have to be a poller to create one"
        );
        uint id;
        id++;
        Poll memory newPoll = Poll({
            pollCreator: msg.sender,
            votes: 0,
            idea: _idea,
            pollID: id
        });
        polls[newPoll.idea] = newPoll;
    }

    function vote(string memory _idea) public {
        Poll storage poll = polls[_idea];
        Voter storage voter = voters[msg.sender];
        require(
            poll.pollCreator != msg.sender,
            "You cannot vote your own poll!"
        );
        require(voter.timesVoted == 0, "You cannot vote twice!");

        poll.votes++;
        voter.timesVoted++;
    }
}