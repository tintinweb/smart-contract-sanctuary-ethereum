// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct ElectionStruct {
    string name;
    uint256 startDate;
    uint256 registrationPeriodEnd;
    uint256 votingPeriodEnd;
}

struct Registered {
    address userAddress;
    address[] votes;
}

contract Election {
    mapping(uint256 => ElectionStruct) public elections;
    mapping(uint256 => address[]) public electionToRegisteredUsers;
    mapping(address => uint256[]) public voteeToElections;
    mapping(uint256 => mapping(address => uint256))
        public electionRegisteredUserVotes;
    event TryUserRegisterEvent(
        uint256 electionId,
        address userToBeRegistered,
        uint256 currentTime,
        uint256 startDate,
        uint256 registrationPeriodEnd
    );
    event UserRegisteredEvent(uint256 electionId, address registeredUser);
    event UserVotedEvent(
        uint256 electionId,
        address registeredUser,
        address voteeUser
    );
    uint256 public electionCount;

    function startElection(
        string memory _name,
        uint256 _startDate,
        uint256 _registrationPeriodEnd,
        uint256 _votingPeriodEnd
    ) public {
        require(
            _startDate >= block.timestamp,
            "You cannot start an election in the past"
        );
        require(_startDate > 0, "You must provide a startDate!");
        require(
            _registrationPeriodEnd > 0,
            "You must provide the end of the registration period"
        );
        require(_votingPeriodEnd > 0, "You must provide the voting period end");
        require(
            _registrationPeriodEnd > _startDate,
            "The registration period cannot end before the election is started"
        );
        require(
            _votingPeriodEnd > _registrationPeriodEnd,
            "The voting period cannot end before the registration process stops"
        );

        elections[electionCount] = ElectionStruct(
            _name,
            _startDate,
            _registrationPeriodEnd,
            _votingPeriodEnd
        );
        electionCount++;
    }

    function register(uint256 _electionId) public {
        ElectionStruct memory election = elections[_electionId];
        emit TryUserRegisterEvent(
            _electionId,
            msg.sender,
            block.timestamp,
            election.startDate,
            election.registrationPeriodEnd
        );
        require(
            election.startDate <= block.timestamp &&
                election.registrationPeriodEnd >= block.timestamp,
            "Cannot register. You are outside the registration period"
        );

        address[] memory registeredUsers = electionToRegisteredUsers[
            _electionId
        ];
        for (uint256 index = 0; index < registeredUsers.length; index++) {
            require(
                registeredUsers[index] != msg.sender,
                "You cannot register twice!"
            );
        }
        electionToRegisteredUsers[_electionId].push(msg.sender);
        emit UserRegisteredEvent(_electionId, msg.sender);
    }

    function getElections() public view returns (ElectionStruct[] memory) {
        ElectionStruct[] memory id = new ElectionStruct[](electionCount);
        for (uint256 i = 0; i < electionCount; i++) {
            ElectionStruct memory election = elections[i];
            id[i] = election;
        }
        return id;
    }

    function castVote(uint256 _electionId, address _votedAddress) public {
        ElectionStruct memory election = elections[_electionId];
        require(
            election.registrationPeriodEnd <= block.timestamp &&
                election.votingPeriodEnd >= block.timestamp,
            "Cannot vote. You are outside the voting period"
        );

        for (
            uint256 index = 0;
            index < voteeToElections[msg.sender].length;
            index++
        ) {
            require(
                voteeToElections[msg.sender][index] != _electionId,
                "You already voted in this election"
            );
        }

        bool found = false;
        for (
            uint256 index = 0;
            index < electionToRegisteredUsers[_electionId].length;
            index++
        ) {
            if (
                electionToRegisteredUsers[_electionId][index] == _votedAddress
            ) {
                found = true;
            }
        }

        require(
            found,
            "The address you want to vote did not register in the election"
        );

        voteeToElections[msg.sender].push(_electionId);
        electionRegisteredUserVotes[_electionId][_votedAddress]++;
        emit UserVotedEvent(_electionId, _votedAddress, msg.sender);
    }
}