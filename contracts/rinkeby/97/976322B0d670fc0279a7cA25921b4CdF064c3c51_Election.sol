/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Election {
    address admin;
    struct Candidate {
        string candidateNumber;
        uint score;
    }
    Candidate[] public candidates;
    mapping(address => bool) voted;
    mapping(address => uint) ballots;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "unauthorized");
        _;
    }

    function addCandidate(string calldata candidateNumber) public onlyAdmin {
        // key value mapping
        candidates.push(Candidate({candidateNumber: candidateNumber, score: 0}));
    }

    function getCandidates() public view returns(string[] memory) {
        uint arrayLength = candidates.length;
        string[] memory list = new string[](arrayLength);
        for (uint i = 0; i < arrayLength; i++) {
            list[i] = candidates[i].candidateNumber;
        }

        return list;
    }

    function vote(uint option) public payable {
        require(option >= 0 && option <= candidates.length, "incorrect option");
        require(!voted[msg.sender], "you're voted");

        candidates[option].score++;
        ballots[msg.sender] = option;
        voted[msg.sender] = true;
    }

    function getBallot() public view returns(uint) {
      return ballots[msg.sender];
    }

    function result() public view returns (Candidate[] memory) {
       return candidates;
    }

}