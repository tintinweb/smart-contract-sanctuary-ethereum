// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// Author: @cameronmcewan

interface IdaoContract {
        function balanceOf(address, uint256) external view returns (uint256);
    }

contract Dao {

    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;
    
    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        // NFT contract address 
        daoContract = IdaoContract(0x1BBd432443c1572b9B1Ce9996BE34C1d9D243B4C);
        // Token ID of valid tokens to hold
        validTokens = [ 0 ];
    }
    
    // struct defines the structure for a proposal in the DAO and holds the data for each proposal
    struct proposal{
        uint256 id; // store the proposal ID
        bool exists; // boolean declares whether the proposal exists
        string description; // description of the proposal
        uint deadline; // deadline to pass votes
        uint256 votesUp; // count up votes
        uint256 votesDown; //count down votes
        address[] canVote; // use the balanceOf function to create array of addresses that can vote on proposal
        uint256 maxVotes; // length of address array above
        mapping(address => bool) voteStatus; // if address has already voted, modifies voteStatus to True
        bool countConducted; // once deadline has passed, the owner can count votes
        bool passed; // change passed boolean to true if more vote up than down
    }

    // anytime a proposal is proposed, change bool exists to true and fill in the details, store proposals in this mapping
    mapping(uint256 => proposal) public Proposals;


    // create some events that we can emit in our functions then listen to with Moralis 

    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
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


    // now create our functions

    // this function runs a loop checking if the address of the proposalist holds any valid tokens enabling the address to create a proposal, using validTokens array list
    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ){
        for(uint i = 0; i < validTokens.length; i++){
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

    // function checks whether the voter address is in the canVote array, which contains addresses which hld the NFT required for eligibility
    function checkVoteEligibility(uint256 _id, address _voter) private view returns (
        bool
    ){
        for (uint256 i=0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
            return true;
            }
        }
        return false;
    }

    // createProposal is a public function so anyone can call it
    // check that the msg.sender actually holds one of the NFTs we've set in the validTokens array
    function createProposal(string memory _description, address[] memory _canVote) public {
        // require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");

        // functionality of the new proposal
        proposal storage newProposal = Proposals[nextProposal]; // increment nextProposal, initially 1
        newProposal.id = nextProposal; 
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100; // this equals current block number + 100, equals deadline
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length; 
        // this now creates a new proposal in our Proposals mapping that can be publically called by anyone

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        // increment the value of nextProposals to avoid duplicate proposals
        nextProposal++;
    }

    // now create functionality for casting a vote on a proposal
    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        } else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);

    }


    // function for owner to count the votes on the proposal
    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner can count votes");
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

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner can add tokens");

        validTokens.push(_tokenId);
    }

}