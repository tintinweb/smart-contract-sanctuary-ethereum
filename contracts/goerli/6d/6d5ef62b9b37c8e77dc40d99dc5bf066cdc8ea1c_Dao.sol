/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract Dao {
    //Global Variables

    //owner of the smart contract
    address public owner;
    //next proposal's ID to keep track of
    uint256 nextProposal;



    constructor() {
        //constructor with variables to initialise the smart contract.
        
        //contract deployer
        owner = msg.sender;
        //set nextProposal to 1, every new proposal will increment this
        nextProposal = 1;
        //this is the contract address on OpenSea - referencing the interface to the contract we will query
    }

    struct proposal {
        //data structure of the proposal object

        //next proposal ID
        uint256 id;
        //If the proposal actually exists
        bool exists;
        //description of the proposal
        string description;
        //deadline to cast votes
        uint deadLine;
        //total votes up
        uint256 votesUp;
        //total votes down
        uint256 votesDown;
        //array of wallet addresses that can actually vote
        address[] canVote;
        //maximum number of votes = length of address array
        uint256 maxVotes;
        //voting status of any possible address
        mapping(address => bool) voteStatus;
        //when the deadline has passed count the number of votes
        bool countConducted;
        //passed boolean to set to true when count conducted is completed
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;
    //maps a proposal ID to Proposal Struct

    event proposalCreated(uint256 id, string description, uint256 maxVotes, address proposer);
    //event for log for when a new proposal is created - emits the Proposal ID, Proposal Description, Num of Max Votes and Address of the proposer

    event newVote(uint256 votesUp, uint256 votesDown, address voter, uint256 proposal, bool votedFor);
    //event for log for a new vote - including votes up, down, the most recent voters address, the proposal and boolean for if it was voted for or against

    event proposalCount(uint256 id, bool passed);
    //event for when or after deadline of vote owner calculates the number of votes - vote ID and whether the vote was passed or not

    function checkVoteEligibility(uint256 _id, address _voter) private view returns(bool) {
        //checking whether a voter can actually vote on a specific proposal
        for(uint i = 0; i < Proposals[_id].canVote.length; i++) {
            //loop around specific proposals in proposal mapping and loop through all proposals.
            //if the voter is part of the canVote array then they can take part in the voting of a proposal
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
        //create proposal function which allows the addresses a part of the canVote
        //require(checkProposalEligibility(msg.sender), "Only Token Holders can put forth Proposals");
        //this requires that the address making a proposal is eligible

        proposal storage newProposal = Proposals[nextProposal];
        //creates a new proposal object called newProposal and stores it within the Proposals storage array
        newProposal.id = nextProposal;
        //sets the newProposal id value to uint nextProposal
        newProposal.exists = true;
        //sets the exists variable within the newProposal struct as true
        newProposal.description = _description;
        //includes the descirption variable within newProposal as the input description of this function
        newProposal.deadLine = block.number + 100;
        //deadline for voting set to blocks
        newProposal.canVote = _canVote;
        //checks for address within the canvote array
        newProposal.maxVotes = _canVote.length;
        //sets the maximum number of votes allowable to the number of addresses withint he canvote array

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        //emits proposalCreated log event
        nextProposal++;
        //increment for new proposal ID
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        //require that proposal exists
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        //check vote eligibility to ensure the msg sender is in the canVote array
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        //make sure that the voter cannot vote multiple times
        require(block.number <= Proposals[_id].deadLine);
        //ensure that the block number isnt higher than the deadline that has been set

        proposal storage p = Proposals[_id];
        //creates a new object, p of proposal struct which is equal to the proposal ID

        if(_vote) {
            //if the user votes 'yes' on the proposal, increment the votesUp variable
            p.votesUp++;
        }else{
            p.votesDown++;
            //if the user votes 'no' on the proposal, increment the votesDown variable
        }

        p.voteStatus[msg.sender] = true;
        //set the voteStatus of the address for this particular proposal to true

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
        //emits the newVote log event
    }

    function countVotes(uint256 _id) public {
        //function for the onwer to count the votes
        require(msg.sender == owner, "Only the owner can count votes");
        //require that only the owner can count votes
        require(Proposals[_id].exists, "This proposal does not exist");
        //require that the proposal of proposal ID actually exists
        require(block.number > Proposals[_id].deadLine, "Voting has not concluded");
        //require that the alloted time has actually elapsed
        require(!Proposals[_id].countConducted, "Count already conducted");
        //require that the count has already been conducted

        proposal storage p = Proposals[_id];
        //creates a new object, p of proposal struct which is equal to the proposal ID

        if(Proposals[_id].votesDown < Proposals[_id].votesUp) {
            //conditional to evaluate whether the vote has passed - i.e. more votes up than votes down
            p.passed = true;
            //if more votesup than votesdown, then the proposal has passed
        }

        p.countConducted = true;
        //count has been conducted

        emit proposalCount(_id, p.passed);
        //emit a proposalCount log event
    }

}