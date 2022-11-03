// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IdaoContract {
        function balanceOf(address) external view returns (uint256);
    }

contract Dao {

    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x6d818827046A47db24E08d0E7799E21E384901c4);
    }

    struct proposal{
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

    event proposalCreated(
        uint256 id,
        string description,
        address proposer,
        uint256 deadline
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


    function checkProposalEligibility(address _proposer) private view returns (bool) { 
        uint256 balance = daoContract.balanceOf(_proposer);
        return (balance > 0);
    }

    function checkVoteEligibility(address _voter) private view returns (bool) { 
        uint256 balance = daoContract.balanceOf(_voter);
        return (balance > 0);
    }


    function createProposal(string memory _description) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        // newProposal.maxVotes = validTokens.length;

        emit proposalCreated(nextProposal, _description, msg.sender, newProposal.deadline);
        nextProposal++;
    }

    function getProposal(uint8 id) external view returns(bool, string memory, uint256, uint256, uint256, bool, bool) {

        return (Proposals[id].exists, 
                Proposals[id].description, 
                Proposals[id].deadline, 
                Proposals[id].votesUp, 
                Proposals[id].votesDown, 
                Proposals[id].countConducted, 
                Proposals[id].passed) ;
    }


    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(msg.sender), "You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

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
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];
        
        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;            
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }


    // function addTokenId(uint256 _tokenId) public {
    //     require(msg.sender == owner, "Only Owner Can Add Tokens");

    //     validTokens.push(_tokenId);
    // }
    
}