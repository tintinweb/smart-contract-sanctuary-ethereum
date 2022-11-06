// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


interface ClownERC20 {
        function balanceOf(address) external view returns (uint);
    }

contract Dao {

    address public owner;
    uint256 nextProposal;
    mapping (address => bool) public hasTokenTF;
    ClownERC20 clownContract;

    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        clownContract = ClownERC20(0x89b3B519Fd89a070112921873E08064CDaB48064);
    }

    struct Proposal{
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] authenticatedVoter;
        uint256 amountOfAuthenticatedVoters;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => Proposal) public proposals;

    event proposalCreated(
        uint256 id,
        string description,
        uint256 amountOfAuthenticatedVoters,
        address proposer
    );

    event newVote(
        uint256 votesUp, 
        uint256 votesDown,
        address voter, 
        uint256 proposal,
        bool votedFor
    );
        
    event proposalPassed(
        uint256 id,
        bool passed
    );


    function checkProposalEligibility(address _address) private view returns (
        // is called by create proposal function
        bool
    ){
        require(clownContract.balanceOf(_address) > 0, 'You need a token in order to make Proposals');
        hasTokenTF[_address]==true;
        return true;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (
        bool
    ){
        for (uint256 i = 0; i < proposals[_id].authenticatedVoter.length; i++) {
            if (proposals[_id].authenticatedVoter[i] == _voter) {
            return true;
            }
        }
        return false;
    }


    function createProposal(string memory _description, address[] memory _authenticatedVoter) public {
        require(checkProposalEligibility(msg.sender)==true , "Only NFT holders can put forth Proposals");

        Proposal storage newProposal = proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.authenticatedVoter = _authenticatedVoter;
        newProposal.amountOfAuthenticatedVoters = _authenticatedVoter.length;

        emit proposalCreated(nextProposal, _description, _authenticatedVoter.length, msg.sender);
        nextProposal++;
    }


    function voteOnProposal(uint256 _id, bool _vote) public {
        require(proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        require(!proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= proposals[_id].deadline, "The deadline has passed for this Proposal");

        Proposal storage p = proposals[_id];

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
        require(proposals[_id].exists, "This Proposal does not exist");
        require(block.number > proposals[_id].deadline, "Voting has not concluded");
        require(!proposals[_id].countConducted, "Count already conducted");

        Proposal storage p = proposals[_id];
        
        if(proposals[_id].votesDown < proposals[_id].votesUp){
            p.passed = true;            
        }

        p.countConducted = true;

        emit proposalPassed(_id, p.passed);
    }
    
}