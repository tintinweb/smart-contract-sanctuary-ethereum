/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Ballot{
    
    struct Voter {
        uint weight;        //whether or not this person has the right to vote/can delegate vote
        bool voted;         //whether or not this person has voted
        address delegate;   //person delegated vote to
        uint vote;          //index of voted proposal
    }

    struct Proposal {
        bytes32 name;       //proposal name. use corresponding JS code to translate 
        uint voteCount;     //number of accumulated votes
    }

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    constructor(bytes32[] memory proposalNames){
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for(uint i = 0; i < proposalNames.length; i++){
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    //As admin, we want to pass an address and let them vote
    function giveRightToVote(address voter) public{
        require(
            msg.sender == chairperson,
            "Only the chairperson (contract creator) can give the right to vote."
        );
        require(
            !voters[voter].voted,   //require voter bool value to be false
            "The voter has already voted."
        );
        require(voters[voter].weight == 0); //make sure voter hasn't already been given right
        voters[voter].weight = 1;
    }

    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is not allowed.");

        //If this person has already delegated vote, forward the vote to that person
        //to whom he/she has delegated
        while(voters[to].delegate != address(0)){
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if(delegate_.voted){
            //If the delegate already voted, directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else{
            //If the delegate hasn't yet voted, add to the weight
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote.");
        require(!sender.voted, "Alread voted.");
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view returns (uint winningProposal_){
        uint winningVoteCount = 0;
        for(uint p = 0; p < proposals.length; p++){
            if(proposals[p].voteCount > winningVoteCount){
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() public view returns (bytes32 winnerName_){
        winnerName_ = proposals[winningProposal()].name;
    }
}