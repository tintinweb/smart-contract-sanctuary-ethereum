/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

/** 
 * @title Simple vote system
 * @dev Implements voting process.
 */
contract SimpleVote {

    struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal
    }

    struct Proposal {
        string name;   // short name
        uint voteCount; // number of accumulated votes
    }

    mapping(address => Voter) public voters;

    Proposal[] public proposals;
    
    address[] public votersAddress;

    /** 
     * @dev Create a new vote to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    constructor(string[] memory proposalNames) {
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    /**
     * @dev Returns all voters addresses.
     * @return voters addresses.
     */
    function votersAddresses() external view returns (address[] memory) {
        return votersAddress;
    }

    /**
     * @dev Give your vote to proposal 'proposals[proposal].name'.
     * @param proposal index of proposal in the proposals array
     */
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        votersAddress.push(msg.sender);
        proposals[proposal].voteCount += 1;
    }
}