// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { Address }         from "@oz/utils/Address.sol";
import { IERC20 }          from "@oz/token/ERC20/IERC20.sol";
import { IVotes }          from "@oz/governance/utils/IVotes.sol";
import { Math }            from "@oz/utils/math/Math.sol";
import { ReentrancyGuard } from "@oz/security/ReentrancyGuard.sol";
import { SafeCast }        from "@oz/utils/math/SafeCast.sol";
import { SafeERC20 }       from "@oz/token/ERC20/utils/SafeERC20.sol";

import { Storage } from "./base/Storage.sol";

import { IGrantFund }        from "./interfaces/IGrantFund.sol";
import { IGrantFundActions } from "./interfaces/IGrantFundActions.sol";

import { Maths } from "./libraries/Maths.sol";


/**
 *  @title  GrantFund Contract
 *  @notice Entrypoint of GrantFund actions for grant fund actors:
 *          - `Proposers`: Create proposals for transfer of ajna tokens to a list of recipients.
 *          - `Voters`: Vote in the Screening and Funding stages of the distribution period on proposals. Claim delegate rewards if eligible.
 *          - `Slate Updaters`: Submit a list of proposals to be finalized for execution during the Challenge Stage of a distribution period.
 *          - `Distribution Starters`: Calls `startNewDistributionPeriod` to start a new distribution period.
 *          - `Treasury Funders`: Calls `fundTreasury` to fund the treasury with ajna tokens.
 *          - `Executors`: Execute finalized proposals after a distribution period has ended.
 *  @dev    Contract inherits from `Storage` abstract contract to contain state variables.
 *  @dev    Events and proposal function interfaces are compliant with OpenZeppelin Governor.
 *  @dev    Calls logic from internal `Maths` library.
 */
contract GrantFund is IGrantFund, Storage, ReentrancyGuard {

    using SafeERC20 for IERC20;

    /*******************/
    /*** Constructor ***/
    /*******************/

    /**
     *  @notice Deploys the GrantFund contract.
     *  @param ajnaToken_ Address of the token which will be distributed to executed proposals, and eligible delegation rewards claimers.
     */
    constructor(address ajnaToken_) {
        ajnaTokenAddress = ajnaToken_;
    }

    /**************************************************/
    /*** Distribution Management Functions External ***/
    /**************************************************/

    /// @inheritdoc IGrantFundActions
    function startNewDistributionPeriod() external override returns (uint24 newDistributionId_) {
        uint24  currentDistributionId       = _currentDistributionId;
        uint256 currentDistributionEndBlock = _distributions[currentDistributionId].endBlock;

        // check that there isn't currently an active distribution period
        if (block.number <= currentDistributionEndBlock) revert DistributionPeriodStillActive();

        // update Treasury with unused funds from last distribution period
        // checks if any previous distribtuion period exists and its unused funds weren't yet re-added into the treasury
        if (currentDistributionId >= 1 && !_isSurplusFundsUpdated[currentDistributionId]) {
            // Add unused funds to treasury
            _updateTreasury(currentDistributionId);
        }

        // set the distribution period to start at the current block
        uint48 startBlock = SafeCast.toUint48(block.number);
        uint48 endBlock   = startBlock + DISTRIBUTION_PERIOD_LENGTH;

        // set new value for currentDistributionId
        newDistributionId_ = _setNewDistributionId(currentDistributionId);

        // create DistributionPeriod struct
        DistributionPeriod storage newDistributionPeriod = _distributions[newDistributionId_];
        newDistributionPeriod.id              = newDistributionId_;
        newDistributionPeriod.startBlock      = startBlock;
        newDistributionPeriod.endBlock        = endBlock;
        uint256 gbc                           = Maths.wmul(treasury, GLOBAL_BUDGET_CONSTRAINT);
        newDistributionPeriod.fundsAvailable  = SafeCast.toUint128(gbc);

        // decrease the treasury by the amount that is held for allocation in the new distribution period
        treasury -= gbc;

        emit DistributionPeriodStarted(
            newDistributionId_,
            startBlock,
            endBlock
        );
    }

    /// @inheritdoc IGrantFundActions
    function fundTreasury(uint256 fundingAmount_) external override {
        IERC20 token = IERC20(ajnaTokenAddress);

        // update treasury accounting
        uint256 newTreasuryAmount = treasury + fundingAmount_;
        treasury = newTreasuryAmount;

        emit FundTreasury(fundingAmount_, newTreasuryAmount);

        // transfer ajna tokens to the treasury
        token.safeTransferFrom(msg.sender, address(this), fundingAmount_);
    }

    /**************************************************/
    /*** Distribution Management Functions Internal ***/
    /**************************************************/

    /**
     * @notice Get the block number at which this distribution period's challenge stage starts.
     * @param  endBlock_ The end block of a distribution period to get the challenge stage start block for.
     * @return The block number at which this distribution period's challenge stage starts.
    */
    function _getChallengeStageStartBlock(
        uint256 endBlock_
    ) internal pure returns (uint256) {
        return (endBlock_ - CHALLENGE_PERIOD_LENGTH) + 1;
    }

    /**
     * @notice Get the block number at which this distribution period's funding stage ends.
     * @param  startBlock_ The end block of a distribution period to get the funding stage end block for.
     * @return The block number at which this distribution period's funding stage ends.
    */
    function _getFundingStageEndBlock(
        uint256 startBlock_
    ) internal pure returns(uint256) {
        return startBlock_ + SCREENING_PERIOD_LENGTH + FUNDING_PERIOD_LENGTH;
    }

    /**
     * @notice Get the block number at which this distribution period's screening stage ends.
     * @param  startBlock_ The start block of a distribution period to get the screening stage end block for.
     * @return The block number at which this distribution period's screening stage ends.
    */
    function _getScreeningStageEndBlock(
        uint256 startBlock_
    ) internal pure returns (uint256) {
        return startBlock_ + SCREENING_PERIOD_LENGTH;
    }

    /**
     * @notice Updates Treasury with surplus funds from distribution.
     * @dev    Counters incremented in an unchecked block due to being bounded by array length of at most 10.
     * @param distributionId_ distribution Id of updating distribution 
     */
    function _updateTreasury(
        uint24 distributionId_
    ) private {
        DistributionPeriod storage distribution = _distributions[distributionId_];
        bytes32 fundedSlateHash = distribution.fundedSlateHash;
        uint256 fundsAvailable  = distribution.fundsAvailable;

        uint256[] storage fundingProposalIds = _fundedProposalSlates[fundedSlateHash];

        uint256 totalTokenDistributed;
        uint256 numFundedProposals = fundingProposalIds.length;

        for (uint256 i = 0; i < numFundedProposals; ) {

            totalTokenDistributed += _proposals[fundingProposalIds[i]].tokensRequested;

            unchecked { ++i; }
        }

        uint256 totalDelegateRewards;
        // Increment totalDelegateRewards by delegate rewards if anyone has voted during funding voting
        if (_distributions[distributionId_].fundingVotePowerCast != 0) totalDelegateRewards = (fundsAvailable / 10);

        // re-add non distributed tokens to the treasury
        treasury += (fundsAvailable - totalTokenDistributed - totalDelegateRewards);

        _isSurplusFundsUpdated[distributionId_] = true;
    }

    /**
     * @notice Set a new DistributionPeriod Id.
     * @dev    Increments the previous Id nonce by 1.
     * @return newId_ The new distribution period Id.
     */
    function _setNewDistributionId(uint24 currentDistributionId_) private returns (uint24 newId_) {
        newId_ = ++currentDistributionId_;
        _currentDistributionId = newId_;
    }

    /************************************/
    /*** Delegation Rewards Functions ***/
    /************************************/

    /// @inheritdoc IGrantFundActions
    function claimDelegateReward(
        uint24 distributionId_
    ) external override returns (uint256 rewardClaimed_) {
        VoterInfo storage voter = _voterInfo[distributionId_][msg.sender];

        // Revert if delegatee didn't vote in screening stage
        if (voter.screeningVotesCast == 0) revert DelegateRewardInvalid();

        DistributionPeriod storage currentDistribution = _distributions[distributionId_];

        // Check if the distribution period is still active
        if (block.number <= currentDistribution.endBlock) revert DistributionPeriodStillActive();

        // check rewards haven't already been claimed
        if (voter.hasClaimedReward) revert RewardAlreadyClaimed();

        // calculate rewards earned for voting
        rewardClaimed_ = _getDelegateReward(currentDistribution, voter);

        voter.hasClaimedReward = true;

        emit DelegateRewardClaimed(
            msg.sender,
            distributionId_,
            rewardClaimed_
        );

        // transfer rewards to delegatee
        if (rewardClaimed_ != 0) IERC20(ajnaTokenAddress).safeTransfer(msg.sender, rewardClaimed_);
    }

    /**
     * @notice Calculate the delegate rewards that have accrued to a given voter, in a given distribution period.
     * @dev    Voter must have voted in both the screening and funding stages, and is proportional to their share of votes across the stages.
     * @param  currentDistribution_ Struct of the distribution period to calculate rewards for.
     * @param  voter_               Struct of the funding stages voter.
     * @return rewards_             The delegate rewards accrued to the voter.
     */
    function _getDelegateReward(
        DistributionPeriod storage currentDistribution_,
        VoterInfo storage voter_
    ) internal view returns (uint256 rewards_) {
        // calculate the total voting power available to the voter that was allocated in the funding stage
        uint256 votingPowerAllocatedByDelegatee = voter_.fundingVotingPower - voter_.fundingRemainingVotingPower;
        // take the sqrt of the voting power allocated to compare against the root of all voting power allocated
        // multiply by 1e18 to maintain WAD precision
        uint256 rootVotingPowerAllocatedByDelegatee = Math.sqrt(votingPowerAllocatedByDelegatee * 1e18);

        // if none of the voter's voting power was allocated, they receive no rewards
        if (rootVotingPowerAllocatedByDelegatee != 0) {
            // calculate reward
            // delegateeReward = 10 % of GBC distributed as per delegatee Voting power allocated
            rewards_ = Math.mulDiv(
                currentDistribution_.fundsAvailable,
                rootVotingPowerAllocatedByDelegatee,
                10 * currentDistribution_.fundingVotePowerCast
            );
        }
    }

    /***********************************/
    /*** Proposal Functions External ***/
    /***********************************/

    /// @inheritdoc IGrantFundActions
    function hashProposal(
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        bytes32 descriptionHash_
    ) external pure override returns (uint256 proposalId_) {
        proposalId_ = _hashProposal(targets_, values_, calldatas_, descriptionHash_);
    }

    /// @inheritdoc IGrantFundActions
    function execute(
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        bytes32 descriptionHash_
    ) external nonReentrant override returns (uint256 proposalId_) {
        proposalId_ = _hashProposal(targets_, values_, calldatas_, descriptionHash_);
        Proposal storage proposal = _proposals[proposalId_];

        uint24 distributionId = proposal.distributionId;

        // check that the distribution period has ended, and one week has passed to enable competing slates to be checked
        if (block.number <= _distributions[distributionId].endBlock) revert ExecuteProposalInvalid();

        // check proposal is successful and hasn't already been executed
        if (!_isProposalFinalized(proposalId_) || proposal.executed) revert ProposalNotSuccessful();

        proposal.executed = true;

        _execute(proposalId_, calldatas_);
    }

    /// @inheritdoc IGrantFundActions
    function propose(
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        string memory description_
    ) external override returns (uint256 proposalId_) {
        // check description string isn't empty
        if (bytes(description_).length == 0) revert InvalidProposal();

        proposalId_ = _hashProposal(targets_, values_, calldatas_, _getDescriptionHash(description_));

        Proposal storage newProposal = _proposals[proposalId_];

        // check for duplicate proposals
        if (newProposal.proposalId != 0) revert ProposalAlreadyExists();

        DistributionPeriod storage currentDistribution = _distributions[_currentDistributionId];

        // cannot add new proposal after end of screening period
        // screening period ends 72000 blocks before end of distribution period, ~ 80 days.
        if (block.number > _getScreeningStageEndBlock(currentDistribution.startBlock)) revert ScreeningPeriodEnded();

        // store new proposal information
        newProposal.proposalId      = proposalId_;
        newProposal.distributionId  = currentDistribution.id;
        uint128 tokensRequested     = _validateCallDatas(targets_, values_, calldatas_); // check proposal parameters are valid and update tokensRequested
        newProposal.tokensRequested = tokensRequested;

        // revert if proposal requested more tokens than are available in the distribution period
        if (tokensRequested > (currentDistribution.fundsAvailable * 9 / 10)) revert InvalidProposal();

        emit ProposalCreated(
            proposalId_,
            msg.sender,
            targets_,
            values_,
            new string[](targets_.length),
            calldatas_,
            block.number,
            currentDistribution.endBlock,
            description_
        );
    }

    /// @inheritdoc IGrantFundActions
    function state(
        uint256 proposalId_
    ) external view override returns (ProposalState) {
        return _state(proposalId_);
    }

    /// @inheritdoc IGrantFundActions
    function updateSlate(
        uint256[] calldata proposalIds_,
        uint24 distributionId_
    ) external override returns (bool newTopSlate_) {
        DistributionPeriod storage currentDistribution = _distributions[distributionId_];

        // store number of proposals for reduced gas cost of iterations
        uint256 numProposalsInSlate = proposalIds_.length;

        // check the each proposal in the slate is valid, and get the sum of the proposals fundingVotesReceived
        uint256 sum = _validateSlate(
            distributionId_,
            currentDistribution.endBlock,
            currentDistribution.fundsAvailable,
            proposalIds_,
            numProposalsInSlate
        );

        // get pointers for comparing proposal slates
        bytes32 currentSlateHash = currentDistribution.fundedSlateHash;
        bytes32 newSlateHash     = keccak256(abi.encode(proposalIds_));

        // check if slate of proposals is better than the existing slate, and is thus the new top slate
        newTopSlate_ = currentSlateHash == 0 || sum > _sumProposalFundingVotes(_fundedProposalSlates[currentSlateHash]);

        // if slate of proposals is new top slate, update state
        if (newTopSlate_) {
            for (uint256 i = 0; i < numProposalsInSlate; ) {
                // update list of proposals to fund
                _fundedProposalSlates[newSlateHash].push(proposalIds_[i]);

                unchecked { ++i; }
            }

            // update hash to point to the new leading slate of proposals
            currentDistribution.fundedSlateHash = newSlateHash;

            emit FundedSlateUpdated(
                distributionId_,
                newSlateHash
            );
        }
    }

    /***********************************/
    /*** Proposal Functions Internal ***/
    /***********************************/

    /**
     * @notice Execute the calldata of a passed proposal.
     * @dev    Counters incremented in an unchecked block due to being bounded by array length.
     * @param proposalId_ The ID of proposal to execute.
     * @param calldatas_  The list of calldatas to execute.
     */
    function _execute(
        uint256 proposalId_,
        bytes[] memory calldatas_
    ) internal {
        string memory errorMessage = "GF_CALL_NO_MSG";

        uint256 noOfCalldatas = calldatas_.length;
        for (uint256 i = 0; i < noOfCalldatas;) {
            // proposals can only ever target the Ajna token contract, with 0 value
            (bool success, bytes memory returndata) = ajnaTokenAddress.call{value: 0}(calldatas_[i]);
            Address.verifyCallResult(success, returndata, errorMessage);

            unchecked { ++i; }
        }

        // use common event name to maintain consistency with tally
        emit ProposalExecuted(proposalId_);
    }

    /**
     * @notice Check an array of proposalIds for duplicate IDs.
     * @dev    Only iterates through a maximum of 10 proposals that made it through the screening round.
     * @dev    Counters incremented in an unchecked block due to being bounded by array length.
     * @param  proposalIds_ Array of proposal Ids to check.
     * @return Boolean indicating the presence of a duplicate. True if it has a duplicate; false if not.
     */
    function _hasDuplicates(
        uint256[] calldata proposalIds_
    ) internal pure returns (bool) {
        uint256 numProposals = proposalIds_.length;

        for (uint256 i = 0; i < numProposals; ) {
            for (uint256 j = i + 1; j < numProposals; ) {
                if (proposalIds_[i] == proposalIds_[j]) return true;

                unchecked { ++j; }
            }

            unchecked { ++i; }

        }
        return false;
    }

    function _getDescriptionHash(
        string memory description_
    ) internal pure returns (bytes32) {
        return keccak256(bytes(description_));
    }

    /**
     * @notice Create a proposalId from a hash of proposal's targets, values, and calldatas arrays, and a description hash.
     * @dev    Consistent with proposalId generation methods used in OpenZeppelin Governor.
     * @param targets_         The addresses of the contracts to call.
     * @param values_          The amounts of ETH to send to each target.
     * @param calldatas_       The calldata to send to each target.
     * @param descriptionHash_ The hash of the proposal's description string. Generated by keccak256(bytes(description))).
     * @return proposalId_     The hashed proposalId created from the provided params.
     */
    function _hashProposal(
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        bytes32 descriptionHash_
    ) internal pure returns (uint256 proposalId_) {
        proposalId_ = uint256(keccak256(abi.encode(targets_, values_, calldatas_, descriptionHash_)));
    }

    /**
     * @notice Calculates the sum of funding votes allocated to a list of proposals.
     * @dev    Only iterates through a maximum of 10 proposals that made it through the screening round.
     * @dev    Counters incremented in an unchecked block due to being bounded by array length of at most 10.
     * @param  proposalIdSubset_ Array of proposal Ids to sum.
     * @return sum_ The sum of the funding votes across the given proposals.
     */
    function _sumProposalFundingVotes(
        uint256[] memory proposalIdSubset_
    ) internal view returns (uint128 sum_) {
        uint256 noOfProposals = proposalIdSubset_.length;

        for (uint256 i = 0; i < noOfProposals;) {
            // since we are converting from int128 to uint128, we can safely assume that the value will not overflow
            sum_ += uint128(_proposals[proposalIdSubset_[i]].fundingVotesReceived);

            unchecked { ++i; }
        }
    }

    /**
     * @notice Get the current ProposalState of a given proposal.
     * @dev    Used by GrantFund.state() for analytics compatibility purposes.
     * @param  proposalId_ The ID of the proposal being checked.
     * @return The proposals status in the ProposalState enum.
     */
    function _state(uint256 proposalId_) internal view returns (ProposalState) {
        Proposal memory proposal = _proposals[proposalId_];

        if (proposal.executed)                                                    return ProposalState.Executed;
        else if (_distributions[proposal.distributionId].endBlock > block.number) return ProposalState.Active;
        else if (_isProposalFinalized(proposalId_))                              return ProposalState.Succeeded;
        else                                                                      return ProposalState.Defeated;
    }

    /**
     * @notice Verifies proposal's targets, values, and calldatas match specifications.
     * @dev    Counters incremented in an unchecked block due to being bounded by array length.
     * @param targets_         The addresses of the contracts to call.
     * @param values_          The amounts of ETH to send to each target.
     * @param calldatas_       The calldata to send to each target.
     * @return tokensRequested_ The amount of tokens requested in the calldata.
     */
    function _validateCallDatas(
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_
    ) internal view returns (uint128 tokensRequested_) {
        uint256 noOfTargets = targets_.length;

        // check params have matching lengths
        if (
            noOfTargets == 0 || noOfTargets != values_.length || noOfTargets != calldatas_.length
        ) revert InvalidProposal();

        for (uint256 i = 0; i < noOfTargets;) {

            // check targets and values params are valid
            if (targets_[i] != ajnaTokenAddress || values_[i] != 0) revert InvalidProposal();

            // check calldata includes both required params
            if (calldatas_[i].length != 68) revert InvalidProposal();

            // access individual calldata bytes
            bytes memory data = calldatas_[i];

            // retrieve the selector from the calldata
            bytes4 selector;
            // slither-disable-next-line assembly
            assembly {
                selector := mload(add(data, 0x20))
            }
            // check the selector matches transfer(address,uint256)
            if (selector != bytes4(0xa9059cbb)) revert InvalidProposal();

            // https://github.com/ethereum/solidity/issues/9439
            // retrieve recipient and tokensRequested from incoming calldata, accounting for the function selector
            uint256 tokensRequested;
            address recipient;
            // slither-disable-next-line assembly
            assembly {
                recipient := mload(add(data, 36)) // 36 = 4 (selector) + 32 (recipient address)
                tokensRequested := mload(add(data, 68)) // 68 = 4 (selector) + 32 (recipient address) + 32 (tokens requested)
            }

            // check recipient in the calldata is valid and doesn't attempt to transfer tokens to a disallowed address
            if (recipient == address(0) || recipient == ajnaTokenAddress || recipient == address(this)) revert InvalidProposal();

            // update tokens requested for additional calldata
            tokensRequested_ += SafeCast.toUint128(tokensRequested);

            unchecked { ++i; }
        }
    }

    /**
     * @notice Check the validity of a potential slate of proposals to execute, and sum the slate's fundingVotesReceived.
     * @dev    Only iterates through a maximum of 10 proposals that made it through both voting stages.
     * @dev    Counters incremented in an unchecked block due to being bounded by array length.
     * @param  distributionId_                   Id of the distribution period to check the slate for.
     * @param  endBlock                          End block of the distribution period.
     * @param  distributionPeriodFundsAvailable_ Funds available for distribution in the distribution period.
     * @param  proposalIds_                      Array of proposal Ids to check.
     * @param  numProposalsInSlate_              Number of proposals in the slate.
     * @return sum_                              The total funding votes received by all proposals in the proposed slate.
     */
    function _validateSlate(
        uint24 distributionId_,
        uint256 endBlock,
        uint256 distributionPeriodFundsAvailable_,
        uint256[] calldata proposalIds_,
        uint256 numProposalsInSlate_
    ) internal view returns (uint256 sum_) {
        // check that the function is being called within the challenge period,
        // and that there is a proposal in the slate
        if (
            block.number > endBlock ||
            block.number < _getChallengeStageStartBlock(endBlock) ||
            numProposalsInSlate_ == 0
        ) {
            revert InvalidProposalSlate();
        }

        // check that the slate has no duplicates
        if (_hasDuplicates(proposalIds_)) revert InvalidProposalSlate();

        uint256 gbc = distributionPeriodFundsAvailable_;
        uint256 totalTokensRequested = 0;

        // check each proposal in the slate is valid
        for (uint256 i = 0; i < numProposalsInSlate_; ) {
            Proposal storage proposal = _proposals[proposalIds_[i]];

            // check if Proposal is in the topTenProposals list
            if (
                _findProposalIndex(proposalIds_[i], _topTenProposals[distributionId_]) == -1
            ) revert InvalidProposalSlate();

            // account for fundingVotesReceived possibly being negative
            // block proposals that recieve no positive funding votes from entering a finalized slate
            if (proposal.fundingVotesReceived <= 0) revert InvalidProposalSlate();

            // update counters
            // since we are converting from int128 to uint128, we can safely assume that the value will not overflow
            sum_ += uint128(proposal.fundingVotesReceived);
            totalTokensRequested += proposal.tokensRequested;

            unchecked { ++i; }
        }

        // check if slate of proposals exceeded budget constraint ( 90% of GBC )
        if (totalTokensRequested > (gbc * 9 / 10)) revert InvalidProposalSlate();
    }

    /*********************************/
    /*** Voting Functions External ***/
    /*********************************/

    /// @inheritdoc IGrantFundActions
    function fundingVote(
        FundingVoteParams[] calldata voteParams_
    ) external override returns (uint256 votesCast_) {
        uint24 currentDistributionId = _currentDistributionId;

        DistributionPeriod storage currentDistribution = _distributions[currentDistributionId];
        VoterInfo          storage voter               = _voterInfo[currentDistributionId][msg.sender];

        uint256 startBlock = currentDistribution.startBlock;

        uint256 screeningStageEndBlock = _getScreeningStageEndBlock(startBlock);

        // check that the funding stage is active
        if (block.number <= screeningStageEndBlock || block.number > _getFundingStageEndBlock(startBlock)) revert InvalidVote();

        uint128 votingPower = voter.fundingVotingPower;

        // if this is the first time a voter has attempted to vote this period,
        // set initial voting power and remaining voting power
        if (votingPower == 0) {

            // calculate the voting power available to the voting power in this funding stage
            uint128 newVotingPower = SafeCast.toUint128(
                _getVotesFunding(
                    msg.sender,
                    votingPower,
                    voter.fundingRemainingVotingPower,
                    screeningStageEndBlock
                )
            );

            voter.fundingVotingPower          = newVotingPower;
            voter.fundingRemainingVotingPower = newVotingPower;
        }

        uint256 numVotesCast = voteParams_.length;

        for (uint256 i = 0; i < numVotesCast; ) {
            Proposal storage proposal = _proposals[voteParams_[i].proposalId];

            // check that the proposal is part of the current distribution period
            if (proposal.distributionId != currentDistributionId) revert InvalidVote();

            // check that the voter isn't attempting to cast a vote with 0 power
            if (voteParams_[i].votesUsed == 0) revert InvalidVote();

            // check that the proposal being voted on is in the top ten screened proposals
            if (
                _findProposalIndex(voteParams_[i].proposalId, _topTenProposals[currentDistributionId]) == -1
            ) revert InvalidVote();

            // cast each successive vote
            votesCast_ += _fundingVote(
                currentDistribution,
                proposal,
                voter,
                voteParams_[i]
            );

            unchecked { ++i; }
        }
    }

    /// @inheritdoc IGrantFundActions
    function screeningVote(
        ScreeningVoteParams[] calldata voteParams_
    ) external override returns (uint256 votesCast_) {
        uint24 distributionId = _currentDistributionId;
        DistributionPeriod storage currentDistribution = _distributions[distributionId];
        uint256 startBlock = currentDistribution.startBlock;

        // check screening stage is active
        if (
            block.number < startBlock
            ||
            block.number > _getScreeningStageEndBlock(startBlock)
        ) revert InvalidVote();

        uint256 numVotesCast = voteParams_.length;

        VoterInfo storage voter = _voterInfo[distributionId][msg.sender];

        for (uint256 i = 0; i < numVotesCast; ) {
            Proposal storage proposal = _proposals[voteParams_[i].proposalId];

            // check that the proposal is part of the current distribution period
            if (proposal.distributionId != distributionId) revert InvalidVote();

            uint256 votes = voteParams_[i].votes;

            // check that the voter isn't attempting to cast a vote with 0 power
            if (votes == 0) revert InvalidVote();

            // cast each successive vote
            votesCast_ += votes;
            _screeningVote(proposal, voter, votes);

            unchecked { ++i; }
        }
    }

    /*********************************/
    /*** Voting Functions Internal ***/
    /*********************************/

    /**
     * @notice Vote on a proposal in the funding stage of the Distribution Period.
     * @dev    Votes can be allocated to multiple proposals, quadratically, for or against.
     * @param  currentDistribution_  The current distribution period.
     * @param  proposal_             The current proposal being voted upon.
     * @param  voter_                The voter data struct tracking available votes.
     * @param  voteParams_           The amount of votes being allocated to the proposal. Not squared. If less than 0, vote is against.
     * @return incrementalVotesUsed_ The amount of funding stage votes allocated to the proposal.
     */
    function _fundingVote(
        DistributionPeriod storage currentDistribution_,
        Proposal storage proposal_,
        VoterInfo storage voter_,
        FundingVoteParams calldata voteParams_
    ) internal returns (uint256 incrementalVotesUsed_) {
        uint8   support = 1;
        uint256 proposalId = proposal_.proposalId;

        // determine if voter is voting for or against the proposal
        voteParams_.votesUsed < 0 ? support = 0 : support = 1;

        uint128 votingPower = voter_.fundingVotingPower;

        // the total amount of voting power used by the voter before this vote executes
        uint128 voterPowerUsedPreVote = votingPower - voter_.fundingRemainingVotingPower;

        FundingVoteParams[] storage votesCast = voter_.votesCast;

        // check that the voter hasn't already voted on a proposal by seeing if it's already in the votesCast array 
        int256 voteCastIndex = _findProposalIndexOfVotesCast(proposalId, votesCast);

        // voter had already cast a funding vote on this proposal
        if (voteCastIndex != -1) {
            // since we are converting from int256 to uint256, we can safely assume that the value will not overflow
            FundingVoteParams storage existingVote = votesCast[uint256(voteCastIndex)];
            int256 votesUsed = existingVote.votesUsed;

            // can't change the direction of a previous vote
            if (
                (support == 0 && votesUsed > 0) || (support == 1 && votesUsed < 0)
            ) {
                // if the vote is in the opposite direction of a previous vote,
                // and the proposal is already in the votesCast array, revert can't change direction
                revert FundingVoteWrongDirection();
            }
            else {
                // update the votes cast for the proposal
                existingVote.votesUsed += voteParams_.votesUsed;
            }
        }
        // first time voting on this proposal, add the newly cast vote to the voter's votesCast array
        else {
            votesCast.push(voteParams_);
        }

        // calculate the cumulative cost of all votes made by the voter
        // and ensure that attempted votes cast doesn't overflow uint128
        uint256 sumOfTheSquareOfVotesCast = _sumSquareOfVotesCast(votesCast);
        uint128 cumulativeVotePowerUsed = SafeCast.toUint128(sumOfTheSquareOfVotesCast);

        // check that the voter has enough voting power remaining to cast the vote
        if (cumulativeVotePowerUsed > votingPower) revert InsufficientRemainingVotingPower();

        // update voter voting power accumulator
        voter_.fundingRemainingVotingPower = votingPower - cumulativeVotePowerUsed;

        // calculate the total sqrt voting power used in the funding stage, in order to calculate delegate rewards.
        // since we are moving from uint128 to uint256, we can safely assume that the value will not overflow.
        // multiply by 1e18 to maintain WAD precision.
        uint256 incrementalRootVotingPowerUsed =
            Math.sqrt(uint256(cumulativeVotePowerUsed) * 1e18) - Math.sqrt(uint256(voterPowerUsedPreVote) * 1e18);

        // update accumulator for total root voting power used in the funding stage in order to calculate delegate rewards
        // check that the voter voted in the screening round before updating the accumulator
        if (voter_.screeningVotesCast != 0) {
            currentDistribution_.fundingVotePowerCast += incrementalRootVotingPowerUsed;
        }

        // update proposal vote tracking
        proposal_.fundingVotesReceived += SafeCast.toInt128(voteParams_.votesUsed);

        // the incremental additional votes cast on the proposal to be used as a return value and emit value
        incrementalVotesUsed_ = Maths.abs(voteParams_.votesUsed);

        // emit VoteCast instead of VoteCastWithParams to maintain compatibility with Tally
        // emits the amount of incremental votes cast for the proposal, not the voting power cost or total votes on a proposal
        emit VoteCast(
            msg.sender,
            proposalId,
            support,
            incrementalVotesUsed_,
            ""
        );
    }

    /**
     * @notice Vote on a proposal in the screening stage of the Distribution Period.
     * @param proposal_ The current proposal being voted upon.
     * @param votes_    The amount of votes being cast.
     */
    function _screeningVote(
        Proposal storage proposal_,
        VoterInfo storage voter_,
        uint256 votes_
    ) internal {
        uint24 distributionId = proposal_.distributionId;

        // check that the voter has enough voting power to cast the vote
        uint248 pastScreeningVotesCast = voter_.screeningVotesCast;
        if (
            pastScreeningVotesCast + votes_ > _getVotesScreening(distributionId, msg.sender)
        ) revert InsufficientVotingPower();

        uint256[] storage currentTopTenProposals = _topTenProposals[distributionId];
        uint256 proposalId = proposal_.proposalId;

        // update proposal votes counter
        proposal_.votesReceived += SafeCast.toUint128(votes_);

        // check if proposal was already screened
        int256 indexInArray = _findProposalIndex(proposalId, currentTopTenProposals);
        uint256 screenedProposalsLength = currentTopTenProposals.length;

        // check if the proposal should be added to the top ten list for the first time
        if (screenedProposalsLength < 10 && indexInArray == -1) {
            currentTopTenProposals.push(proposalId);

            // sort top ten proposals
            _insertionSortProposalsByVotes(currentTopTenProposals, screenedProposalsLength);
        }
        else {
            // proposal is already in the array
            if (indexInArray != -1) {
                // re-sort top ten proposals to account for new vote totals
                _insertionSortProposalsByVotes(currentTopTenProposals, uint256(indexInArray));
            }
            // proposal isn't already in the array
            else if (_proposals[currentTopTenProposals[screenedProposalsLength - 1]].votesReceived < proposal_.votesReceived) {
                // replace the least supported proposal with the new proposal
                currentTopTenProposals.pop();
                currentTopTenProposals.push(proposalId);

                // sort top ten proposals
                _insertionSortProposalsByVotes(currentTopTenProposals, screenedProposalsLength - 1);
            }
        }

        // record voters vote
        voter_.screeningVotesCast = pastScreeningVotesCast + SafeCast.toUint248(votes_);

        // emit VoteCast instead of VoteCastWithParams to maintain compatibility with Tally
        emit VoteCast(
            msg.sender,
            proposalId,
            1,
            votes_,
            ""
        );
    }

    /**
     * @notice Identify where in an array of proposalIds the proposal exists.
     * @dev    Only iterates through a maximum of 10 proposals that made it through the screening round.
     * @dev    Counters incremented in an unchecked block due to being bounded by array length.
     * @param  proposalId_ The proposalId to search for.
     * @param  array_      The array of proposalIds to search.
     * @return index_      The index of the proposalId in the array, else -1.
     */
    function _findProposalIndex(
        uint256 proposalId_,
        uint256[] storage array_
    ) internal view returns (int256 index_) {
        index_ = -1; // default value indicating proposalId not in the array
        uint256 arrayLength = array_.length;

        for (uint256 i = 0; i < arrayLength;) {
            // slither-disable-next-line incorrect-equality
            if (array_[i] == proposalId_) {
                index_ = int256(i);
                break;
            }

            unchecked { ++i; }
        }
    }

    /**
     * @notice Identify where in an array of FundingVoteParams structs the proposal exists.
     * @dev    Only iterates through a maximum of 10 proposals that made it through the screening round.
     * @dev    Counters incremented in an unchecked block due to being bounded by array length.
     * @param proposalId_ The proposalId to search for.
     * @param voteParams_ The array of FundingVoteParams structs to search.
     * @return index_ The index of the proposalId in the array, else -1.
     */
    function _findProposalIndexOfVotesCast(
        uint256 proposalId_,
        FundingVoteParams[] storage voteParams_
    ) internal view returns (int256 index_) {
        index_ = -1; // default value indicating proposalId not in the array

        // since we are converting from uint256 to int256, we can safely assume that the value will not overflow
        uint256 numVotesCast = voteParams_.length;
        for (uint256 i = 0; i < numVotesCast; ) {
            // slither-disable-next-line incorrect-equality
            if (voteParams_[i].proposalId == proposalId_) {
                index_ = int256(i);
                break;
            }

            unchecked { ++i; }
        }
    }

    /**
     * @notice Sort the 10 proposals which will make it through screening and move on to the funding round.
     * @dev    Implements the descending insertion sort algorithm.
     * @dev    Counters incremented in an unchecked block due to being bounded by array length.
     * @dev    Since we are converting from int256 to uint256, we can safely assume that the values will not overflow.
     * @param proposals_           The array of proposals to sort by votes received.
     * @param targetProposalIndex_ The targeted proposal index to insert in proposals array.
     */
    function _insertionSortProposalsByVotes(
        uint256[] storage proposals_,
        uint256 targetProposalIndex_
    ) internal {
        while (
            targetProposalIndex_ != 0
            &&
            _proposals[proposals_[targetProposalIndex_]].votesReceived > _proposals[proposals_[targetProposalIndex_ - 1]].votesReceived
        ) {
            // swap values if left item < right item
            uint256 temp = proposals_[targetProposalIndex_ - 1];

            proposals_[targetProposalIndex_ - 1] = proposals_[targetProposalIndex_];
            proposals_[targetProposalIndex_] = temp;

            unchecked { --targetProposalIndex_; }
        }
    }

    /**
     * @notice Sum the square of each vote cast by a voter.
     * @dev    Used to calculate if a voter has enough voting power to cast their votes.
     * @dev    Only iterates through a maximum of 10 proposals that made it through the screening round.
     * @dev    Counters incremented in an unchecked block due to being bounded by array length.
     * @param  votesCast_           The array of votes cast by a voter.
     * @return votesCastSumSquared_ The sum of the square of each vote cast.
     */
    function _sumSquareOfVotesCast(
        FundingVoteParams[] storage votesCast_
    ) internal view returns (uint256 votesCastSumSquared_) {
        uint256 numVotesCast = votesCast_.length;

        for (uint256 i = 0; i < numVotesCast; ) {
            votesCastSumSquared_ += Maths.wpow(Maths.abs(votesCast_[i].votesUsed), 2);

            unchecked { ++i; }
        }
    }

    /**
     * @notice Check to see if a proposal is in it's distribution period's top funded slate of proposals.
     * @param  proposalId_ The proposalId to check.
     * @return             True if the proposal is in the it's distribution period's slate hash.
     */
    function _isProposalFinalized(
        uint256 proposalId_
    ) internal view returns (bool) {
        uint24 distributionId = _proposals[proposalId_].distributionId;
        return _findProposalIndex(proposalId_, _fundedProposalSlates[_distributions[distributionId].fundedSlateHash]) != -1;
    }

    /**
     * @notice Retrieve the number of votes available to an account in the current screening stage.
     * @param  distributionId_ The distribution id to screen votes for.
     * @param  account_        The account to retrieve votes for.
     * @return votes_          The number of votes available to an account in this screening stage.
     */
    function _getVotesScreening(uint24 distributionId_, address account_) internal view returns (uint256 votes_) {
        uint256 startBlock = _distributions[distributionId_].startBlock;
        uint256 snapshotBlock = startBlock - 1;

        // calculate voting weight based on the number of tokens held at the snapshot blocks of the screening stage
        votes_ = _getVotesAtSnapshotBlocks(
            account_,
            snapshotBlock - VOTING_POWER_SNAPSHOT_DELAY,
            snapshotBlock
        );
    }

    /**
     * @notice Retrieve the number of votes available to an account in the current funding stage.
     * @param  account_                The address of the voter to check.
     * @param  votingPower_            The voter's voting power in the funding round. Equal to the square of their tokens in the voting snapshot.
     * @param  remainingVotingPower_   The voter's remaining quadratic voting power in the given distribution period's funding round.
     * @param  screeningStageEndBlock_ The block number at which the screening stage ends.
     * @return votes_                  The number of votes available to an account in this funding stage.
     */
    function _getVotesFunding(
        address account_,
        uint256 votingPower_,
        uint256 remainingVotingPower_,
        uint256 screeningStageEndBlock_
    ) internal view returns (uint256 votes_) {
        // voter has already allocated some of their budget this period
        if (votingPower_ != 0) {
            votes_ = remainingVotingPower_;
        }
        // voter hasn't yet called _castVote in this period
        else {
            uint256 fundingStageStartBlock = screeningStageEndBlock_;
            votes_ = Maths.wpow(
                _getVotesAtSnapshotBlocks(
                    account_,
                    fundingStageStartBlock - VOTING_POWER_SNAPSHOT_DELAY,
                    fundingStageStartBlock
                ),
                2
            );
        }
    }

     /**
     * @notice Retrieve the voting power of an account.
     * @dev    Voting power is the minimum of the amount of votes available at two snapshots:
     *         a snapshot 34 blocks prior to voting start, and the second snapshot the block before the distribution period starts.
     * @param account_        The voting account.
     * @param snapshot_       One of the block numbers to retrieve the voting power at. 34 blocks prior to the block at which a proposal is available for voting.
     * @param voteStartBlock_ The block number the proposal became available for voting.
     * @return                The voting power of the account.
     */
    function _getVotesAtSnapshotBlocks(
        address account_,
        uint256 snapshot_,
        uint256 voteStartBlock_
    ) internal view returns (uint256) {
        IVotes token = IVotes(ajnaTokenAddress);

        // calculate the number of votes available at the first snapshot block
        uint256 votes1 = token.getPastVotes(account_, snapshot_);

        // calculate the number of votes available at the second snapshot occuring the block before the stage's start block
        uint256 votes2 = token.getPastVotes(account_, voteStartBlock_);

        return Maths.min(votes2, votes1);
    }

    /*******************************/
    /*** External View Functions ***/
    /*******************************/

    /// @inheritdoc IGrantFundActions
    function getChallengeStageStartBlock(uint256 endBlock_) external pure override returns (uint256) {
        return _getChallengeStageStartBlock(endBlock_);
    }

    /// @inheritdoc IGrantFundActions
    function getDescriptionHash(
        string memory description_
    ) external pure override returns (bytes32) {
        return _getDescriptionHash(description_);
    }

    /// @inheritdoc IGrantFundActions
    function getDelegateReward(
        uint24 distributionId_,
        address voter_
    ) external view override returns (uint256 rewards_) {
        DistributionPeriod storage currentDistribution = _distributions[distributionId_];
        VoterInfo          storage voter               = _voterInfo[distributionId_][voter_];

        rewards_ = _getDelegateReward(currentDistribution, voter);
    }

    /// @inheritdoc IGrantFundActions
    function getDistributionId() external view override returns (uint24) {
        return _currentDistributionId;
    }

    /// @inheritdoc IGrantFundActions
    function getDistributionPeriodInfo(
        uint24 distributionId_
    ) external view override returns (uint24, uint48, uint48, uint128, uint256, bytes32) {
        return (
            _distributions[distributionId_].id,
            _distributions[distributionId_].startBlock,
            _distributions[distributionId_].endBlock,
            _distributions[distributionId_].fundsAvailable,
            _distributions[distributionId_].fundingVotePowerCast,
            _distributions[distributionId_].fundedSlateHash
        );
    }

    /// @inheritdoc IGrantFundActions
    function getFundedProposalSlate(
        bytes32 slateHash_
    ) external view override returns (uint256[] memory) {
        return _fundedProposalSlates[slateHash_];
    }

    /// @inheritdoc IGrantFundActions
    function getFundingStageEndBlock(uint256 startBlock_) external pure override returns (uint256) {
        return _getFundingStageEndBlock(startBlock_);
    }

    /// @inheritdoc IGrantFundActions
    function getFundingVotesCast(
        uint24 distributionId_,
        address account_
    ) external view override returns (FundingVoteParams[] memory) {
        return _voterInfo[distributionId_][account_].votesCast;
    }

    /// @inheritdoc IGrantFundActions
    function getHasClaimedRewards(uint256 distributionId_, address account_) external view override returns (bool) {
        return _voterInfo[distributionId_][account_].hasClaimedReward;
    }

    /// @inheritdoc IGrantFundActions
    function getProposalInfo(
        uint256 proposalId_
    ) external view override returns (uint256, uint24, uint128, uint128, int128, bool) {
        return (
            _proposals[proposalId_].proposalId,
            _proposals[proposalId_].distributionId,
            _proposals[proposalId_].votesReceived,
            _proposals[proposalId_].tokensRequested,
            _proposals[proposalId_].fundingVotesReceived,
            _proposals[proposalId_].executed
        );
    }

    /// @inheritdoc IGrantFundActions
    function getScreeningStageEndBlock(uint256 startBlock_) external pure override returns (uint256) {
        return _getScreeningStageEndBlock(startBlock_);
    }

    /// @inheritdoc IGrantFundActions
    function getScreeningVotesCast(uint256 distributionId_, address account_) external view override returns (uint256) {
        return _voterInfo[distributionId_][account_].screeningVotesCast;
    }

    /// @inheritdoc IGrantFundActions
    function getSlateHash(
        uint256[] calldata proposalIds_
    ) external pure override returns (bytes32) {
        return keccak256(abi.encode(proposalIds_));
    }

    /// @inheritdoc IGrantFundActions
    function getStage() external view returns (bytes32 stage_) {
        DistributionPeriod memory currentDistribution = _distributions[_currentDistributionId];
        uint256 startBlock = currentDistribution.startBlock;
        uint256 endBlock = currentDistribution.endBlock;
        uint256 screeningStageEndBlock = _getScreeningStageEndBlock(startBlock);
        uint256 fundingStageEndBlock = _getFundingStageEndBlock(startBlock);

        if (block.number <= screeningStageEndBlock) {
            stage_ = keccak256(bytes("Screening"));
        }
        else if (block.number > screeningStageEndBlock && block.number <= fundingStageEndBlock) {
            stage_ = keccak256(bytes("Funding"));
        }
        else if (block.number > fundingStageEndBlock && block.number <= endBlock) {
            stage_ = keccak256(bytes("Challenge"));
        }
        else {
            // a new distribution period needs to be started
            stage_ = keccak256(bytes("Pending"));
        }
    }

    /// @inheritdoc IGrantFundActions
    function getTopTenProposals(
        uint24 distributionId_
    ) external view override returns (uint256[] memory) {
        return _topTenProposals[distributionId_];
    }

    /// @inheritdoc IGrantFundActions
    function getVoterInfo(
        uint24 distributionId_,
        address account_
    ) external view override returns (uint128, uint128, uint256) {
        return (
            _voterInfo[distributionId_][account_].fundingVotingPower,
            _voterInfo[distributionId_][account_].fundingRemainingVotingPower,
            _voterInfo[distributionId_][account_].votesCast.length
        );
    }

    /// @inheritdoc IGrantFundActions
    function getVotesFunding(
        uint24 distributionId_,
        address account_
    ) external view override returns (uint256 votes_) {
        DistributionPeriod memory currentDistribution = _distributions[distributionId_];
        VoterInfo          memory voter               = _voterInfo[distributionId_][account_];

        uint256 screeningStageEndBlock = _getScreeningStageEndBlock(currentDistribution.startBlock);

        votes_ = _getVotesFunding(account_, voter.fundingVotingPower, voter.fundingRemainingVotingPower, screeningStageEndBlock);
    }

    /// @inheritdoc IGrantFundActions
    function getVotesScreening(
        uint24 distributionId_,
        address account_
    ) external view override returns (uint256 votes_) {
        votes_ = _getVotesScreening(distributionId_, account_);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { IGrantFundState } from "../interfaces/IGrantFundState.sol";

abstract contract Storage is IGrantFundState {

    /*****************/
    /*** Constants ***/
    /*****************/

    /**
     * @notice Maximum percentage of tokens that can be distributed by the treasury in a quarter.
     * @dev Stored as a Wad percentage.
     */
    uint256 internal constant GLOBAL_BUDGET_CONSTRAINT = 0.03 * 1e18;

    /**
     * @notice Length of the challenge phase of the distribution period in blocks.
     * @dev    Roughly equivalent to the number of blocks in 7 days.
     * @dev    The period in which funded proposal slates can be checked in updateSlate.
     */
    uint256 internal constant CHALLENGE_PERIOD_LENGTH = 50_400;

    /**
     * @notice Length of the distribution period in blocks.
     * @dev    Roughly equivalent to the number of blocks in 90 days.
     */
    uint48 internal constant DISTRIBUTION_PERIOD_LENGTH = 648_000;

    /**
     * @notice Length of the funding stage of the distribution period in blocks.
     * @dev    Roughly equivalent to the number of blocks in 10 days.
     */
    uint256 internal constant FUNDING_PERIOD_LENGTH = 72_000;

    /**
     * @notice Length of the screening stage of the distribution period in blocks.
     * @dev    Roughly equivalent to the number of blocks in 73 days.
     */
    uint256 internal constant SCREENING_PERIOD_LENGTH = 525_600;

    /**
     * @notice Number of blocks prior to a given voting stage to check an accounts voting power.
     * @dev    Prevents flashloan attacks or duplicate voting with multiple accounts.
     */
    uint256 internal constant VOTING_POWER_SNAPSHOT_DELAY = 33;

    /***********************/
    /*** State Variables ***/
    /***********************/

    // address of the ajna token used in grant coordination
    address public ajnaTokenAddress = 0x9a96ec9B57Fb64FbC60B423d1f4da7691Bd35079;

    /**
     * @notice ID of the current distribution period.
     * @dev Used to access information on the status of an ongoing distribution.
     * @dev Updated at the start of each quarter.
     * @dev Monotonically increases by one per period.
     */
    uint24 internal _currentDistributionId = 0;

    /**
     * @notice Mapping of distribution periods from the grant fund.
     * @dev distributionId => DistributionPeriod
     */
    mapping(uint24 distributionId => DistributionPeriod) internal _distributions;

    /**
     * @dev Mapping of all proposals that have ever been submitted to the grant fund for screening.
     * @dev proposalId => Proposal
     */
    mapping(uint256 proposalId => Proposal) internal _proposals;

    /**
     * @dev Mapping of distributionId to a sorted array of 10 proposalIds with the most votes in the screening period.
     * @dev distribution.id => proposalId[]
     * @dev A new array is created for each distribution period
     */
    mapping(uint256 distributionId => uint256[] topTenProposals) internal _topTenProposals;

    /**
     * @notice Mapping of a hash of a proposal slate to a list of funded proposals.
     * @dev slate hash => proposalId[]
     */
    mapping(bytes32 slateHash => uint256[] fundedProposalSlate) internal _fundedProposalSlates;

    /**
     * @notice Mapping of distributionId to whether surplus funds from distribution updated into treasury
     * @dev distributionId => bool
    */
    mapping(uint256 distributionId => bool isUpdated) internal _isSurplusFundsUpdated;

    /**
     * @notice Mapping of distributionId to user address to a VoterInfo struct.
     * @dev distributionId => address => VoterInfo
    */
    mapping(uint256 distributionId => mapping(address voter => VoterInfo)) public _voterInfo;

    /**
     * @notice Total funds available for distribution.
    */
    uint256 public treasury;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { IGrantFundActions } from "./IGrantFundActions.sol";
import { IGrantFundErrors }  from "./IGrantFundErrors.sol";
import { IGrantFundEvents }  from "./IGrantFundEvents.sol";

/**
 * @title Grant Fund Interface.
 * @dev   Combines all interfaces into one.
 * @dev   IGrantFundState is inherited through IGrantFundActions.
 */
interface IGrantFund is
    IGrantFundActions,
    IGrantFundErrors,
    IGrantFundEvents
{

}

// SPDX-License-Identifier: MIT

//slither-disable-next-line solc-version
pragma solidity 0.8.18;

import { IGrantFundState } from "./IGrantFundState.sol";

/**
 * @title Grant Fund User Actions.
 */
interface IGrantFundActions is IGrantFundState {

    /*****************************************/
    /*** Distribution Management Functions ***/
    /*****************************************/

    /**
     * @notice Transfers Ajna tokens to the GrantFund contract.
     * @param fundingAmount_ The amount of Ajna tokens to transfer.
     */
    function fundTreasury(uint256 fundingAmount_) external;

    /**
     * @notice Start a new Distribution Period and reset appropriate state.
     * @dev    Can be kicked off by anyone assuming a distribution period isn't already active.
     * @return newDistributionId_ The new distribution period Id.
     */
    function startNewDistributionPeriod() external returns (uint24 newDistributionId_);

    /************************************/
    /*** Delegation Rewards Functions ***/
    /************************************/

    /**
     * @notice distributes delegate reward based on delegatee Vote share.
     * @dev Can be called by anyone who has voted in both screening and funding stages.
     * @param  distributionId_ Id of distribution from which delegatee wants to claim their reward.
     * @return rewardClaimed_  Amount of reward claimed by delegatee.
     */
    function claimDelegateReward(
        uint24 distributionId_
    ) external returns(uint256 rewardClaimed_);

    /**************************/
    /*** Proposal Functions ***/
    /**************************/

    /**
     * @notice Execute a proposal that has been approved by the community.
     * @dev    Calls out to _execute().
     * @dev    Only proposals in the finalized top slate slate at the end of the challenge period can be executed.
     * @param  targets_         List of contracts the proposal calldata will interact with. Should be the Ajna token contract for all proposals.
     * @param  values_          List of values to be sent with the proposal calldata. Should be 0 for all proposals.
     * @param  calldatas_       List of calldata to be executed. Should be the transfer() method.
     * @param  descriptionHash_ Hash of proposal's description string.
     * @return proposalId_      The id of the executed proposal.
     */
     function execute(
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        bytes32 descriptionHash_
    ) external returns (uint256 proposalId_);

    /**
     * @notice Create a proposalId from a hash of proposal's targets, values, and calldatas arrays, and a description hash.
     * @dev    Consistent with proposalId generation methods used in OpenZeppelin Governor.
     * @param targets_         The addresses of the contracts to call.
     * @param values_          The amounts of ETH to send to each target.
     * @param calldatas_       The calldata to send to each target.
     * @param descriptionHash_ The hash of the proposal's description string. Generated by `abi.encode(DESCRIPTION_PREFIX_HASH, keccak256(bytes(description_))`.
     *                         The `DESCRIPTION_PREFIX_HASH` is unique for each funding mechanism: `keccak256(bytes("Standard Funding: "))` for standard funding
     * @return proposalId_     The hashed proposalId created from the provided params.
     */
    function hashProposal(
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        bytes32 descriptionHash_
    ) external pure returns (uint256 proposalId_);

    /**
     * @notice Submit a new proposal to the Grant Coordination Fund Standard Funding mechanism.
     * @dev    All proposals can be submitted by anyone. There can only be one value in each array. Interface is compliant with OZ.propose().
     * @param  targets_     List of contracts the proposal calldata will interact with. Should be the Ajna token contract for all proposals.
     * @param  values_      List of values to be sent with the proposal calldata. Should be 0 for all proposals.
     * @param  calldatas_   List of calldata to be executed. Should be the transfer() method.
     * @param  description_ Proposal's description string.
     * @return proposalId_  The id of the newly created proposal.
     */
    function propose(
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        string memory description_
    ) external returns (uint256 proposalId_);

    /**
     * @notice Find the status of a given proposal.
     * @dev Check proposal status based upon Grant Fund specific logic.
     * @param proposalId_ The id of the proposal to query the status of.
     * @return ProposalState of the given proposal.
     */
    function state(
        uint256 proposalId_
    ) external view returns (ProposalState);

    /**
     * @notice Check if a slate of proposals meets requirements, and maximizes votes. If so, update DistributionPeriod.
     * @param  proposalIds_    Array of proposal Ids to check.
     * @param  distributionId_ Id of the current distribution period.
     * @return newTopSlate_    Boolean indicating whether the new proposal slate was set as the new top slate for distribution.
     */
    function updateSlate(
        uint256[] calldata proposalIds_,
        uint24 distributionId_
    ) external returns (bool newTopSlate_);

    /************************/
    /*** Voting Functions ***/
    /************************/

    /**
     * @notice Cast an array of funding votes in one transaction.
     * @dev    Calls out to StandardFunding._fundingVote().
     * @dev    Only iterates through a maximum of 10 proposals that made it through the screening round.
     * @dev    Counters incremented in an unchecked block due to being bounded by array length.
     * @param voteParams_ The array of votes on proposals to cast.
     * @return votesCast_ The total number of votes cast across all of the proposals.
     */
    function fundingVote(
        FundingVoteParams[] memory voteParams_
    ) external returns (uint256 votesCast_);

    /**
     * @notice Cast an array of screening votes in one transaction.
     * @dev    Calls out to StandardFunding._screeningVote().
     * @dev    Counters incremented in an unchecked block due to being bounded by array length.
     * @param  voteParams_ The array of votes on proposals to cast.
     * @return votesCast_  The total number of votes cast across all of the proposals.
     */
    function screeningVote(
        ScreeningVoteParams[] memory voteParams_
    ) external returns (uint256 votesCast_);

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     * @notice Get the block number at which this distribution period's challenge stage starts.
     * @param  endBlock_ The end block of a distribution period to get the challenge stage start block for.
     * @return The block number at which this distribution period's challenge stage starts.
    */
    function getChallengeStageStartBlock(uint256 endBlock_) external pure returns (uint256);

    /**
     * @notice Retrieve the delegate reward accrued to a voter in a given distribution period.
     * @param  distributionId_ The distributionId to calculate rewards for.
     * @param  voter_          The address of the voter to calculate rewards for.
     * @return rewards_        The rewards earned by the voter for voting in that distribution period.
     */
    function getDelegateReward(
        uint24 distributionId_,
        address voter_
    ) external view returns (uint256 rewards_);

    /**
     * @notice Calculate the description hash of a proposal.
     * @dev    The description hash is used as a unique identifier for a proposal. It is created by hashing the description string with a prefix.
     * @param  description_ The proposal's description string.
     * @return              The hash of the proposal's prefix and description string.
     */
    function getDescriptionHash(string memory description_) external pure returns (bytes32);

    /**
     * @notice Retrieve the current DistributionPeriod distributionId.
     * @return The current distributionId.
     */
    function getDistributionId() external view returns (uint24);

    /**
     * @notice Mapping of distributionId to {DistributionPeriod} struct.
     * @param  distributionId_      The distributionId to retrieve the DistributionPeriod struct for.
     * @return distributionId       The retrieved struct's distributionId.
     * @return startBlock           The block number of the distribution period's start.
     * @return endBlock             The block number of the distribution period's end.
     * @return fundsAvailable       The maximum amount of funds that can be taken out of the distribution period.
     * @return fundingVotePowerCast The total number of votes cast in the distribution period's funding round.
     * @return fundedSlateHash      The slate hash of the proposals that were funded.
     */
    function getDistributionPeriodInfo(
        uint24 distributionId_
    ) external view returns (uint24, uint48, uint48, uint128, uint256, bytes32);

    /**
     * @notice Get the funded proposal slate for a given distributionId, and slate hash
     * @param  slateHash_      The slateHash to retrieve the funded proposals from.
     * @return                 The array of proposalIds that are in the funded slate hash.
     */
    function getFundedProposalSlate(
        bytes32 slateHash_
    ) external view returns (uint256[] memory);

    /**
     * @notice Get the block number at which this distribution period's funding stage ends.
     * @param  startBlock_ The end block of a distribution period to get the funding stage end block for.
     * @return The block number at which this distribution period's funding stage ends.
    */
    function getFundingStageEndBlock(uint256 startBlock_) external pure returns (uint256);

    /**
     * @notice Get the list of funding votes cast by an account in a given distribution period.
     * @param  distributionId_   The distributionId of the distribution period to check.
     * @param  account_          The address of the voter to check.
     * @return FundingVoteParams The list of FundingVoteParams structs that have been successfully cast the voter.
     */
    function getFundingVotesCast(uint24 distributionId_, address account_) external view returns (FundingVoteParams[] memory);

    /**
     * @notice Get the reward claim status of an account in a given distribution period.
     * @param  distributionId_ The distributionId of the distribution period to check.
     * @param  account_        The address of the voter to check.
     * @return                 The reward claim status of the account in the distribution period.
     */
    function getHasClaimedRewards(uint256 distributionId_, address account_) external view returns (bool);

    /**
     * @notice Mapping of proposalIds to {Proposal} structs.
     * @param  proposalId_          The proposalId to retrieve the Proposal struct for.
     * @return proposalId           The retrieved struct's proposalId.
     * @return distributionId       The distributionId in which the proposal was submitted.
     * @return votesReceived        The amount of votes the proposal has received in its distribution period's screening round.
     * @return tokensRequested      The amount of tokens requested by the proposal.
     * @return fundingVotesReceived The amount of funding votes cast on the proposal in its distribution period's funding round.
     * @return executed             True if the proposal has been executed.
     */
    function getProposalInfo(
        uint256 proposalId_
    ) external view returns (uint256, uint24, uint128, uint128, int128, bool);

    /**
     * @notice Get the block number at which this distribution period's screening stage ends.
     * @param  startBlock_ The start block of a distribution period to get the screening stage end block for.
     * @return The block number at which this distribution period's screening stage ends.
    */
    function getScreeningStageEndBlock(uint256 startBlock_) external pure returns (uint256);

    /**
     * @notice Get the number of screening votes cast by an account in a given distribution period.
     * @param  distributionId_ The distributionId of the distribution period to check.
     * @param  account_        The address of the voter to check.
     * @return                 The number of screening votes successfully cast the voter.
     */
    function getScreeningVotesCast(uint256 distributionId_, address account_) external view returns (uint256);

    /**
     * @notice Generate a unique hash of a list of proposal Ids for usage as a key for comparing proposal slates.
     * @param  proposalIds_ Array of proposal Ids to hash.
     * @return Bytes32      Hash of the list of proposals.
     */
    function getSlateHash(
        uint256[] calldata proposalIds_
    ) external pure returns (bytes32);

    /**
     * @notice Retrieve a bytes32 hash of the current distribution period stage.
     * @dev    Used to check if the distribution period is in the screening, funding, or challenge stages.
     * @return stage_ The hash of the current distribution period stage.
     */
    function getStage() external view returns (bytes32 stage_);

    /**
     * @notice Retrieve the top ten proposals that have received the most votes in a given distribution period's screening round.
     * @dev    It may return less than 10 proposals if less than 10 have been submitted. 
     * @dev    Values are subject to change if the queried distribution period's screening round is ongoing.
     * @param  distributionId_ The distributionId of the distribution period to query.
     * @return topTenProposals Array of the top ten proposal's proposalIds.
     */
    function getTopTenProposals(
        uint24 distributionId_
    ) external view returns (uint256[] memory);

    /**
     * @notice Get the current state of a given voter in the funding stage.
     * @param  distributionId_ The distributionId of the distribution period to check.
     * @param  account_        The address of the voter to check.
     * @return votingPower          The voter's voting power in the funding round. Equal to the square of their tokens in the voting snapshot.
     * @return remainingVotingPower The voter's remaining quadratic voting power in the given distribution period's funding round.
     * @return votesCast            The voter's number of proposals voted on in the funding stage.
     */
    function getVoterInfo(
        uint24 distributionId_,
        address account_
    ) external view returns (uint128, uint128, uint256);

    /**
     * @notice Get the remaining quadratic voting power available to the voter in the funding stage of a distribution period.
     * @dev    This value will be the square of the voter's token balance at the snapshot blocks.
     * @param  distributionId_ The distributionId of the distribution period to check.
     * @param  account_        The address of the voter to check.
     * @return votes_          The voter's remaining quadratic voting power.
     */
    function getVotesFunding(uint24 distributionId_, address account_) external view returns (uint256 votes_);

    /**
     * @notice Get the voter's voting power in the screening stage of a distribution period.
     * @param  distributionId_ The distributionId of the distribution period to check.
     * @param  account_        The address of the voter to check.
     * @return votes_           The voter's voting power.
     */
    function getVotesScreening(uint24 distributionId_, address account_) external view returns (uint256 votes_);
}

// SPDX-License-Identifier: MIT

//slither-disable-next-line solc-version
pragma solidity 0.8.18;

/**
 * @title Grant Fund Errors.
 */
interface IGrantFundErrors {

    /**************/
    /*** Errors ***/
    /**************/

    /**
     * @notice Voter has already voted on a proposal in the screening stage in a quarter.
     */
    error AlreadyVoted();

    /**
     * @notice User attempted to start a new distribution or claim delegation rewards before the distribution period ended.
     */
     error DistributionPeriodStillActive();

    /**
     * @notice Delegatee attempted to claim delegate rewards when they didn't vote in both stages.
     */
    error DelegateRewardInvalid();

    /**
     * @notice User attempted to execute a proposal before the distribution period ended.
     */
     error ExecuteProposalInvalid();

    /**
     * @notice User attempted to change the direction of a subsequent funding vote on the same proposal.
     */
    error FundingVoteWrongDirection();

    /**
     * @notice User attempted to vote with more voting power than was available to them.
     */
    error InsufficientVotingPower();

    /**
     * @notice Voter does not have enough voting power remaining to cast the vote.
     */
    error InsufficientRemainingVotingPower();

    /**
     * @notice User submitted a proposal with invalid parameters.
     * @dev    A proposal is invalid if it has a mismatch in the number of targets, values, or calldatas.
     * @dev    It is also invalid if it's calldata selector doesn't equal transfer().
     */
    error InvalidProposal();

    /**
     * @notice User provided a slate of proposalIds that is invalid.
     */
    error InvalidProposalSlate();

    /**
     * @notice User attempted to cast an invalid vote (outside of the distribution period, ).
     * @dev    This error is thrown when the user attempts to vote outside of the allowed period, vote with 0 votes, or vote with more than their voting power.
     */
    error InvalidVote();

    /**
     * @notice User attempted to submit a duplicate proposal.
     */
    error ProposalAlreadyExists();

    /**
     * @notice Proposal didn't meet requirements for execution.
     */
    error ProposalNotSuccessful();

    /**
     * @notice User attempted to Claim delegate reward again
     */
    error RewardAlreadyClaimed();

    /**
     * @notice User attempted to propose after screening period ended
     */
    error ScreeningPeriodEnded();

}

// SPDX-License-Identifier: MIT

//slither-disable-next-line solc-version
pragma solidity 0.8.18;

/**
 * @title Grant Fund Events.
 */
interface IGrantFundEvents {

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @notice Emitted when a new top ten slate is submitted and set as the leading optimized slate.
     *  @param  distributionId  Id of the distribution period.
     *  @param  fundedSlateHash Hash of the proposals to be funded.
     */
    event FundedSlateUpdated(
        uint256 indexed distributionId,
        bytes32 indexed fundedSlateHash
    );

    /**
     *  @notice Emitted at the beginning of a new distribution period.
     *  @param  distributionId Id of the new distribution period.
     *  @param  startBlock     Block number of the distribution period start.
     *  @param  endBlock       Block number of the distribution period end.
     */
    event DistributionPeriodStarted(
        uint256 indexed distributionId,
        uint256 startBlock,
        uint256 endBlock
    );

    /**
     *  @notice Emitted when delegatee claims their rewards.
     *  @param  delegateeAddress Address of delegatee.
     *  @param  distributionId   Id of distribution period.
     *  @param  rewardClaimed    Amount of Reward Claimed.
     */
    event DelegateRewardClaimed(
        address indexed delegateeAddress,
        uint256 indexed distributionId,
        uint256 rewardClaimed
    );

    /**
     *  @notice Emitted when Ajna tokens are transferred to the GrantFund contract.
     *  @param  amount          Amount of Ajna tokens transferred.
     *  @param  treasuryBalance GrantFund's total treasury balance after the transfer.
     */
    event FundTreasury(uint256 amount, uint256 treasuryBalance);

    /**
     * @notice Emitted when a proposal is executed.
     * @dev Compatibile with interface used by Compound Governor Bravo and OpenZeppelin Governor.
     * @param proposalId Id of the proposal executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @notice Emitted when a proposal is created.
     * @dev Compatibile with interface used by Compound Governor Bravo and OpenZeppelin Governor.
     * @param proposalId  Id of the proposal created.
     * @param proposer    Address of the proposer.
     * @param targets     List of addresses of the contracts called by proposal's associated transactions.
     * @param values      List of values in wei for each proposal's associated transaction.
     * @param signatures  List of function signatures (can be empty) of the proposal's associated transactions.
     * @param calldatas   List of calldatas: calldata format is [functionId (4 bytes)][packed arguments (32 bytes per argument)].
     *                    Calldata is always transfer(address,uint256) for Ajna distribution proposals.
     * @param startBlock  Block number when the distribution period and screening stage begins:
     *                    holders must delegate their votes for the period 34 prior to this block to vote in the screening stage.
     * @param endBlock    Block number when the distribution period ends.
     * @param description Description of the proposal.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /**
     * @notice Emitted when votes are cast on a proposal.
     * @dev Compatibile with interface used by Compound Governor Bravo and OpenZeppelin Governor.
     * @param voter      Address of the voter.
     * @param proposalId Id of the proposal voted on.
     * @param support    Indicates if the voter supports the proposal (0=against, 1=for).
     * @param weight     Amount of votes cast on the proposal.
     * @param reason     Reason given by the voter for or against the proposal.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);
}

// SPDX-License-Identifier: MIT

//slither-disable-next-line solc-version
pragma solidity 0.8.18;

/**
 * @title Grant Fund State.
 */
interface IGrantFundState {

    /*************/
    /*** Enums ***/
    /*************/

    /**
     * @notice Enum listing a proposal's lifecycle.
     * @dev Compatibile with interface used by Compound Governor Bravo and OpenZeppelin Governor.
     * @dev Returned in `state()` function.
     * @param Pending   N/A for Ajna. Maintained for compatibility purposes.
     * @param Active    Block number is still within a proposal's distribution period, and the proposal hasn't yet been finalized.
     * @param Canceled  N/A for Ajna. Maintained for compatibility purposes.
     * @param Defeated  Proposal wasn't finalized.
     * @param Succeeded Proposal was succesfully voted on and finalized, and can be executed at will.
     * @param Queued    N/A for Ajna. Maintained for compatibility purposes.
     * @param Expired   N/A for Ajna. Maintained for compatibility purposes.
     * @param Executed  Proposal was executed.
     */
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /***************/
    /*** Structs ***/
    /***************/

    /**
     * @notice Contains proposals that made it through the screening process to the funding stage.
     * @param id                   Id of the current distribution period.
     * @param startBlock           Block number of the distribution period's start.
     * @param endBlock             Block number of the distribution period's end.
     * @param fundsAvailable       Maximum fund (including delegate reward) that can be taken out that period.
     * @param fundingVotePowerCast Total number of voting power allocated in funding stage that period.
     * @param fundedSlateHash      Hash of leading slate of proposals to fund.
     */
    struct DistributionPeriod {
        uint24  id;
        uint48  startBlock;
        uint48  endBlock;
        uint128 fundsAvailable;
        uint256 fundingVotePowerCast;
        bytes32 fundedSlateHash;
    }

    /**
     * @notice Contains information about proposals in a distribution period.
     * @param proposalId           OZ.Governor compliant proposalId. Hash of propose() inputs.
     * @param distributionId       Id of the distribution period in which the proposal was made.
     * @param executed             Whether the proposal has been executed.
     * @param votesReceived        Accumulator of screening votes received by a proposal.
     * @param tokensRequested      Number of Ajna tokens requested by the proposal.
     * @param fundingVotesReceived Accumulator of funding votes allocated to the proposal.
     */
    struct Proposal {
        uint256 proposalId;
        uint24  distributionId;
        bool    executed;
        uint128 votesReceived;
        uint128 tokensRequested;
        int128  fundingVotesReceived;
    }

    /**
     * @notice Contains information about voters during a vote made by a QuadraticVoter in the Funding stage of a distribution period.
     * @dev    Used in fundingVote().
     * @param proposalId Id of the proposal being voted on.
     * @param votesUsed  Number of votes allocated to the proposal.
     */
    struct FundingVoteParams {
        uint256 proposalId;
        int256 votesUsed;
    }

    /**
     * @notice Contains information about voters during a vote made during the Screening stage of a distribution period.
     * @dev    Used in screeningVote().
     * @param proposalId Id of the proposal being voted on.
     * @param votes      Number of votes allocated to the proposal.
     */
    struct ScreeningVoteParams {
        uint256 proposalId;
        uint256 votes;
    }

    /**
     * @notice Contains information about voters during a distribution period's funding stage.
     * @dev    Used in `fundingVote()`, and `claimDelegateReward()`.
     * @param fundingVotingPower          Amount of votes originally available to the voter, equal to the sum of the square of their initial votes.
     * @param fundingRemainingVotingPower Remaining voting power in the given period.
     * @param votesCast                   Array of votes cast by the voter.
     * @param screeningVotesCast          Number of screening votes cast by the voter.
     * @param hasClaimedReward            Whether the voter has claimed their reward for the given period.
     */
    struct VoterInfo {
        uint128 fundingVotingPower;
        uint128 fundingRemainingVotingPower;
        FundingVoteParams[] votesCast;
        uint248 screeningVotesCast;
        bool hasClaimedReward;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { SafeCast }  from "@oz/utils/math/SafeCast.sol";

/**
    @title  Maths library
    @notice Internal library containing helpful math utility functions.
 */
library Maths {

    /*****************/
    /*** Constants ***/
    /*****************/

    uint256 internal constant WAD = 10**18;

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    /**
     * @notice Returns the absolute value of a number.
     * @param x Number to return the absolute value of.
     * @return z Absolute value of the number.
     */
    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? SafeCast.toUint256(x) : SafeCast.toUint256(-x);
    }

    /**
     * @notice Returns the result of multiplying two numbers.
     * @param x First number, WAD.
     * @param y Second number, WAD.
     * @return z Result of multiplication, as a WAD.
     */
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y + WAD / 2) / WAD;
    }

    /**
     * @notice Returns the result of dividing two numbers.
     * @param x First number, WAD.
     * @param y Second number, WAD.
     * @return z Result of division, as a WAD.
     */
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * WAD + y / 2) / y;
    }

    /**
     * @notice Returns the minimum of two numbers.
     * @param x First number.
     * @param y Second number.
     * @return z Minimum number.
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    /**
     * @notice Raises a WAD to the power of an integer and returns a WAD
     * @param x WAD to raise to a power.
     * @param n Integer power to raise WAD to.
     * @return z Squared number as a WAD.
     */
    function wpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : WAD;

        for (n /= 2; n != 0; n /= 2) {
            x = wmul(x, x);

            if (n % 2 != 0) {
                z = wmul(z, x);
            }
        }
    }

}