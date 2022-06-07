//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDaoContract {
    function balanceOf(address, uint) external view returns (uint);
}

contract Dao {

    address public owner;
    uint nextProposal;
    uint[] public validTokens;
    IDaoContract daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IDaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [90589094416039184604703704186156568307524264362799260266890565735654715555850]; //ID of my NFT
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the owner");
        _;
    }

    struct proposal {
        uint256 id;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        uint256 maxVotes;
        address[] canVote;
        string description;        
        mapping(address => bool) voteStatus;
        bool exists;
        bool countCounducted;
        bool passed;
    }

    mapping(uint => proposal) public Proposals;

    event proposalCreated (
        address proposer,
        string description,
        uint256 id,
        uint256 maxVotes
    );

    event newVote (
        uint256 votesUp,
        uint256 votesDown,
        uint256 proposal,
        address voter,
        bool votedFor
    );

    event proposalCount (
        uint256 id,
        bool passed
    );

    function checkProposalEligibility(address _proposalAddr) private view returns(bool) {
        for (uint i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposalAddr, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint _id, address _voter) private view returns(bool) {
        for (uint i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "You must own a NFT to create a proposal");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 3000; // More or less 12 hours
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(msg.sender, _description, nextProposal, _canVote.length);
        nextProposal++;
    }

    function voteOnProposal(uint _id, bool _vote) public {
        require(Proposals[_id].exists, "This proposal doesn't exist");
        require(checkVoteEligibility(_id, msg.sender), "You can't vote on this proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You've already voted");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, _id, msg.sender, _vote);
    }

    function countVotes(uint _id) public onlyOwner {
        require(Proposals[_id].exists, "This proposal doesn't exist");
        require(block.number > Proposals[_id].deadline, "You must wait for the deadline");
        require(!Proposals[_id].countCounducted, "You've already counted the votes");

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            Proposals[_id].passed = true; 
        }

        p.countCounducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint _tokenId) public onlyOwner {
        validTokens.push(_tokenId);
    }

}