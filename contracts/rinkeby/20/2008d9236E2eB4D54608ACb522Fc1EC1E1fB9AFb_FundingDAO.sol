// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IFundingNFT.sol";

error NotHaveRightToVote();
error ProposalIsNotActive();
error ProposalStillActive();
error onlyLeaderCall();
error onlyFunderCall();
error NotCommunityMember();
error AlreadyVoted();

contract FundingDAO {
    struct Community {
        uint256 id;
        string name;
        string description;
        address leader;
        address[] members;
    }

    struct Proposal {
        uint256 id;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline; // Deadline of the proposal.
        uint256 requiredBudget; // Budget needed to implement.
        string description;
        Community community; // Id to Community.
        Goal[] goals;
        address[] voters;
        mapping(address => uint256) fundsBy;
        uint256 funds;
        bool executed;
    }

    enum Vote {
        YES,
        NO
    }

    enum Goal {
        NO_PROVERTY,
        ZERO_HUNGER,
        GOOD_HEALTH_AND_WELL_BEING,
        QUALITY_EDUCATION,
        GENDER_QUALITY,
        GREEN_WATER,
        AFFORDABLE_AND_CLEAN_ENERGY,
        DEVENT_WORK_AND_ECONOMIC_GROWTH,
        INDUSTRY_INNOVATION_AND_INFTRASTRUCTURE,
        REDUCES_INEQUALITIES,
        SUSTAINABLE_CITIES_AND_COMMUNITIES,
        RESPONSIBLE_CONSUPTION_AND_PRODUCTION,
        CLIMATE_ACTION,
        LIFE_BELOW_WATER,
        LIFE_ON_LAND,
        PEACT_JUSTICE_AND_STRONG_INSTITUTIONS,
        PARTNERSHIPS_FOR_THE_GOALS
    }

    uint256 proposalCounts;
    mapping(uint256 => Proposal) public proposals;

    uint256 communityCounts;
    mapping(uint256 => Community) public communities;
    mapping(address => Community) public communityMembers;
    /**
     *  Community Id To Proposal array.
     *  Let users know, which proposals who created.
     */
    mapping(uint256 => Proposal[]) public communityIdToProposals;
    IFundingNFT fundingNFT;

    event memberLeftTheCommunity(address member);
    event communityCreated(uint256 id);
    event proposalCreated(uint256 id);

    modifier nftHolderOnly() {
        if (fundingNFT.balanceOf(msg.sender) > 0) revert NotHaveRightToVote();
        _;
    }

    modifier activeProposals(uint256 proposalId) {
        if (block.timestamp > (proposals[proposalId].deadline))
            revert ProposalIsNotActive();
        _;
    }

    modifier onlyFunder() {
        if (!fundingNFT.isFunder(msg.sender)) revert onlyFunderCall();
        _;
    }

    modifier onlyLeader() {
        if (!fundingNFT.isLeader(msg.sender)) revert onlyLeaderCall();
        _;
    }

    modifier onlyMembers(uint256 communityId) {
        if (communityMembers[msg.sender].id != communityId)
            revert NotCommunityMember();
        _;
    }

    modifier activeProposal(uint256 proposalId) {
        if (block.timestamp < proposals[proposalId].deadline)
            revert ProposalIsNotActive();
        _;
    }

    modifier finishedProposal(uint256 proposalId) {
        if (block.timestamp > proposals[proposalId].deadline)
            revert ProposalStillActive();
        _;
    }

    constructor(address _fundingNFT) {
        fundingNFT = IFundingNFT(_fundingNFT);
    }

    function createCommunity(string memory _name, string memory _description)
        external
        onlyLeader
    {
        Community storage newCommunity = communities[communityCounts];
        newCommunity.id = communityCounts;
        newCommunity.name = _name;
        newCommunity.description = _description;
        newCommunity.leader = msg.sender;
        communityMembers[msg.sender] = newCommunity;
        emit communityCreated(communityCounts);
        communityCounts++;
    }

    function addMembersToCommunity(address[] calldata memberAddresses)
        external
        onlyLeader
    {
        fundingNFT.setMembers(memberAddresses);
        for (uint256 i; i < memberAddresses.length; i++) {
            communityMembers[msg.sender].members.push(memberAddresses[i]);
        }
    }

    function leftTheCommunity(uint256 communityId)
        external
        onlyMembers(communityId)
    {
        fundingNFT.exitTheCommunity();
        delete communityMembers[msg.sender];
    }

    function transferLeadership(address newLeader, uint256 communityId)
        external
        onlyLeader
    {
        delete communityMembers[msg.sender];
        communities[communityId].leader = newLeader;
        fundingNFT.transferLeadership(newLeader);
    }

    function createProposal(
        uint256 _requiredBudget,
        string memory _desc,
        Goal[] calldata goals
    ) external onlyLeader {
        Proposal storage newProposal = proposals[proposalCounts];
        newProposal.id = proposalCounts;
        newProposal.deadline = block.timestamp + 5 minutes; // it is for tests
        newProposal.requiredBudget = _requiredBudget;
        newProposal.description = _desc;
        newProposal.community = communityMembers[msg.sender];
        for (uint256 i; i < goals.length; i++) {
            newProposal.goals.push(goals[i]);
        }
        emit proposalCreated(proposalCounts);
        proposalCounts++;
    }

    function voteToProposal(uint256 proposalId, Vote vote)
        external
        activeProposal(proposalId)
    {
        require(
            fundingNFT.balanceOf(msg.sender) > 0,
            "You don't have any NFT."
        );
        Proposal storage proposal = proposals[proposalId];
        require(
            proposal.community.leader != communityMembers[msg.sender].leader,
            "You can't vote your own proposal."
        );
        for (uint256 i; i < proposal.voters.length; i++) {
            if (proposal.voters[i] == msg.sender) {
                revert AlreadyVoted();
            }
        }
        proposal.voters.push(msg.sender);
        if (vote == Vote.YES) {
            proposal.yesVotes += 1;
        }
        if (vote == Vote.NO) {
            proposal.noVotes += 1;
        }
    }

    function executeProposal(uint256 proposalIndex)
        external
        finishedProposal(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];
        require(
            proposal.community.leader == msg.sender,
            "The person who opened can execute."
        );
        require(
            proposal.yesVotes > proposal.noVotes,
            "Proposal couldn't pass the vote."
        );
        require(!proposal.executed, "Already executed.");
        proposal.executed = true;
    }

    function fundToProposal(uint256 proposalIndex)
        external
        payable
        onlyFunder
        nftHolderOnly
    {
        Proposal storage proposal = proposals[proposalIndex];
        require(proposal.executed, "Proposal is not executed.");
        proposal.funds += msg.value;
        proposal.fundsBy[msg.sender] = msg.value;
    }

    function getCommunity(uint256 communityId)
        external
        view
        returns (
            uint256 id,
            string memory name,
            string memory description,
            address leader,
            address[] memory members
        )
    {
        Community storage community = communities[communityId];
        return (
            community.id,
            community.name,
            community.description,
            community.leader,
            community.members
        );
    }

    function getLeaderOfTheCommunity(uint256 communityId)
        external
        view
        returns (address)
    {
        return communities[communityId].leader;
    }

    function getProposal(uint256 proposalId)
        external
        view
        returns (
            uint256 id,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 deadline,
            uint256 requiredBudget,
            string memory description,
            Community memory community,
            Goal[] memory goals,
            address[] memory voters,
            uint256 funds,
            bool executed
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.deadline,
            proposal.requiredBudget,
            proposal.description,
            proposal.community,
            proposal.goals,
            proposal.voters,
            proposal.funds,
            proposal.executed
        );
    }

    function getProposalGoals(uint256 proposalId)
        external
        view
        returns (Goal[] memory goals)
    {
        return proposals[proposalId].goals;
    }

    function isProposalExecuted(uint256 proposalId)
        external
        view
        returns (bool)
    {
        return proposals[proposalId].executed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IFundingNFT {
    error OnlyLeaderCanCallTheFunction();
    error OnlyMembersCanCallTheFunction();
    error MemberHasAlreadyHasNFT();
    error YouCanHaveJustOneNFT();
    error InsufficientFunds();

    enum Breed {
        CommunityMemberNFT,
        CommunityLeaderNFT
    }

    function setFunders(address[] calldata funderAddresses) external;

    /**
     *  The caller can only be owner of the contract.
     *  User in given address will qualify for mint leader NFT.
     */
    function setLeader(address leaderAddress) external;

    /**
     *  The caller can only be a leader.
     *  Users in member addresses array will qualify for mint member NFT.
     */
    function setMembers(address[] calldata memberAddresses) external;

    function mintFunderNFT() external;

    /**
     *  Owner of the contract must run setLeader before the function.
     *  The caller can only be a leader.
     */
    function mintLeaderNFT() external;

    /**
     *  One leader must run setMembers function before the function.
     *  The caller can only be a member.
     */
    function mintMemberNFT() external;

    /**
     *  Only leaders can call the function.
     *  They can hand over their leaderships.
     */
    function transferLeadership(address newLeader) external;

    /**
     *  Only members can exit their communities.
     *  If a member run this function their NFT's are burns.
     *  And they lose their voting rights.
     */
    function exitTheCommunity() external;

    function isFunder(address funderAddress) external view returns (bool);

    /**
     *  Is given address a leader?
     */
    function isLeader(address leaderAddress) external view returns (bool);

    /**
     *  Is given address a member?
     */
    function isMember(address memberAddress) external view returns (bool);

    function getTokenId(address tokenOwner) external view returns (uint256);

    function getTokenUris(uint256 index) external view returns (string memory);

    function getTokenCounter() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}