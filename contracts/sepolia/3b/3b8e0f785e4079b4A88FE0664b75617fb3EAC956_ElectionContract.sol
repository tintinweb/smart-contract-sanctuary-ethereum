// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ElectionContract {
    struct Candidate {
        string name;
        uint256 nid;
        string symbolName;
        string symbolImg;
        uint256 votes;
        bytes32 hash;
    }
    struct Voter {
        string name;
        uint256 nid;
        bool votingStatus;
        bytes32 hash;
    }

    struct Election {
        string name;
        bytes32 hash;
        uint256 startTime;
        uint256 endTime;
        Candidate[] candidates;
        Voter[] voters;
    }

    address owner;
    uint256 numberOfElections = 0;
    mapping(uint256 => Election) elections;

    constructor() {
        owner = msg.sender;
    }

    //create new election
    function createElection(
        string memory _electionName,
        uint256 _starTime,
        uint256 _endTime
    ) public {
        require(owner == msg.sender, "Unauthorized access.");
        require(
            _starTime > block.timestamp,
            "Start time can't be less than current time."
        );
        require(
            _endTime > _starTime,
            "End time must be greater than start time."
        );

        Election storage election = elections[numberOfElections];
        election.name = _electionName;
        election.startTime = _starTime;
        election.endTime = _endTime;

        //hashing
        bytes memory concatenatedInputs = abi.encodePacked(
            _electionName,
            _starTime,
            _endTime,
            block.timestamp
        );
        election.hash = keccak256(concatenatedInputs);

        numberOfElections++;
    }

    //register candidate
    function registerCandidate(
        uint256 _electionId,
        string memory _name,
        uint256 _nid,
        string memory _symbolName,
        string memory _symbolImg
    ) public {
        require(owner == msg.sender, "Unauthorozied access.");
        require(bytes(_name).length > 0, "Candidate name can't be empty.");
        require(
            bytes(_symbolImg).length > 0,
            "Candidate symbol img url can't be empty."
        );
        Election storage election = elections[_electionId];

        require(
            election.startTime > block.timestamp,
            "The registration period has exceeded."
        );

        require(
            isCandidateRegisterd(_electionId, _nid) == false,
            "Candidate already registerd"
        );
        bytes memory concatenatedInputs = abi.encodePacked(_name, _nid);
        bytes32 generatedHash = keccak256(concatenatedInputs);

        Candidate memory candidate;
        candidate.name = _name;
        candidate.symbolName = _symbolName;
        candidate.symbolImg = _symbolImg;
        candidate.nid = _nid;
        candidate.votes = 0;
        candidate.hash = generatedHash;
        election.candidates.push(candidate);
    }

    //checking voter already registerd or not
    function isCandidateRegisterd(
        uint256 _electionId,
        uint256 _nid
    ) internal view returns (bool) {
        Election storage election = elections[_electionId];
        for (uint256 i; i < election.candidates.length; i++) {
            if (election.candidates[i].nid == _nid) {
                return true;
            }
        }
        return false;
    }

    //voter registration
    function registerVoter(
        uint256 _electionId,
        string memory _name,
        uint256 _nid
    ) public returns (bytes32) {
        require(owner == msg.sender, "Unauthorized acess.");
        require(bytes(_name).length > 0, "Name can't be empty.");
        require(_electionId >= 0, "Election id can't be empty.");
        require(_nid > 0, "Nid number can't be empty.");

        Election storage election = elections[_electionId];

        require(
            election.startTime > block.timestamp,
            "The registration period has exceeded."
        );

        require(
            isVoterRegistered(_electionId, _nid) == false,
            "Voters have already been registered."
        );

        bytes memory concatenatedInputs = abi.encodePacked(_name, _nid);
        bytes32 generatedHash = keccak256(concatenatedInputs);

        Voter memory voter;
        voter.name = _name;
        voter.nid = _nid;
        voter.hash = generatedHash;
        voter.votingStatus = false;
        election.voters.push(voter);
        return generatedHash;
    }

    //checking voter already registered or not
    function isVoterRegistered(
        uint256 _electionId,
        uint256 _voterNid
    ) internal view returns (bool) {
        Election storage election = elections[_electionId];
        for (uint256 i; i < election.voters.length; i++) {
            if (election.voters[i].nid == _voterNid) {
                return true;
            }
        }
        return false;
    }

    //give vote
    function giveVote(
        uint256 _electionId,
        bytes32 _voterHash,
        bytes32 _candidateHash
    ) public {
        Election storage election = elections[_electionId];
        require(
            election.startTime < block.timestamp,
            "Election haven't started yet."
        );
        require(election.endTime > block.timestamp, "Election time exceeded.");
        (bool status, uint256 voterIndex) = isVoterEligable(
            _electionId,
            _voterHash
        );
        require(
            status == false,
            "You are ineligible to vote or already given."
        );

        (bool candidateStatus, uint256 candidateIndex) = isCandidateAvailable(
            _electionId,
            _candidateHash
        );

        require(candidateStatus == true, "Something went wrong.");

        Voter[] storage allVoters = election.voters;
        Candidate[] storage allCandidates = election.candidates;

        allCandidates[candidateIndex].votes = 1;
        allVoters[voterIndex].votingStatus = true;
    }

    function isVoterEligable(
        uint256 _electionId,
        bytes32 _voterHash
    ) internal view returns (bool, uint256) {
        Voter[] memory voter = elections[_electionId].voters;
        for (uint256 i; i < voter.length; i++) {
            if (voter[i].hash == _voterHash) {
                return (voter[i].votingStatus, i);
            }
        }
        return (true, 0);
    }

    //checking candidate availability
    function isCandidateAvailable(
        uint256 _electionId,
        bytes32 _candidateHash
    ) internal view returns (bool, uint256) {
        Candidate[] storage allCandidates = elections[_electionId].candidates;
        for (uint256 i = 0; i < allCandidates.length; i++) {
            if (allCandidates[i].hash == _candidateHash) {
                return (true, i);
            }
        }

        return (false, 0);
    }

    //get all elections
    function getElections() public view returns (Election[] memory) {
        Election[] memory allEllections = new Election[](numberOfElections);
        for (uint256 i; i < numberOfElections; i++) {
            allEllections[i] = elections[i];
        }
        return allEllections;
    }
}