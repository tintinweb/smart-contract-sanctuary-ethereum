// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface VotingToken {
    function balanceOf(address) external returns (uint256);
    function numberOfVotesAvailable(address) external returns (uint256);
    function totalSupply() external pure returns(uint256);
}

contract Poll {
    address immutable votingTokenAddr;
    uint256 immutable votingPeriod;
    address immutable owner;
    uint8 immutable quroumRequiredPercentage;

    event ProposalQuorumReached(
        string indexed proposalName,
        string winningOption
    );
    event ProposalTimedOut(string indexed proposalName);
    event ProposalFinished(string indexed proposalName);
    event ProposalCreated(string indexed proposalName, address indexed creator);
    event VotesAdded(
        string indexed proposalName,
        string option,
        uint256 numberOfVotes
    );
    event Test(uint256 test);

    mapping(string => Proposal) public proposals;

    struct Proposal {
        uint256 creationTime;
        // prevent computing 'creation+voting period' every time
        uint256 deadlineTime;
        string[] votingOptions;
        address creatorAddr;
        bool isActive;
        mapping(string => uint256) optionVotes;
        mapping(string => mapping(address => uint256)) optionVotesByAddress;
    }

    function getProposalOptionVotes(
        string calldata _propsalName,
        string calldata _option
    ) public view returns (uint256) {
        return proposals[_propsalName].optionVotes[_option];
    }

    constructor(
        uint256 _votingPeriod,
        address _votingTokenAddr,
        uint8 _quroumRequiredPercentage
    ) {
        owner = msg.sender;

        votingPeriod = _votingPeriod;
        quroumRequiredPercentage = _quroumRequiredPercentage;
        votingTokenAddr = _votingTokenAddr;
    }

    modifier isPropsalActive(string memory proposalName) {
        require(
            proposals[proposalName].isActive,
            "User can't interact with inactive proposal"
        );
        _;
    }

    modifier isProposalTimeFinished(string calldata _name) {
        uint256 deadline = proposals[_name].deadlineTime;
        if (block.timestamp >= deadline) {
            makeProposalInactive(_name);
        } else {
            _;
        }
    }

    modifier userHasTokens() {
        require(
            VotingToken(votingTokenAddr).balanceOf(msg.sender) != 0,
            "User should have tokens to preform this operation"
        );
        _;
    }

    function createProposal(
        string calldata _name,
        string[] memory _votingOptions
    ) external userHasTokens {
        require(
            proposals[_name].creationTime == 0,
            "Proposal name should be unique"
        );

        require(
            _votingOptions.length > 1,
            "Proposal should have at least two voting options"
        );

        Proposal storage newProposal = proposals[_name];
        newProposal.creationTime = block.timestamp;
        newProposal.votingOptions = _votingOptions;
        newProposal.deadlineTime = block.timestamp + votingPeriod;
        newProposal.creatorAddr = msg.sender;
        newProposal.isActive = true;

        emit ProposalCreated(_name, msg.sender);
    }

    function voteForProposal(
        string calldata _name,
        string calldata _option,
        uint256 _votes
    )
        external
        userHasTokens
        isPropsalActive(_name)
        isProposalTimeFinished(_name)
    {
        uint256 numberOfVotesAvailable = VotingToken(votingTokenAddr)
            .numberOfVotesAvailable(msg.sender);
        require(
            numberOfVotesAvailable >= _votes,
            "User doesn't have enough votes"
        );

        proposals[_name].optionVotes[_option] += _votes;
        proposals[_name].optionVotesByAddress[_option][msg.sender] += _votes;

        emit VotesAdded(_name, _option, _votes);
        checkIsQuorumReached(_name, _option);
    }

    function removeVotesForProposal(
        string calldata _name,
        string calldata _option
    )
        external
        userHasTokens
        isPropsalActive(_name)
        isProposalTimeFinished(_name)
    {
        uint256 numberOfUserVotes = proposals[_name].optionVotesByAddress[
            _option
        ][msg.sender];

        require(
            numberOfUserVotes != 0,
            "User hasn't yet voted for this proposal"
        );

        proposals[_name].optionVotes[_option] -= numberOfUserVotes;
        proposals[_name].optionVotesByAddress[_option][
            msg.sender
        ] -= numberOfUserVotes;
    }

    function checkIsQuorumReached(
        string calldata _proposalName,
        string calldata _option
    ) private {
        uint256 numberOfVotes = proposals[_proposalName].optionVotes[_option];
        uint256 totalSupply = VotingToken(votingTokenAddr).totalSupply();

        if (((numberOfVotes * 100) / totalSupply) >= quroumRequiredPercentage) {
            emit ProposalQuorumReached(_proposalName, _option);
            makeProposalInactive(_proposalName);
        }
    }

    function makeProposalInactive(string calldata _name) private {
        proposals[_name].isActive = false;
        emit ProposalFinished(_name);
    }
}