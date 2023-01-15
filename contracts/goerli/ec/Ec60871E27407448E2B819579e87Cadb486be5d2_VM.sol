// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract VM {
    address public manager;

    struct voter {
        string name;
        string dob;
        address account;
        uint aadhar;
    }

    struct canidate {
        string name;
        string party;
        uint vote;
    }

    uint public canidateCount;
    mapping(uint => canidate) public canidatesList;

    uint public voterCount;
    mapping(uint => voter) public votersList;

    mapping(uint => bool) public registeredVoters;
    mapping(uint => bool) public votedList;

    constructor() {
        manager = 0xFb7d8f1C94d30F6DF612AF6ae058560B2eD8F9De;
    }

    modifier restrictedToManager() {
        require(msg.sender == manager);
        _;
    }

    function addCanidate(string memory name, string memory party) public restrictedToManager {
        canidate storage newCanidate = canidatesList[canidateCount];
        canidateCount++;

        newCanidate.name = name;
        newCanidate.party = party;
        newCanidate.vote = 0;
    }

    function addVoter(
        string memory name,
        string memory dob,
        address account,
        uint aadhar
    ) public restrictedToManager {
        voter storage newVoter = votersList[aadhar];

        newVoter.name = name;
        newVoter.dob = dob;
        newVoter.account = account;
        newVoter.aadhar = aadhar;
    }

    function Vote(uint aadhar, uint canidateID) public {
        require(!votedList[aadhar]);
        votedList[aadhar] = true;
        require(votersList[aadhar].account == msg.sender);

        canidate storage selectedCanidate = canidatesList[canidateID];
        selectedCanidate.vote++;
    }
}