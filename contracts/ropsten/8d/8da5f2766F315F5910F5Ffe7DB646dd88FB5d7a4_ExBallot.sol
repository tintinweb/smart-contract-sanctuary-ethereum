// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract ExBallot {

    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    struct Proposal {
        bytes32 name;
        uint voteCount;
    }

    address public chairperson;

    mapping (address => Voter) public voters;

    Proposal[] public proposals;

    constructor( bytes32[] memory proposalNames ) payable {

        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for( uint i =0; i< proposalNames.length; i++){
            proposals.push( Proposal({
                name: proposalNames[i],
                voteCount: 0
            }) );
        } 
    }

    function giveRightToVote( address voter) external {
        require( msg.sender == chairperson, "only chairperson can give right to vote.");
        require( !voters[voter].voted, "the voter alreaady voted" );
        require( voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function delegate( address to) external {
        Voter storage me = voters[msg.sender];
        require(!me.voted, "you voted already");
        require(msg.sender != to, "you can't delegate to yourself");

        while( voters[to].delegate != address(0)){
            to = voters[to].delegate;
            require(to != msg.sender, "found a loop in delegation");
        }

        me.delegate = to;
        me.voted = true;
        Voter storage delegated = voters[to];
        if( delegated.voted){
            proposals[ delegated.vote ].voteCount += me.weight;
        }else{
            delegated.weight += me.weight;
        }
    }

    function vote( uint proposalNo) external {
        Voter storage me = voters[msg.sender];
        require(!me.voted, "you've already voted");
        require(me.weight !=0, "you don't have right to vote");
        me.voted = true;
        me.vote = proposalNo;

        proposals[proposalNo].voteCount += me.weight;
    }

    function winningProposal() public view returns ( uint winningProposal_){
        uint winningVoteCount = 0;

        for( uint p=0; p<proposals.length; p++){
            if( proposals[p].voteCount > winningVoteCount){
                winningProposal_ = p;
                winningVoteCount = proposals[p].voteCount;
            }
        }
    }

    function winnerName() external view returns( bytes32 winnerName_ ){
        uint winningno = winningProposal();
        Proposal storage winningProposal_ = proposals[ winningno ];
        winnerName_ = winningProposal_.name;
    }

}