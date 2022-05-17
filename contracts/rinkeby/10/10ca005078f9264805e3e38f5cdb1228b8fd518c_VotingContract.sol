/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract VotingContract {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    struct Proposal {
        string name;
        uint voteCount;
    }

    address public chairPerson;
    mapping(address=>Voter) public voters;
    Proposal[] public proposals;

    constructor (){
        string[3] memory proposalNames=["Oranges", "Apples", "Mangos"];
        chairPerson=msg.sender;
        voters[chairPerson].weight=1;
        for (uint i=0; i<proposalNames.length;i++) {
            proposals.push(Proposal({name:proposalNames[i], voteCount:0}));
        }
    } 

    function giveRightToVote(address voter) public {
        require(msg.sender==chairPerson, "only chairperson can give right to vote");
        require(!voters[voter].voted, "The voter alreday voted");
        require(voters[voter].weight==0, "The voter already has the right to vote");
        voters[voter].weight=1;
    }

    function deligate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted,"You already voted");
        require(to!=msg.sender,"Self delegation is not allowed");
        require(voters[msg.sender].weight!=0,"You dont have permission to give a delegate");
        sender.voted=true;
        sender.delegate=to;
        //if the one that sender wants to delegete has already delegete someone else to delegete
        //we wont to change to who we are delegeting
        while(voters[to].delegate!=address(0)){
            to=voters[to].delegate;
            require(to!=msg.sender,"Found the loop in delegation");
        }
        Voter storage delegate_=voters[to];
        if(delegate_.voted) {
            proposals[delegate_.vote].voteCount+=sender.weight;
        } else {
            delegate_.weight+=sender.weight;
        }
    }

    function vote(uint proposal) public {
        Voter storage sender= voters[msg.sender];
        require(sender.weight!=0,"You don't have right to vote");
        require(!sender.voted,"Already voted");
        sender.voted=true;
        sender.vote=proposal;
        proposals[proposal].voteCount+=sender.weight;
    }

    function wininingProposal() public view returns (uint _winingProposal) {
        uint wininingVoteCount=0;
        for(uint p=0; p<proposals.length; p++){
            if(proposals[p].voteCount>wininingVoteCount){
                wininingVoteCount=proposals[p].voteCount;
                _winingProposal=p;
            }
        }
    }

    function winnerName() public view returns (string memory _winnerName) {
        _winnerName= proposals[wininingProposal()].name;
    }



}