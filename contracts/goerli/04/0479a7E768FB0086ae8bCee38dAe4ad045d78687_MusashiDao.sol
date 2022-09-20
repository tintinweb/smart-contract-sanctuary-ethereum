/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IdaoContract {
    function balanceOf(address account) external view returns (uint256);
}


contract MusashiDao {

    address public owner;
    uint256 nextProposal;
    address[] public validTokens;
    IdaoContract daoContract;

    constructor () {
        owner = msg.sender;
        nextProposal = 1;
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
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
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

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (
        bool
    ){
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), 'You need to hold at least 50,000,000 $MUSHI to put forth proposals.');

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This proposal doesn't exist.");
        require(checkVoteEligibility(_id, msg.sender), "You can't vote on this proposal.");
        require(!Proposals[_id].voteStatus[msg.sender], 'You have already voted on this proposal.');
        require(block.number <= Proposals[_id].deadline, 'The deadline has passed for this proposal.');

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true; 

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
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