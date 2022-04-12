/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/// @title BasicDAO
/// @author alexjrg
contract BasicDAO {

    address public contractOwner;
    mapping(address => bool) private members;
    mapping(uint256 => Proposal) public proposals;

    enum VoteType{
        Against,
        Abstain,
        For
    }

    struct Proposal {
        string name;
        string description;
        mapping(address => bool) hasVoted;
        uint256 againstVotes;
        uint256 abstainVotes;
        uint256 forVotes; 
    }

    event ProposalCreated(
        uint256 proposalId,
        address creator,
        string name,
        string description
    );

    event voted(
       uint256 propoosalId,
       address voter,
       VoteType vote
    );

    constructor(){
        // Set the transaction sender as the owner of the contract.
        contractOwner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == contractOwner, "Not the owner");
        _;
    }

    modifier onlyMember(){
        require(members[msg.sender], "Not a member");
        _;
    }

    function addMember(address _newMember) public onlyOwner {
        require(_newMember != address(0), "Invalid address");
        require(!members[_newMember], "Already a member");
        
        members[_newMember] = true;
    }

    /// @notice function used to create a proposal
    function createProposal(string memory _name, string memory _description) public onlyMember returns (uint256){
        uint256 proposalId = uint256(keccak256(abi.encodePacked(_name, _description)));

        Proposal storage proposal = proposals[proposalId];
        proposal.name = _name;
        proposal.description = _description;

        emit ProposalCreated(proposalId, msg.sender, _name, _description);

        return proposalId;
    }

    /// @notice function used to vote on a proposal
    function vote(uint256 _proposalId, uint8 _vote) public onlyMember {
        Proposal storage proposal = proposals[_proposalId];

        require(!proposal.hasVoted[msg.sender], "Already voted");

        proposal.hasVoted[msg.sender] = true;

        if(_vote == uint8(VoteType.Against)){
            proposal.againstVotes += 1;
        }else if(_vote == uint8(VoteType.Abstain)){
            proposal.abstainVotes += 1;
        }else if(_vote == uint8(VoteType.For)){
            proposal.forVotes += 1;
        }else{
            revert("Invalid value for enum VoteType");
        }
        
        emit voted(_proposalId, msg.sender, VoteType(_vote));
    }

    /// @notice function used to get votes on a proposal
    function getVotes(uint256 _idProposal) public view returns (uint256 againstVotes, uint256 abstainVotes, uint256 forVotes){
        Proposal storage proposal = proposals[_idProposal];
        return (proposal.againstVotes, proposal.abstainVotes, proposal.forVotes);
    }



}