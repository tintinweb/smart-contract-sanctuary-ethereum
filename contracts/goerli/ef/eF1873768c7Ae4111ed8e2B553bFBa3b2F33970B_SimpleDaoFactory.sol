// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Dao {
    struct Proposal {
        uint id;
        string title;
        string description;
        uint forVotes;
        uint againstVotes;
        bool executed;
        mapping(address => bool) voted;
    }

    uint public proposalCount;
    mapping(uint => Proposal) public proposals;
    mapping(address => bool) public members;
    address public owner;

    event ProposalAdded(uint proposalId, string description);
    event Voted(uint proposalId, bool inSupport, address voter);
    event ProposalExecuted(uint proposalId);

    constructor(address _owner) {
        owner = _owner;
        members[owner] = true;
    }

    function addProposal(string memory _description,string memory _title) public {
        require(members[msg.sender], "Only members can add a proposal.");
        proposalCount++;
        proposals[proposalCount].description =  _description;
        proposals[proposalCount].title =  _title;
        emit ProposalAdded(proposalCount, _description);
    }

    function vote(uint _proposalId, bool _inSupport) public {
        Proposal storage proposal = proposals[_proposalId];
        require(members[msg.sender], "Only members can vote.");
        require(!proposal.voted[msg.sender], "Member has already voted.");
        if (_inSupport) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }
        proposal.voted[msg.sender] = true;
        emit Voted(_proposalId, _inSupport, msg.sender);
    }

    function executeProposal(uint _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal has already been executed.");
        require(proposalCount > 0, "No proposals found.");
        require(msg.sender == owner, "Only owner can execute proposals.");
        if (proposal.forVotes > proposal.againstVotes) {
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        }
    }

    function addMember(address _newMember) public {
        require(msg.sender == owner, "Only owner can add a new member.");
        members[_newMember] = true;
    }

    function removeMember(address _member) public {
        require(msg.sender == owner, "Only owner can remove a member.");
        require(_member != owner, "Owner cannot remove themselves.");
        delete members[_member];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Dao.sol";

contract SimpleDaoFactory {
    address[] public deployedDaos;
    event DaoAdd(address);

    function createDao() public  {
        Dao newDao = new Dao(msg.sender);
        deployedDaos.push(address(newDao));
        emit DaoAdd(address(newDao));
        // return address(newDao);
    }

    function getDeployedDaos() public view returns (address[] memory) {
        return deployedDaos;
    }
}