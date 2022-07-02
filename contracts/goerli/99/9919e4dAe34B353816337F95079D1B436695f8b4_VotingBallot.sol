/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Voting Ballot
 *
 * @dev Voting ballot is meant to be used by token holders to create and vote on existent proposals
 */
contract VotingBallot {
    event ProposalCreated(uint256 indexed _id, uint256 indexed _endingPeriod);
    event HolderVoted(address indexed _holder, uint256 indexed _proposalId);
    event HolderDelegated(address indexed _from, address indexed _to);
    
    struct Voter {
        address[] delegators; // who delegated to this voter
        uint256[] delegatedWeight; // and how much weight has been delegated
       
        address delegate; // who did this voter delegated to
        uint256[] voteTrack; // proposal id's this user has voted
    }
    struct Proposal {
        uint256 id;
        string name;
        uint256 endingPeriod;
        bool approved;
    }
    struct Option {
        uint256 id;
        string value;
        uint256 voteCount;
    }
    
    // time ins seconds
    uint256 public votingPeriod;
    address public token;

    uint256 private proposalIdTracker = 1;
    uint256 private optionIdTracker = 1;
    uint256 private minimumPercentageApproval = 51;
    mapping (address => Voter) private voters;
    Proposal[] private proposals;
    // maps proposal's id to its options
    mapping (uint256 => Option[]) private proposalsOptions;
    

    constructor (address deployedTokenAddress, uint256 votingTime) {
        token = deployedTokenAddress;
        votingPeriod = votingTime;
    }

    /**
    * 
    * API
    *
    */
    
    /**
    * @dev Creates a new proposal
    *
    * @param name string The proposal's name
    * @param options string[] The proposal's options
    */
    function create(string calldata name, string[] calldata options) external {
        _assertIsHolder(msg.sender);

        Proposal memory created = _createProposal(name);
        _createProposalOptions(created, options);

        emit ProposalCreated(created.id, created.endingPeriod);
    }

    /**
    * @dev Vote in a proposal
    * Own voting power of a voter is only discharged at vote
    * Whatever weight voter might have before this, it was delegated to him
    *
    * @param proposalId uint256 The proposal's id
    * @param optionId uint256 The option's id
    */
    function vote(uint256 proposalId, uint256 optionId) external {
        uint256 voterOwnWeight = _assertIsHolder(msg.sender);
        _assertProposalExist(proposalId);
        _assertOptionExist(proposalId, optionId);        
        _assertHolderCanVote(proposalId);

        _vote(proposalId, optionId, voterOwnWeight);
    }

    /**
    * @dev Delegate voting power to another holder
    * A holder can not delegate to someone that has already delegated
    *
    * @param to address The holder address to delegate to
    */
    function delegate(address to) external {
        uint256 delegatorWeight = _assertIsHolder(msg.sender);
        _assertIsNotSelfDelegation(to);
        _assertIsHolder(to);
        _assertHolderDidNotDelegated(msg.sender);
        _assertHolderDidNotDelegated(to);

        _delegate(to, delegatorWeight);
    }

    /**
    * @dev Checks if there is any proposal
    *
    * @return bool The existence of proposals
    */
    function hasProposals() external view returns(bool) {
        return proposals.length > 0;
    }

    /**
    * @dev Retrieve a specific proposal
    *
    * @param id uint256 The id of the proposal
    *
    * @return (Proposal, Option[]) The proposal and its options
    */
    function getProposal(uint256 id) external view returns(Proposal memory, Option[] memory) {
        _assertProposalExist(id);

        Proposal memory proposal = _getProposal(id);
        Option[] memory options = _getProposalOptions(id);

        return (proposal, options);
    }

    /**
    * 
    * PRIVATE
    *
    */

    /**
    * @dev Gets a proposal by its id
    *
    * @param id uint256 The id of the proposal
    *
    * @return Proposal The selected proposal
    */
    function _getProposal(uint256 id) private view returns(Proposal storage) {
        // since we can only append proposals, and we won't ever delete them
        // its safe to say that its index in `proposals` will always be id - 1
        return proposals[id - 1];
    }

    /**
    * @dev Gets a proposal's options
    *
    * @param id uint256 The id of the proposal
    *
    * @return Option[] The selected proposal's options
    */
    function _getProposalOptions(uint256 id) private view returns(Option[] storage) {
        return proposalsOptions[id];
    }


    /**
    * @dev Creates a proposal and append it to existent proposals
    *
    * @param name string The proposal's name
    *
    * @return Proposal The created proposal
    */
    function _createProposal(string calldata name) private returns(Proposal memory){
        Proposal memory newProposal = Proposal({
            id: proposalIdTracker++,
            name: name,
            endingPeriod: block.timestamp + votingPeriod,
            approved: false
        });

        proposals.push(newProposal);

        return newProposal;
    }

    /**
    * @dev Creates a proposal's options and add them to the record
    *
    * @param created Proposal The recently created proposal
    * @param options string[] The proposal's options
    */
    function _createProposalOptions(Proposal memory created, string[] calldata options) private {
        require(options.length <= 4, "You can add a maximum of four options");
        require(options.length >= 2, "A minimim of two options is required");

        for (uint i = 0; i < options.length; i++) {
            proposalsOptions[created.id].push(
                Option({ id: optionIdTracker++, value: options[i], voteCount: 0 })
            );
        }
    }

    /**
    * @dev Vote and update voter state and vote count
    *
    * @param proposalId uint256 The proposal's id
    * @param optionId uint256 The option's id
    * @param weight uint256 The holders own weight
    */
    function _vote(uint256 proposalId, uint256 optionId, uint256 weight) private {
        uint256 delegatedWeight = _calculateDelegatedWeight(proposalId);

        _updateVoteTrack(proposalId);
        _updateProposalVoteCount(proposalId, optionId, weight + delegatedWeight);

        emit HolderVoted(msg.sender, proposalId);
    }

    /**
    * @dev Calculate the delegated voting weight of a voter for a vote in a proposal
    *
    * @param proposalId uint256 The proposal's id
    *
    * @return uint256 The valid delegated weight
    */
    function _calculateDelegatedWeight(uint256 proposalId) private returns(uint256) {
        Voter storage voter = voters[msg.sender];
        uint256[] memory copyDelegatedWeight = voter.delegatedWeight;
        uint256 delegatedWeight;

        for (uint256 i = 0; i < copyDelegatedWeight.length; i++) {
            address delegator = voter.delegators[i];
            
            if (!_delegatorIsStillHolder(delegator)) {
                //remove its delegated amount
                delete voter.delegatedWeight[i];
                delete voter.delegators[i];

                continue;
            }

            if (_delegatorAlreadyVotedOnProposal(delegator, proposalId)) {
                // delegator already voted on this proposal
                // do not add his weight to this vote
                continue;
            }

            delegatedWeight += copyDelegatedWeight[i];
        }
        
        return delegatedWeight;
    }

    /**
    * @dev Check if a certain delegator is still a holder of the token
    *
    * @param delegator address The delegator's address
    *
    * @return bool Whether the delegator is still a holder
    */
    function _delegatorIsStillHolder(address delegator) private returns(bool) {
        uint256 balance = _getTokenBalance(delegator);

        return balance > 0;
    }

    /**
    * @dev Check if a delegator already voted on a specific proposal
    *
    * @param delegator address The address of the delegator
    * @param proposalId uint256 The proposal's id
    *
    * @return bool Whether delegator already voted on intented proposal
    */
    function _delegatorAlreadyVotedOnProposal(address delegator, uint256 proposalId) private view returns(bool) {
        uint256[] storage delegatorVotedProposals = voters[delegator].voteTrack;
        bool alreadyVoted = false;
        
        for (uint256 i = 0; i < delegatorVotedProposals.length; i++) {
            alreadyVoted = delegatorVotedProposals[i] == proposalId;

            if (alreadyVoted) {
                break;
            }
        }

        return alreadyVoted;
    }

    /**
    * @dev Updates the proposals a holder has voted for
    *
    * @param proposalId uint256 The id of the proposal
    */
    function _updateVoteTrack(uint256 proposalId) private {
         voters[msg.sender].voteTrack.push(proposalId);
    }

    /**
    * @dev Updates the vote count of a proposal option
    *
    * @param proposalId uint256 The id of the proposal
    * @param optionId uint256 The id of the option
    * @param voteWeight uint256 The vote weight to update the count
    */
    function _updateProposalVoteCount(uint256 proposalId, uint256 optionId, uint256 voteWeight) private {
        Option[] storage options = _getProposalOptions(proposalId);
    
        for (uint256 i = 0; i < options.length; i++) {
            if (options[i].id == optionId) {
                // update vote count
                options[i].voteCount += voteWeight;
                break;
            }
        }
       
        _verifyProposalApprovedState(proposalId, options);
    }

    /**
    * @dev Verifies if a proposal has been approved
    *
    * @param proposalId uint256 The proposal's id
    * @param options Option[] The proposal's options
    */
    function _verifyProposalApprovedState(uint256 proposalId, Option[] storage options) private {
        uint256 totalSupply = _getTokenTotalSupply();

        // a proposal has been approved if one of its options has at
        // least a vote count equal to 51% of the token total supply
        uint256 currentVoteCountPercentage;
        bool approved = false;
        
        for (uint256 i = 0; i < options.length; i++) {
            currentVoteCountPercentage = options[i].voteCount * 100 / totalSupply;
            approved = currentVoteCountPercentage >= minimumPercentageApproval;
           
            if (approved) {
                _getProposal(proposalId).approved = approved;
                break;
            }
        }
    }

    /**
    * @dev Delegate voting power
    *
    * @param to address The holder to delegate to
    * @param weight uint256 The weight to be delegated
    */
    function _delegate(address to, uint256 weight) private {
        Voter storage delegator = voters[msg.sender];

        delegator.delegate = to;
        (address[] memory delegatedBy, uint256[] memory weightToDelegateOver) = _removeTotalDelegatedWeight();
       
        // update target delegation with delegator previously delegated weight
        Voter storage delegated = voters[to];
        for (uint256 i = 0; i < weightToDelegateOver.length; i++) {
            delegated.delegatedWeight.push(weightToDelegateOver[i]);
            delegated.delegators.push(delegatedBy[i]);
        }

        // update target delegation with delegator own weight
        delegated.delegatedWeight.push(weight);
        delegated.delegators.push(msg.sender);
       
        emit HolderDelegated(msg.sender, to);
    }

    /**
    * @dev Calculate the total delegated voting weight of a voter and delete them afterwards
    * To be used in delegation action only
    *
    * @return address[], uint256[] delegators and correspondent weight to be passed on
    */
    function _removeTotalDelegatedWeight() private returns(address[] memory, uint256[] memory) {
        Voter storage delegator = voters[msg.sender];
        uint256[] memory copyDelegatedWeight = delegator.delegatedWeight;

        // keep whoever delegated what, to be passed on to the next delegation
        address[] memory delegatedBy = new address[](copyDelegatedWeight.length);
        uint256[] memory weightToDelegateOver = new uint256[](copyDelegatedWeight.length);
        
        for (uint256 i = 0; i < copyDelegatedWeight.length; i++) {
            delegatedBy[i] = delegator.delegators[i];
            weightToDelegateOver[i] = delegator.delegatedWeight[i];
        
            delete delegator.delegatedWeight[i];
            delete delegator.delegators[i];
        }

        return (delegatedBy, weightToDelegateOver);
    }

    /**
    * @dev Assert a holder can vote on a certain proposal
    *
    * @param id uint256 The proposal's id
    */
    function _assertHolderCanVote(uint256 id) private view {
        _assertProposalIsOngoing(id);
        _assertHolderDidNotDelegated(msg.sender);

        bool voted = false;
        // [] proposal ids holder has voted on
        uint256[] storage votedProposals = voters[msg.sender].voteTrack;

        for (uint256 i = 0; i < votedProposals.length; i++) {
            voted = votedProposals[i] == id;

            if (voted) {
                break;
            }
        }

        require(!voted, "You already voted on this proposal");
    }

    /**
    * @dev Assert if a proposal still up for vote
    *
    * @param id uint256 The id of the proposal
    */
    function _assertProposalIsOngoing(uint256 id) private view {
        require(block.timestamp <= _getProposal(id).endingPeriod, "Voting period has ended");
    }

    /**
    * @dev Assert that a holder did not delegated
    *
    * @param holderAddress address The holder address to assert
    */
    function _assertHolderDidNotDelegated(address holderAddress) private view {
        Voter storage holder = voters[holderAddress];

        require(holder.delegate == address(0), "Voting power has been delegated");
    }

    /**
    * @dev Assert that a holder is not self delegating
    *
    * @param holder address The holder address to assert
    */
    function _assertIsNotSelfDelegation(address holder) private view {
        require(msg.sender != holder, "You can't delegate to yourself");
    }

    /**
    * @dev Assert that a certain address is a token holder
    *
    * @param holder address The address of the holder
    *
    * @return uint256 The balance of the holder
    */
    function _assertIsHolder(address holder) private returns(uint256) {
        uint256 balance = _getTokenBalance(holder);

        require(balance > 0, "Not an holder");

        return balance;
    }

    /**
    * @dev Assert a proposal exists
    *
    * @param id uint256 The id of the proposal
    */
    function _assertProposalExist(uint256 id) private view {
        // since we can only append proposals, and we won't ever delete them
        // its safe to say that its index in `proposals` will always be id - 1
        require(proposals.length > id - 1, "Proposal does not exist");
    }

    /**
    * @dev Assert an option exists
    *
    * @param id uint256 The proposal's id
    * @param optionId uint256 The option id
    */
    function _assertOptionExist(uint256 id, uint256 optionId) private view {
        Option[] storage options = _getProposalOptions(id);
        bool exists = false;

        for (uint256 i = 0; i < options.length; i++) {
            exists = options[i].id == optionId;

            if (exists) {
                break;
            }
        }

        require(exists, "Option does not exist");
    }

    /**
    * @dev Performs a low level call to fetch the token balance of a holder
    *
    * @param holder address The address of the holder
    *
    * @return uint256 The balance of the holder
    */
    function _getTokenBalance(address holder) private returns(uint256) {
        (bool success, bytes memory result) = token.call(abi.encodeWithSignature("balanceOf(address)", holder));

        require(success, "Low level call failed");

        (uint256 data) = abi.decode(result, (uint256));
    
        return data;
    }

    /**
    * @dev Performs a low level call to fetch the token total supply
    *
    * @return uint256 The token total supply
    */
    function _getTokenTotalSupply() private returns(uint256) {
        (bool success, bytes memory result) = token.call(abi.encodeWithSignature("totalSupply()"));

        require(success, "Low level call failed");

        (uint256 data) = abi.decode(result, (uint256));
    
        return data;
    }
}