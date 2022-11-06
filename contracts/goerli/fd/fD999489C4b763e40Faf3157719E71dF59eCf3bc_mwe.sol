// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract mwe {
    struct Proposal {
        uint256 nftId;
        uint256 deadline;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;

    event NewProposal(uint256 numProposal);

    function createProposal(uint256 _nftTokenId) external returns (uint256) {
        Proposal storage proposal = proposals[numProposals];
        proposal.nftId = _nftTokenId;
        proposal.deadline = block.timestamp;
        emit NewProposal(numProposals);
        numProposals++;
        return numProposals - 1;
    }
}