/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

contract Ballot{
    address public chairperson;

    struct Voter{
        uint vote; // index of voted proposal
        bool voted; // has voted or not
        address delegate; // delegated address
        uint weight; // total no. of delegations or right to vote or not
    }

    struct Proposal{
        bytes32 name; // name of proposal
        uint voteCount; // total no. of votes
    }

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    constructor(bytes32[] memory ProposalNames){
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        for(uint i = 0; i < ProposalNames.length; i++){
            proposals.push(Proposal({name : ProposalNames[i], voteCount : 0}));
        }
    }

    function giveRightToVote(address voter) external{
        require(msg.sender == chairperson, "Right to vote can be given by the Chairperson only!");
        require(!voters[voter].voted, "This person has already voted!");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function delegate(address to) external{
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Sorry! you have no voting rights...");
        require(!sender.voted, "You have already voted!");
        require(to != msg.sender, "Self-delegation is not allowed!");
        while(voters[to].delegate != address(0)){
            to = voters[to].delegate;
            require(to != msg.sender);
        }
        Voter storage delegate_ = voters[to];
        require(delegate_.weight >= 1, "The delegate address should have voting rights!");
        sender.delegate = to;
        sender.voted = true;
        if(delegate_.voted){
            proposals[delegate_.vote].voteCount += sender.weight;
        }
        else{
            delegate_.weight = sender.weight;
        }
    }

    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight >= 1, "Sorry! You should have voting rights to vote");
        require(!sender.voted, "You have already voted!");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view returns(uint winningProposal_){
        uint winningVoteCount = 0;
        for(uint i = 0; i < proposals.length; i++){
            if(proposals[i].voteCount > winningVoteCount){
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }

    function winnerName() external view returns(bytes32 winnerName_){
        winnerName_ = proposals[winningProposal()].name;
    }

}