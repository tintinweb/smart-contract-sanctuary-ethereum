// SPDX-License-Identifier: GPLv3
// Developed by: @joevidev
// v1.0.0
pragma solidity ^0.8.9;

interface iDaoCheckBalance {
    function balanceOf(address) external view returns (uint256);
}

contract IzineyDao {
    address public owner;
    uint256 nextProposal;
    uint256 public cantVoteToken;
    iDaoCheckBalance daochkToken;
    address public iDaoInterfaceToken;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        cantVoteToken = 0.01 ether;
        iDaoInterfaceToken = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        daochkToken = iDaoCheckBalance(iDaoInterfaceToken);
    }

    struct proposal{
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        uint256 canVote;
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
        address proposerl,
        uint256 deadline,
        uint256 timeStamp
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

    function checkProposalVoteEligibility(address _voter) public view returns (bool) {
            if(daochkToken.balanceOf(_voter) >= cantVoteToken) {
                return true;
            }
        return false;
    }

    function createProposal(string memory _description, uint256 _voterMax, uint256 _dealine) public {
        require(checkProposalVoteEligibility(msg.sender), "Only WETH holders can put forth Proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + _dealine;
        newProposal.canVote = cantVoteToken;
        newProposal.maxVotes = _voterMax;

        emit proposalCreated(nextProposal, _description, _voterMax, msg.sender, _dealine, block.timestamp);
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkProposalVoteEligibility(msg.sender), "You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.timestamp <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
        
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.timestamp > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];
        
        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;            
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function changeAmountToken(uint256 _amountToken, address _iDaoToken) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");
        cantVoteToken=  _amountToken;
        iDaoInterfaceToken = _iDaoToken;
        daochkToken = iDaoCheckBalance(iDaoInterfaceToken);
    }


}