/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract DAO {
    address public owner;
    uint256 nextProposal;
    uint256[] public vaildTokens;
    IdaoContract daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0xBfA75033b059134993A89ba9063bdF7744cfe139);
        vaildTokens = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
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

    function checkProposalEligibility(address _proposalList) private view returns (bool) {
        for (uint i = 0; i < vaildTokens.length; i++) {
            if (daoContract.balanceOf(_proposalList, vaildTokens[i]) > 0) {
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool) {
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
                return false;
            }
        }
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "You are not eligible to create a proposal, only NFT holders can create proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + 1 days; // +100
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }

    function voteOnPurposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You are not eligible to vote on this proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this proposal");
        require(block.number <= Proposals[_id].deadline, "Proposal has expired");

        proposal storage currentProposal = Proposals[_id];

        if(_vote) {
            currentProposal.votesUp++;
        } else {
            currentProposal.votesDown++;
        }

        currentProposal.voteStatus[msg.sender] = true;
        // currentProposal.canVote.push(msg.sender);
        emit newVote(currentProposal.votesUp, currentProposal.votesDown, msg.sender, _id, _vote);
    }

    function countProposal(uint256 _id) public {
        require(msg.sender == owner, "Only the owner can count the votes");
        require(Proposals[_id].exists, "Proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Proposal has not expired yet");
        require(!Proposals[_id].countConducted, "Proposal has already been counted");
 
        proposal storage currentProposal = Proposals[_id];

        if (currentProposal.votesUp > currentProposal.votesDown) {
            currentProposal.passed = true;
        } else {
            currentProposal.passed = false;
        }

        currentProposal.countConducted = true;
        emit proposalCount(_id, currentProposal.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only the owner can add a token id");
        vaildTokens.push(_tokenId);
    }
}