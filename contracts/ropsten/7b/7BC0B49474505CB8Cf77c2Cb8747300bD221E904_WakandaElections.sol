/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
pragma experimental ABIEncoderV2;

contract WakandaElections {

    struct Voter {
        uint weight; 
        bool voted;  
        uint vote;   
    }

    struct Proposal {
        string name;   
        uint voteCount;
    }
    
    //owner of smart contract (person who deployed SC)
    address public chairperson; 

    mapping(address => Voter) public voters;

    Proposal[] public proposals;
    uint public candidateConut;
    string public currentThirdCandidate;

    event NewChallenger(bool isPresent);


    constructor() {
        candidateConut = 4;
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
    }

    function injectProposalNames(string[] memory proposalNames) public {
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function vote(uint proposal) public {
        Voter storage sender =  voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += 1;
        triggerEvent();
    }

    //First 3 candiates are winners of Wakanda elections
    function winningCandidates() public returns (Proposal[] memory)
    {
        uint first = 0;
        uint second = 0;
        uint third = 0;
        
        Proposal[] memory winningCandiadatesList = new Proposal[](candidateConut);    

        for (uint i = 0; i < proposals.length; i++) {
            Proposal storage candidate = proposals[i];

            // If current element is
            // greater than first
            if (proposals[i].voteCount > first) {
                third = second;
                second = first;
                first = candidate.voteCount;

                winningCandiadatesList[0].voteCount = first;
                winningCandiadatesList[0].name = candidate.name;
            }
 
            // If proprsals[i].voteCount is in between first
            // and second then update second
            else if (proposals[i].voteCount > second) {
                third = second;
                second = candidate.voteCount;

                winningCandiadatesList[1].voteCount = second;
                winningCandiadatesList[1].name = candidate.name;
            }
 
            else if (proposals[i].voteCount > third) {
                third = candidate.voteCount;

                winningCandiadatesList[2].voteCount = third;
                winningCandiadatesList[2].name = candidate.name;

                currentThirdCandidate = candidate.name;
            }
        }

        return  winningCandiadatesList;
    }

    function isNewChallenger() public  returns (bool) {
        Proposal[] memory currentTopCandidates = winningCandidates();

        if (currentTopCandidates.length >= 3) {
            return keccak256(abi.encodePacked(currentTopCandidates[2].name)) == keccak256(abi.encodePacked(currentThirdCandidate));
        }

        return false;
    }

    function triggerEvent() public  {
        bool newChallenger = isNewChallenger();

        if (newChallenger) {
            emit NewChallenger(true);
        }
    }
}