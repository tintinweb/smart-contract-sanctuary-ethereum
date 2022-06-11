// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ProposalRegistry {
    enum VotingType {
        Single,
        Weighted
    }

    // proposal data
    struct Proposal {
        uint256 deadline;
        uint256 maxIndex;
        VotingType _type;
    }

    address public governance;

    // bytes32 of snapshot IPFS hash id for a given proposal
    mapping(bytes32 => Proposal) public proposalInfo;

    /* ========== EVENT ========== */
    event Initiated(bytes32 _proposal);

    constructor(address _governance) {
        governance = _governance;
    }

    /***************************************
                    MODIFIER
    ****************************************/
    modifier onlyGovernance() {
        require(msg.sender == governance, "not-governance!");
        _;
    }

    /***************************************
               ADMIN - GOVERNANCE
    ****************************************/

    function initiateProposal(
        bytes32 _proposal,
        uint256 _deadline,
        uint256 _maxIndex,
        uint8 _type
    ) public onlyGovernance {
        require(proposalInfo[_proposal].deadline == 0, "exists");
        require(_deadline > block.timestamp, "invalid deadline");
        require(_type <= uint8(VotingType.Weighted), "out range");

        proposalInfo[_proposal].deadline = _deadline;
        proposalInfo[_proposal].maxIndex = _maxIndex;

        emit Initiated(_proposal);
    }
}