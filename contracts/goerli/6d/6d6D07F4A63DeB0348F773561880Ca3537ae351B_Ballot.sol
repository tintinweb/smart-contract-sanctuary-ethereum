// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

contract Ballot{

    //who deploy the contract
    //storage
    address public chairperson;

    // proposal A [0]
    // proposal B [1]
    // proposal C [2]

    //struct voter
    struct Voter{
        address delegate; //person delegated to vote
        uint vote; //index of the voted proposal
        uint weight; //weight of the voter
        bool voted; //whether voter has voted or not


    }
    //struct proposal
    struct Proposal {
        bytes32 name;
        uint voteCount; //number of votes
    }

    //given address, return voter
    mapping(address => Voter) public voters;

    //array of proposal
    Proposal[] public proposals;

    constructor(bytes32[] memory proposalName) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // for proposals
        for (uint i=0; i < proposalName.length; i++) {
            proposals.push(Proposal({name : proposalName[i], voteCount : 0}));
        }
    }

    function getProposalCount() public view returns(uint count){
        return proposals.length;
    }

    function giveRightToVote(address _voter) external {

        require(msg.sender == chairperson, "Only chairperson can assign rights to vote");
        require(!voters[_voter].voted, "The voter has already voted.");
        require(voters[_voter].weight == 0, "Voter already has the right to vote.");

        voters[_voter].weight = 1;
    }

    function delegate(address _to) external {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted. Cannot delegate");
        require(msg.sender != _to, "You cannot delegate to yourself.");

        // prevent loop in delegation
        // a -> b -> a
        // as is msg.sender
        // b is voters[_to]
        while(voters[_to].delegate != address (0)){
            _to = voters[_to].delegate;

            require(_to != msg.sender, "Found loop in delegation");
        }

        Voter storage delegate_ = voters[_to];

        //delegate to anybody as long the delegate has rights to vote
        require(delegate_.weight > 0);
        sender.voted = true;
        sender.delegate = _to;
        // actual delegation. two scenarios:
        //1. if the delegate have not voted yet
        if(!delegate_.voted){
            delegate_.weight += sender.weight;
        }
        //2. if the delegate has already voted
        else{
            proposals[delegate_.vote].voteCount += sender.weight;

        }


    }

    //person A voted for proposal B
    function vote(uint _proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight > 0, "No rights to vote");
        require(!sender.voted, "Already voted");

        proposals[_proposal].voteCount += sender.weight;

        sender.vote = _proposal;
        sender.voted = true;
    }

    // return the index of the winning proposal
    function getWinningProposal() public view returns(uint256 winningProposal_){
        uint256 winningVoteCount = 0;

        for(uint i=0; i < proposals.length; i++){
            if(proposals[i].voteCount > winningVoteCount){
                winningProposal_ = i;
                winningVoteCount = proposals[i].voteCount;
            }
        }


    }

    function getWinnerName() external view returns(bytes32 winnerName_){

        winnerName_ = proposals[getWinningProposal()].name;


    }
}