/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// File: simpleDao.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao{
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x031225793213Fa7a1648c00444aBaa8AF47f6486);
        validTokens = [0];
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

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

    function checkVoteEligibility(uint256 _id, address _voter) private view returns(bool){
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if(Proposals[_id].canVote[i] == _voter){
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public onlyOwner{

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public{
        require(Proposals[_id].exists, "This proposal does not exist.");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal.");
        require(!Proposals[_id].voteStatus[msg.sender],"You have already voted on this Proposal.");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this proposal.");

        proposal storage p = Proposals[_id];

        if(_vote){
            p.votesUp++;
        }
        else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public onlyOwner {
        require(Proposals[_id].exists, "This Proposal does not exist.");
        require(block.number > Proposals[_id].deadline, "Voting has not yet completed for this proposal.");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];
        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;
        }
        p.countConducted = true;
        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only owner can add tokens");

        validTokens.push(_tokenId);
    }

    function getValidTokens() public view returns(uint256[] memory){
        return validTokens;
    }

    

}