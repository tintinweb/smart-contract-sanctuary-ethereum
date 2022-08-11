// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Ballot1{

    struct Voter{
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    struct Proposal{
        string name;
        uint voteCount;
    }

    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    address owner;

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    constructor(Proposal[] memory _persons){
        owner = msg.sender;
        for(uint i=0;i<_persons.length;i++){
            proposals.push(Proposal({
                    name : _persons[i].name,
                    voteCount : _persons[i].voteCount
                }));
        }
        voters[owner].weight = 1;
    }

    function giveRightToVote(address voter) public onlyOwner{
        Voter storage temp = voters[voter];
        require(!temp.voted, "Already voted");
        require(temp.weight == 0, "Not right to vote");
        temp.weight = 1;
    }
    
    function getProposals() view public returns(Proposal[] memory){
        return proposals;
    }

    function delegate(address to) public{
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        require(sender.weight != 0, "Has no Right to vote");
        require(to != msg.sender, "Not allowed to deligate yourself");

        while(voters[to].delegate != address(0)){
            to = voters[to].delegate;
            require(msg.sender != to, "Found loop in delegation");
        }
        
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if(delegate_.voted == true){
            proposals[delegate_.vote].voteCount += sender.weight;
        } else{
            delegate_.weight += sender.weight;
        }    
    }

    function vote(uint proposalIndex) public{
        Voter storage voter = voters[msg.sender];
        require(voter.weight != 0, "Has no Right to vote");
        require(!voter.voted,"Already Voted.");
        voter.voted = true;
        voter.vote = proposalIndex;

        proposals[proposalIndex].voteCount += voter.weight;
    }

    function wininngProposal() public view returns(uint winningIndex, string memory winnerName){
        uint maxVoteCount = 0;
        for(uint i=0;i<proposals.length;i++)
            if(maxVoteCount < proposals[i].voteCount){
                maxVoteCount = proposals[i].voteCount;
                winningIndex = i;
            }
        if(maxVoteCount== 0)
            winnerName = "Nobody";
        else 
            winnerName = proposals[winningIndex].name;
    }

}