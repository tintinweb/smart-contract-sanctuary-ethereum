/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library NyxDAOProposals {

    enum ProposalType{Investment, Revenue, Governance, Allocation, Free}
    enum InvestmentType{Crypto, NFT}
    enum GovernanceAddressAction{ADD, REMOVE}

    // Proposal Structs
    /////////////////////////////////////////

    struct ProposalConf
    {
        uint256 id;
        ProposalType proposalType;
        uint256 livePeriod;
        uint256 votesFor;
        uint256 votesAgainst;
        bool votingPassed;
        bool settled;
        address proposer;
        address settledBy;
        bool approved;
    }

    struct Proposal
    {
        ProposalType proposalType;
        InvestmentProposal investmentPoposal;
        RevenueProposal revenuePoposal;
        AllocationProposal allocationPoposal;
        GovernanceProposal governancePoposal;
        FreeProposal freePoposal;
    }

    struct InvestmentProposal
    {
        uint256 id;
        InvestmentType assetType;
        string tokenName;
        address payable tokenAddress;
        uint256 percentage;
        ProposalConf conf;
    }

    struct RevenueProposal
    {
        uint256 id;
        uint256 yieldPercentage;
        uint256 reinvestedPercentage;
        uint256 mgmtFeesPercentage;
        uint256 perfFeesPercentage;
        ProposalConf conf;
    }

    struct GovernanceProposal
    {
        uint256 id;
        address ambassadorAddress;
        GovernanceAddressAction action;
        ProposalConf conf;
    }

    struct AllocationProposal
    {
        uint256 id;
        uint256 NFTPercentage;
        uint256 CryptoPercentage;
        uint256 VenturePercentage;
        uint256 TreasurePercentage;
        ProposalConf conf;
    }

    struct FreeProposal
    {
        uint256 id;
        string title;
        string description;
        ProposalConf conf;
    }

    // Events
    ///////////////////

    event NewProposal(address indexed proposer, ProposalType proposalType, ProposalConf proposalConf);

    // Functions
    ////////////////////

    function createProposalConf(uint256 livePeriodInput, uint256 proposalId, ProposalType proposalType)
        public view
        returns (ProposalConf memory)
    {
        uint256 livePeriod = livePeriodInput;
        uint256 votesFor = 0;
        uint256 votesAgainst = 0;
        bool votingPassed = false;
        bool settled = false;
        address proposer = msg.sender;
        address settledBy;
        bool approved;
        ProposalConf memory proposalConf = ProposalConf(proposalId, proposalType, livePeriod, votesFor,
                                                        votesAgainst, votingPassed,
                                                        settled, proposer, settledBy, approved);
        return proposalConf;
    }

    function createInvestmentProposal(uint256 proposalId, InvestmentType assetType, string calldata tokenName,
                                      address tokenAddress, uint256 percentage, uint256 livePeriod)
        // external
        public
        returns (InvestmentProposal memory)
    {
        InvestmentProposal memory proposal;

        proposal.id = proposalId;
        proposal.assetType = assetType;
        proposal.tokenName = tokenName;
        proposal.tokenAddress = payable(tokenAddress);
        proposal.percentage = percentage;

        ProposalConf memory proposalConf = createProposalConf(livePeriod, proposalId, ProposalType.Investment);

        proposal.conf = proposalConf;

        emit NewProposal(msg.sender, ProposalType.Investment, proposalConf);

        return proposal;
    }

    function createRevenueProposal(uint256 proposalId, uint256 yieldPercentage, uint256 reinvestedPercentage, uint256 mgmtFeesPercentage, uint256 perfFeesPercentage, uint256 livePeriod)
        // external
        public
        returns (RevenueProposal memory)
    {
        RevenueProposal memory proposal;

        proposal.id = proposalId;
        proposal.yieldPercentage = yieldPercentage;
        proposal.reinvestedPercentage = reinvestedPercentage;
        proposal.mgmtFeesPercentage = mgmtFeesPercentage;
        proposal.perfFeesPercentage = perfFeesPercentage;

        ProposalConf memory proposalConf = createProposalConf(livePeriod, proposalId, ProposalType.Revenue);

        proposal.conf = proposalConf;

        emit NewProposal(msg.sender, ProposalType.Revenue, proposalConf);

        return proposal;
    }

    function createAllocationProposal(uint256 proposalId, uint256 NFTPercentage, uint256 cryptoPercentage, uint256 venturePercentage, uint256 treasurePercentage, uint256 livePeriod)
        // external
        public
        returns (AllocationProposal memory)
    {
        AllocationProposal memory proposal;

        proposal.NFTPercentage = NFTPercentage;
        proposal.CryptoPercentage = cryptoPercentage;
        proposal.VenturePercentage = venturePercentage;
        proposal.TreasurePercentage = treasurePercentage;

        ProposalConf memory proposalConf = createProposalConf(livePeriod, proposalId, ProposalType.Allocation);

        proposal.conf = proposalConf;

        emit NewProposal(msg.sender, ProposalType.Allocation, proposalConf);

        return proposal;
    }

    function createGovernanceProposal(uint256 proposalId, address ambassadorAddress, GovernanceAddressAction action, uint256 livePeriod)
        // external
        public
        returns (GovernanceProposal memory)
    { 
        GovernanceProposal memory proposal;

        proposal.ambassadorAddress = ambassadorAddress;
        proposal.action = action;

        ProposalConf memory proposalConf = createProposalConf(livePeriod, proposalId, ProposalType.Governance);

        proposal.conf = proposalConf;

        emit NewProposal(msg.sender, ProposalType.Governance, proposalConf);

        return proposal;
    }

    function createFreeProposal(uint256 proposalId, string memory title, string memory description, uint256 livePeriod)
        // external
        public
        returns (FreeProposal memory)
    {
        FreeProposal memory proposal;

        proposal.title = title;
        proposal.description = description;

        ProposalConf memory proposalConf = createProposalConf(livePeriod, proposalId, ProposalType.Free);

        proposal.conf = proposalConf;

        emit NewProposal(msg.sender, ProposalType.Free, proposalConf);

        return proposal;
    }
}