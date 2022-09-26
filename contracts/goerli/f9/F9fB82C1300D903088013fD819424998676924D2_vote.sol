// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract vote {
    address[] public voters; // it stores the list of voters -> database
    address[] public partiesAddress;
    string[] public partiesName;
    uint public noOfParties;
    mapping(address => uint) public votes; // verifies whether a voter has casted votes or not
    mapping(string => uint) public partiesVoteCount; // which party has got how many votes
    uint public totalCastedVotes;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthiticated user!!");
        _;
    }

    function participateInElection(string memory _pName) public {
        partiesName.push(_pName);
        partiesAddress.push(msg.sender);
        noOfParties++;
    }

    function casteVote(string memory _name) public {
        require(votes[msg.sender] == 0, "your vote has been casted");
        voters.push(msg.sender);
        totalCastedVotes++;
        votes[msg.sender] = 1;
        partiesVoteCount[_name]++;
    }

    function getResult() public view onlyAdmin returns (string memory) {
        uint magicFigure = 6;
        for (uint i = 0; i < partiesName.length; i++) {
            if (partiesVoteCount[partiesName[i]] > magicFigure) {
                return partiesName[i];
            }
        }
        for (uint i = 0; i < partiesName.length; i++) {
            if (partiesVoteCount[partiesName[i]] > magicFigure - 1) {
                return partiesName[i];
            }
        }
        for (uint i = 0; i < partiesName.length; i++) {
            if (partiesVoteCount[partiesName[i]] > magicFigure - 2) {
                return partiesName[i];
            }
        }
        return "none";
    }
}