/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT

//MusashiDAO

//Together we unite as one.
//Together we conquer.
//Together we achieve eternal life

//We are Musashi

pragma solidity ^0.8.7;


interface IdaoContract {
    function balanceOf(address account) external view returns (uint256);
}


contract MusashiDao {

    address public owner;
    uint256 public nextProposal;
    uint256 public nextVote;
    address[] public validTokens;
    IdaoContract daoContract;

    constructor () {
        owner = msg.sender;
        nextProposal = 1;
        nextVote = 1;
        daoContract = IdaoContract(0x962E3bF94F1020855f0729e0755Db81EDFa1fd63);
        validTokens = [0x962E3bF94F1020855f0729e0755Db81EDFa1fd63];
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    struct vote {
        uint256 id;
        bool exists;
        uint256 votesUp;
        uint256 votesDown;
        address voter1;
        uint256 proposal;
        bool votedFor;
    }

    mapping(uint256 => proposal) public Proposals;

    mapping(uint256 => vote) public Votes;

    event proposalCreated(
        uint256 id,
        string description,
        address proposer
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal, 
        bool votedFor
    );

    event proposalCount(
        uint256 id,
        bool passed
    );

    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ){
        for (uint i = 0; i < validTokens.length; i ++) {
            if(daoContract.balanceOf(_proposalist) >= 1) {
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description) public {
        require(checkProposalEligibility(msg.sender), 'You need to hold at least 1 $MUSHI to put forth proposals.');

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 50000;

        emit proposalCreated(nextProposal, _description, msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(checkProposalEligibility(msg.sender), 'You need to hold at least 1 $MUSHI to put forth proposals.');
        require(Proposals[_id].exists, "This proposal doesn't exist.");
        require(!Proposals[_id].voteStatus[msg.sender], 'You have already voted on this proposal.');
        require(block.number <= Proposals[_id].deadline, 'The deadline has passed for this proposal.');

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true; 

        vote storage newVote1 = Votes[nextVote];
        newVote1.id = nextVote;
        newVote1.exists = true;
        newVote1.votesUp = p.votesUp;
        newVote1.votesDown = p.votesDown;
        newVote1.voter1 = msg.sender;
        newVote1.proposal = _id;
        newVote1.votedFor = _vote;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
        nextVote++;
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, 'Only the owner can count votes.');
        require(Proposals[_id].exists, 'This proposal does not exist.');
        require(block.number > Proposals[_id].deadline, 'Voting has not concluted.');
        require(!Proposals[_id].countConducted, 'Count already conducted.');

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

}