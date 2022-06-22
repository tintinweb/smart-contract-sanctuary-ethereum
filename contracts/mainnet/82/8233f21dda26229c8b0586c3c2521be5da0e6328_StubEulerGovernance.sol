// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StubEulerGovernance {

    event ProposalExecuted(uint proposalCounter, string description, bytes proposalData);

    address public immutable governor;
    uint public proposalCounter;

    modifier onlyGovernor() {
        require(msg.sender == governor, "GovernanceStub: only governor can call");
        _;
    }

    constructor(address _governor) {
        governor = _governor;
    }

    function executeProposal(
        string memory description, 
        bytes memory proposalData
    ) 
    external 
    onlyGovernor 
    {
        proposalCounter = proposalCounter + 1;
        emit ProposalExecuted(proposalCounter, description, proposalData);
    }
}