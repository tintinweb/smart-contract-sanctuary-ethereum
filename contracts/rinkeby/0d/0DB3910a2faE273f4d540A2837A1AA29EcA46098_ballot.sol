// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ballot{

struct Voter{
    uint weightOfVote;
    bool voted;
    uint8 vote;
}
struct Proposal{
    uint voteCount;
}
uint8 proposalsLen;
address chairperson;
mapping(address=>Voter)voterList;
Proposal[] proposals;
constructor(uint8 _numProposals) public{
    chairperson = msg.sender;
    voterList[chairperson].weightOfVote = 2;
    proposalsLen = _numProposals;
}


function register(address newVoter)public{
    if(msg.sender!=chairperson|| voterList[newVoter].voted)return;
    voterList[newVoter].weightOfVote = 1;
    voterList[newVoter].voted = false;
}

function voting(uint8 toProposal) public{
    Voter storage sender = voterList[msg.sender];
    if(sender.voted||toProposal>=proposals.length)return;
    sender.voted = true;
    sender.vote = toProposal;
    proposals[toProposal].voteCount +=sender.weightOfVote;
}

function winningProposal() public returns(uint8 _winnningProposal){
    uint256 winningVoteCount = 0;
    for(uint8 prop = 0;prop<proposalsLen;prop++){
        if(proposals[prop].voteCount>winningVoteCount){
            winningVoteCount = proposals[prop].voteCount;
            _winnningProposal = prop;
        }
    }
}

}