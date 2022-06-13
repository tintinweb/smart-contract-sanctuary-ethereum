// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


// iconic NFTs interface
interface IdaoNft{
    function balanceOf(address _owner) external view returns (uint256);}


contract FocusDao {

    address public owner;
    uint256 nextproposal;
    uint256[] public validTokens;
    IdaoNft nftContract;
    

    struct Proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => Proposal) public proposal;

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


    constructor(){
        owner = msg.sender;
        nextproposal = 1;
        nftContract = IdaoNft(0x705f8B395361218056B20eE5C36853AB84b8bbFF);
        validTokens = [0];
    }


    function checkProposalEligibility(address _proposalist) private view returns (bool) {
        for(uint i = 0; i < validTokens.length; i++){
            if(nftContract.balanceOf(_proposalist) >= 1){
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool) {
        for (uint256 i=0; i < proposal[_id].canVote.length; i++){
            if(proposal[_id].canVote[i] == _voter) {
                return true;
            }
        }

        return false;
    }
    
    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");

        Proposal storage newProposal = proposal[nextproposal];
        newProposal.id = nextproposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextproposal, _description, _canVote.length, msg.sender);
        nextproposal ++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(proposal[_id].exists, "This Proposal does not exist");
        require(block.number <= proposal[_id].deadline, "The deadline has passed for this Proposal");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        require(!proposal[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        

        Proposal storage p = proposal[_id];


        p.voteStatus[msg.sender] = true;
        
        if(_vote) {
            p.votesFor++;
        }else {
            p.votesAgainst++;
        }

        

        emit newVote(p.votesFor, p.votesAgainst, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(proposal[_id].exists, "This Proposal does not exist");
        require(block.number > proposal[_id].deadline, "Voting has not concluded");
        require(!proposal[_id].countConducted, "Count already conducted");

        Proposal storage p = proposal[_id];

        if (p.votesFor > p.votesAgainst) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner can Add tokens");

        validTokens.push(_tokenId);
    }

    

}