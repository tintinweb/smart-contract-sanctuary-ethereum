// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./../utils/Governable.sol";
import "./../interfaces/utils/IRegistry.sol";
import "./../interfaces/native/IUnderwritingLocker.sol";
import "./../interfaces/native/IUnderwritingLockVoting.sol";
import "./../interfaces/native/IGaugeController.sol";

/**
 * @title UnderwritingLockVoting
 * @author solace.fi
 * @notice Enables individual votes in Solace Native insurance gauges for owners of [`UnderwritingLocker`](./UnderwritingLocker).
 *
 * Any address owning an underwriting lock can vote and will have a votePower that can be viewed with [`getVotePower()`](#getVotePower)
 * An address' vote power is the sum of the vote power of its owned locks.
 * A lock's vote power scales linearly with locked amount, and through a sqrt formula with lock duration
 * Users cannot view the vote power of an individual lock through this contract, only the total vote power of an address.
 * This is an intentional design choice to abstract locks away from address-based voting.
 *
 * Voters can set a delegate who can vote on their behalf via [`setDelegate()`](#setDelegate).
 *
 * To cast a vote, either the voter or their delegate can call [`vote()`](#vote) or [`voteMultiple()`](#voteMultiple).
 * Votes can be cast among existing gaugeIDs (set in GaugeController.sol), and voters/delegates can set a custom proportion
 * of their total voting power for different gauges.
 * Voting power proportion is measured in bps, and total used voting power bps for a voter cannot exceed 10000.
 *
 * Votes are saved, so a vote today will count as the voter's vote for all future epochs until the voter modifies their votes.
 *
 * After each epoch (one-week) has passed, voting is frozen until governance has processed all the votes.
 * This is a two-step process:
 * GaugeController.updateGaugeWeights() - this will aggregate individual votes and update gauge weights accordingly
 * [`chargePremiums()`](#chargepremiums) - this will charge premiums for every vote. There is a voting premium
 * to be paid every epoch, this gets sent to the revenue router.
 */
contract UnderwritingLockVoting is
        IUnderwritingLockVoting,
        ReentrancyGuard,
        Governable
    {
    using EnumerableSet for EnumerableSet.AddressSet;

    /***************************************
    GLOBAL PUBLIC VARIABLES
    ***************************************/

    /// @notice Revenue router address (Voting premiums will be transferred here).
    address public override revenueRouter;

    /// @notice Address of [`UnderwritingLocker`](./UnderwritingLocker).
    address public override underwritingLocker;

    /// @notice Address of [`GaugeController`](./GaugeController).
    address public override gaugeController;

    /// @notice Address of [`BribeController`](./BribeController).
    address public override bribeController;

    /// @notice Registry address
    address public override registry;

    /// @notice Updater address.
    /// @dev Second address that can call chargePremiums (in addition to governance).
    address public override updater;

    /// @notice End timestamp for last epoch that premiums were charged for all stored votes.
    uint256 public override lastTimePremiumsCharged;

    /// @notice voter => delegate.
    mapping(address => address) public override delegateOf;

    /// @notice voter => used voting power percentage (max of 10000 bps).
    mapping(address => uint256) public override usedVotePowerBPSOf;

    /***************************************
    GLOBAL INTERNAL VARIABLES
    ***************************************/

    uint256 constant internal YEAR = 31536000;

    /// @notice Total premium due to the revenueRouter.
    /// @dev Avoid this storage slot being 0, avoid SSTORE cost from 0 to nonzero value.
    uint256 internal _totalPremiumDue;

    /// @notice voter => last processed vote power.
    /// @dev Cache for getVotePower() result for most recent GaugeController.updateGaugeWeights() call.
    mapping (address => uint256) internal _lastProcessedVotePowerOf;

    /// @notice State of last [`chargePremiums()`](#chargepremiums) call.
    GaugeStructs.UpdateInfo internal _updateInfo;

    /// @notice delegate => voters.
    mapping(address => EnumerableSet.AddressSet) internal _votingDelegatorsOf;

    /***************************************
    CONSTRUCTOR
    ***************************************/

    /**
     * @notice Constructs the UnderwritingLockVoting contract.
     * @dev Requires 'uwe', 'revenueRouter', 'underwritingLocker' and 'gaugeController' addresses to be set in the Registry.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param registry_ The [`Registry`](./Registry) contract address.
     */
    constructor(address governance_, address registry_) Governable(governance_) {
        _setRegistry(registry_);
        // Initialize as non-zero storage slots.
        _totalPremiumDue = type(uint256).max;
        _clearUpdateInfo();
    }

    /***************************************
    INTERNAL VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Get vote power for a lock.
     * @dev Need try-catch block, otherwise revert for burned lock will deadlock updateGaugeWeight() call.
     * @param lockID_ The ID of the lock to query.
     * @return votePower
     */
    function _getVotePowerOfLock(uint256 lockID_) internal view returns (uint256 votePower) {
        try IUnderwritingLocker(underwritingLocker).locks(lockID_) returns (Lock memory lock) {
            return ( lock.amount * IUnderwritingLocker(underwritingLocker).getLockMultiplier(lockID_) ) / 1e18;
        } catch {
            return 0;
        }
    }

    /**
     * @notice Get timestamp for the start of the current epoch.
     * @return timestamp
     */
    function _getEpochStartTimestamp() internal view returns (uint256 timestamp) {
        return IGaugeController(gaugeController).getEpochStartTimestamp();
    }

    /**
     * @notice Get timestamp for end of the current epoch.
     * @return timestamp
     */
    function _getEpochEndTimestamp() internal view returns (uint256 timestamp) {
        return IGaugeController(gaugeController).getEpochEndTimestamp();
    }

    /**
     * @notice Get end timestamp for last epoch that all stored votes were processed.
     * @return timestamp
     */
    function _getLastTimeGaugesUpdated() internal view returns (uint256 timestamp) {
        return IGaugeController(gaugeController).lastTimeGaugeWeightsUpdated();
    }

    /**
     * @notice Query whether msg.sender is either the governance or updater role.
     * @return True if msg.sender is either governor or updater roler, and contract govenance is not locked, false otherwise.
     */
    function _isUpdaterOrGovernance() internal view returns (bool) {
        return ( !this.governanceIsLocked() && ( msg.sender == updater || msg.sender == this.governance() ));
    }

    /***************************************
    EXTERNAL VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Get vote power for a voter.
     * @param voter_ The address of the voter to query.
     * @return votePower
     */
    function getVotePower(address voter_) external view override returns (uint256 votePower) {
        uint256[] memory lockIDs = IUnderwritingLocker(underwritingLocker).getAllLockIDsOf(voter_);
        uint256 numVoterLocks = lockIDs.length;
        for (uint256 i = 0; i < numVoterLocks; i++) {votePower += _getVotePowerOfLock(lockIDs[i]);}
    }

    /**
     * @notice Get all current votes for a voter.
     * @param voter_ Address of voter to query for.
     * @return votes Array of Vote{gaugeID, votePowerBPS}.
     */
    function getVotes(address voter_) external view override returns (GaugeStructs.Vote[] memory votes) {
        return IGaugeController(gaugeController).getVotes(address(this), voter_);
    }

    /**
     * @notice Get timestamp for the start of the current epoch.
     * @return timestamp
     */
    function getEpochStartTimestamp() external view override returns (uint256 timestamp) {
        return _getEpochStartTimestamp();
    }

    /**
     * @notice Get timestamp for end of the current epoch.
     * @return timestamp
     */
    function getEpochEndTimestamp() external view override returns (uint256 timestamp) {
        return _getEpochEndTimestamp();
    }

    /**
     * @notice Query whether voting is currently open.
     * @return True if voting is open for this epoch, false otherwise.
     */
    function isVotingOpen() external view override returns (bool) {
        uint256 epochStartTime = _getEpochStartTimestamp();
        return epochStartTime == lastTimePremiumsCharged && epochStartTime == _getLastTimeGaugesUpdated();
    }

    /**
     * @notice Get array of voters who have delegated their vote to a given address.
     * @param delegate_ Address to query array of voting delegators for.
     * @return votingDelegators Array of voting delegators.
     */
    function getVotingDelegatorsOf(address delegate_) external view override returns (address[] memory votingDelegators) {
        uint256 length = _votingDelegatorsOf[delegate_].length();
        votingDelegators = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            votingDelegators[i] = _votingDelegatorsOf[delegate_].at(i);
        }
    }

    /**
     * @notice Get last processed vote power for given voter.
     * @param voter_ Address of voter to query for.
     * @return lastProcessedVotePower
     */
    function getLastProcessedVotePowerOf(address voter_) external view override returns (uint256 lastProcessedVotePower) {
        return _lastProcessedVotePowerOf[voter_];
    }

    /***************************************
    INTERNAL MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Set the voting delegate for the caller.
     * To remove a delegate, the delegate can be set to the ZERO_ADDRESS - 0x0000000000000000000000000000000000000000
     * @param delegate_ Address of intended delegate
     */
    function _setDelegate(address delegate_) internal {
        address oldDelegate = delegateOf[msg.sender];
        if (oldDelegate != address(0)) _votingDelegatorsOf[oldDelegate].remove(msg.sender);
        if (delegate_ != address(0)) _votingDelegatorsOf[delegate_].add(msg.sender);
        delegateOf[msg.sender] = delegate_;
        emit DelegateSet(msg.sender, delegate_);
    }

    /**
     * @notice Sets registry and related contract addresses.
     * @dev Requires 'uwe', 'revenueRouter' and 'underwritingLocker' addresses to be set in the Registry.
     * @param _registry The registry address to set.
     */
    function _setRegistry(address _registry) internal {
        if(_registry == address(0x0)) revert ZeroAddressInput("registry");
        registry = _registry;
        IRegistry reg = IRegistry(_registry);
        // set revenueRouter
        (, address revenueRouterAddr) = reg.tryGet("revenueRouter");
        if(revenueRouterAddr == address(0x0)) revert ZeroAddressInput("revenueRouter");
        revenueRouter = revenueRouterAddr;
        // set underwritingLocker
        (, address underwritingLockerAddr) = reg.tryGet("underwritingLocker");
        if(underwritingLockerAddr == address(0x0)) revert ZeroAddressInput("underwritingLocker");
        underwritingLocker = underwritingLockerAddr;
        // set gaugeController
        (, address gaugeControllerAddr) = reg.tryGet("gaugeController");
        if(gaugeControllerAddr == address(0x0)) revert ZeroAddressInput("gaugeController");
        gaugeController = gaugeControllerAddr;
        emit RegistrySet(_registry);
    }

    /**
     * @notice Add, change or remove votes.
     * Can only be called by the voter or their delegate.
     * @param voter_ The voter address.
     * @param gaugeIDs_ The array of gaugeIDs to vote for.
     * @param votePowerBPSs_ The corresponding array of votePowerBPS values. Can be from 0-10000.
     */
    function _vote(address voter_, uint256[] memory gaugeIDs_, uint256[] memory votePowerBPSs_) internal {
        // Disable voting if votes not yet processed or premiums not yet charged for this epoch
        if ( _getEpochStartTimestamp() != lastTimePremiumsCharged) revert LastEpochPremiumsNotCharged();
        if( voter_ != msg.sender && delegateOf[voter_] != msg.sender && bribeController != msg.sender) revert NotOwnerNorDelegate();
        if (gaugeIDs_.length != votePowerBPSs_.length) revert ArrayArgumentsLengthMismatch();

        for(uint256 i = 0; i < gaugeIDs_.length; i++) {
            uint256 gaugeID = gaugeIDs_[i];
            uint256 votePowerBPS = votePowerBPSs_[i];
            if (votePowerBPS > 10000) revert SingleVotePowerBPSOver10000();

            // If remove vote
            if ( votePowerBPS == 0 ) {
                uint256 oldVotePowerBPS = IGaugeController(gaugeController).vote(voter_, gaugeID, votePowerBPS);
                usedVotePowerBPSOf[voter_] -= oldVotePowerBPS;
                emit VoteRemoved(voter_, gaugeID);
            } else {
                uint256 oldVotePowerBPS = IGaugeController(gaugeController).vote(voter_, gaugeID, votePowerBPS);
                // Add vote
                if (oldVotePowerBPS == 0) {
                    usedVotePowerBPSOf[voter_] += votePowerBPS;
                    emit VoteAdded(voter_, gaugeID, votePowerBPS);
                // Else modify vote
                } else {
                    usedVotePowerBPSOf[voter_] += votePowerBPS;
                    usedVotePowerBPSOf[voter_] -= oldVotePowerBPS;
                    emit VoteChanged(voter_, gaugeID, votePowerBPS, oldVotePowerBPS);
                }
            }
        }

        if (usedVotePowerBPSOf[voter_] > 10000) revert TotalVotePowerBPSOver10000();
    }

    /***************************************
    EXTERNAL MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Register a single vote for a gauge. Can either add or change a vote.
     * @notice Can also remove a vote (votePowerBPS_ == 0), the difference with removeVote() is that
     * vote() will revert if the voter has no locks (no locks => no right to vote, but may have votes from
     * locks that have since been burned).
     * @notice GaugeController.updateGaugeWeights() will remove voters with no voting power, however voters can
     * preemptively 'clean' the system.
     * @notice Votes are frozen after the end of every epoch, and resumed when all stored votes have been processed.
     * Can only be called by the voter or vote delegate.
     * @param voter_ The voter address.
     * @param gaugeID_ The ID of the gauge to vote for.
     * @param votePowerBPS_ Vote power BPS to assign to this vote
     */
    function vote(address voter_, uint256 gaugeID_, uint256 votePowerBPS_) external override {
        if ( IUnderwritingLocker(underwritingLocker).balanceOf(voter_) == 0 ) revert VoterHasNoLocks();
        uint256[] memory gaugeIDs_ = new uint256[](1);
        uint256[] memory votePowerBPSs_ = new uint256[](1);
        gaugeIDs_[0] = gaugeID_;
        votePowerBPSs_[0] = votePowerBPS_;
        _vote(voter_, gaugeIDs_, votePowerBPSs_);
    }

    /**
     * @notice Register multiple gauge votes.
     * Can only be called by the voter or vote delegate.
     * @param voter_ The voter address.
     * @param gaugeIDs_ Array of gauge IDs to vote for.
     * @param votePowerBPSs_ Array of corresponding vote power BPS values.
     */
    function voteMultiple(address voter_, uint256[] memory gaugeIDs_, uint256[] memory votePowerBPSs_) external override {
        if ( IUnderwritingLocker(underwritingLocker).balanceOf(voter_) == 0 ) revert VoterHasNoLocks();
        _vote(voter_, gaugeIDs_, votePowerBPSs_);
    }

    /**
     * @notice Register a single voting configuration for multiple voters.
     * Can only be called by the voter or vote delegate.
     * @param voters_ Array of voters.
     * @param gaugeIDs_ Array of gauge IDs to vote for.
     * @param votePowerBPSs_ Array of corresponding vote power BPS values.
     */
    function voteForMultipleVoters(address[] calldata voters_, uint256[] memory gaugeIDs_, uint256[] memory votePowerBPSs_) external override {
        uint256 length = voters_.length;
        for (uint256 i = 0; i < length; i++) {
            if ( IUnderwritingLocker(underwritingLocker).balanceOf(voters_[i]) == 0 ) revert VoterHasNoLocks();
            _vote(voters_[i], gaugeIDs_, votePowerBPSs_);
        }
    }

    /**
     * @notice Removes a vote.
     * @notice Votes cannot be removed while voting is frozen.
     * Can only be called by the voter or vote delegate.
     * @param voter_ The voter address.
     * @param gaugeID_ The ID of the gauge to remove vote for.
     */
    function removeVote(address voter_, uint256 gaugeID_) external override {
        uint256[] memory gaugeIDs_ = new uint256[](1);
        uint256[] memory votePowerBPSs_ = new uint256[](1);
        gaugeIDs_[0] = gaugeID_;
        votePowerBPSs_[0] = 0;
        _vote(voter_, gaugeIDs_, votePowerBPSs_);
    }

    /**
     * @notice Remove multiple gauge votes.
     * @notice Votes cannot be removed while voting is frozen.
     * Can only be called by the voter or vote delegate.
     * @param voter_ The voter address.
     * @param gaugeIDs_ Array of gauge IDs to remove votes for.
     */
    function removeVoteMultiple(address voter_, uint256[] memory gaugeIDs_) external override {
        uint256[] memory votePowerBPSs_ = new uint256[](gaugeIDs_.length);
        for(uint256 i = 0; i < gaugeIDs_.length; i++) {votePowerBPSs_[i] = 0;}
        _vote(voter_, gaugeIDs_, votePowerBPSs_);
    }

    /**
     * @notice Remove gauge votes for multiple voters.
     * @notice Votes cannot be removed while voting is frozen.
     * Can only be called by the voter or vote delegate.
     * @param voters_ Array of voter addresses.
     * @param gaugeIDs_ Array of gauge IDs to remove votes for.
     */
    function removeVotesForMultipleVoters(address[] calldata voters_, uint256[] memory gaugeIDs_) external override {
        uint256 length = voters_.length;
        uint256[] memory votePowerBPSs_ = new uint256[](gaugeIDs_.length);
        for(uint256 i = 0; i < gaugeIDs_.length; i++) {votePowerBPSs_[i] = 0;}
        for (uint256 i = 0; i < length; i++) {
            _vote(voters_[i], gaugeIDs_, votePowerBPSs_);
        }
    }

    /**
     * @notice Set the voting delegate for the caller.
     * To remove a delegate, the delegate can be set to the ZERO_ADDRESS - 0x0000000000000000000000000000000000000000.
     * @param delegate_ Address of intended delegate
     */
    function setDelegate(address delegate_) external override {
        _setDelegate(delegate_);
    }

    /***************************************
    GAUGE CONTROLLER FUNCTIONS
    ***************************************/

    /**
     * @notice Cache last processed vote power for a voter.
     * @dev Can only be called by the gaugeController contract.
     * @dev Assist gas efficiency of chargePremiums().
     * @param voter_ Address of voter.
     * @param votePower_ Vote power.
     */
    function cacheLastProcessedVotePower(address voter_, uint256 votePower_) external override {
        if (msg.sender != gaugeController) revert NotGaugeController();
        _lastProcessedVotePowerOf[voter_] = votePower_;
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [`Registry`](./Registry) contract address.
     * @dev Requires 'uwe', 'revenueRouter' and 'underwritingLocker' addresses to be set in the Registry.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param registry_ The address of `Registry` contract.
     */
    function setRegistry(address registry_) external override onlyGovernance {
        _setRegistry(registry_);
    }

    /**
     * @notice Set updater address.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param updater_ The address of the new updater.
     */
    function setUpdater(address updater_) external override onlyGovernance {
        updater = updater_;
        emit UpdaterSet(updater_);
    }

    /**
     * @notice Sets bribeController as per `bribeController` address stored in Registry.
     * @dev We do not set this in constructor, because we expect BribeController.sol to be deployed after this contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function setBribeController() external override onlyGovernance {
        (, address bribeControllerAddr) = IRegistry(registry).tryGet("bribeController");
        if(bribeControllerAddr == address(0x0)) revert ZeroAddressInput("bribeController");
        bribeController = bribeControllerAddr;
        emit BribeControllerSet(bribeControllerAddr);
    }

    /**
     * @notice Charge premiums for votes.
     * @dev Designed to be called in a while-loop with the condition being `lastTimePremiumsCharged != epochStartTimestamp` and using the maximum custom gas limit.
     * @dev Requires GaugeController.updateGaugeWeights() to be run to completion for the last epoch.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function chargePremiums() external override {
        if (!_isUpdaterOrGovernance()) revert NotUpdaterNorGovernance();
        uint256 epochStartTimestamp = _getEpochStartTimestamp();
        if(_getLastTimeGaugesUpdated() != epochStartTimestamp) revert GaugeWeightsNotYetUpdated();
        if(lastTimePremiumsCharged == epochStartTimestamp) revert LastEpochPremiumsAlreadyProcessed({epochTime: epochStartTimestamp});

        // Single call for universal multipliers in premium computation.
        uint256 insuranceCapacity = IGaugeController(gaugeController).getInsuranceCapacity();
        uint256 votePowerSum = IGaugeController(gaugeController).getVotePowerSum();
        uint256 epochLength = IGaugeController(gaugeController).getEpochLength();

        // Iterate through voters
        address[] memory voters = IGaugeController(gaugeController).getVoters(address(this));
        for(uint256 i = _updateInfo._votersIndex == type(uint88).max ? 0 : _updateInfo._votersIndex ; i < voters.length; i++) {
            // _saveUpdateState(0, i, 0);
            // Short-circuit operator - need at least 30K gas for getVoteCount() call
            if (gasleft() < 40000 || gasleft() < 10000 * IGaugeController(gaugeController).getVoteCount(address(this), voters[i])) {
                return _saveUpdateState(0, i, 0);
            }
            // Unbounded loop since # of votes (gauges) unbounded
            uint256 premium = _calculateVotePremium(voters[i], insuranceCapacity, votePowerSum, epochLength); // 87K gas for 10 votes
            uint256[] memory lockIDs = IUnderwritingLocker(underwritingLocker).getAllLockIDsOf(voters[i]);
            uint256 numLocks = lockIDs.length;

            // Iterate through locks
            // Using _votesIndex as _lockIndex
            // If either votesIndex slot is cleared, or we aren't on the same voter as when we last saved, start from index 0.
            for(uint256 j = _updateInfo._votesIndex == type(uint88).max || i != _updateInfo._votersIndex ? 0 : _updateInfo._votesIndex; j < numLocks; j++) {
                if (gasleft() < 20000) {return _saveUpdateState(0, i, j);}
                // Split premium amongst each lock equally.
                IUnderwritingLocker(underwritingLocker).chargePremium(lockIDs[j], premium / numLocks);
            }

            _totalPremiumDue -= premium;
        }

        SafeERC20.safeTransferFrom(
            IERC20(IUnderwritingLocker(underwritingLocker).token()),
            underwritingLocker,
            revenueRouter,
            type(uint256).max - _totalPremiumDue // Avoid _totalPremiumDue being zero.
        );

        _clearUpdateInfo();
        _totalPremiumDue = type(uint256).max; // Reinitialize _totalPremiumDue.
        lastTimePremiumsCharged = epochStartTimestamp;
        emit AllPremiumsCharged(epochStartTimestamp);
    }

    /***************************************
     updateGaugeWeights() HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Save state of charging premium to _updateInfo
     * @param empty_ Empty index (should be 0).
     * @param votersIndex_ Current index of _voters[votingContractsIndex_].
     * @param lockIndex_ Current index of _votes[votingContractsIndex_][votersIndex_]
     */
    function _saveUpdateState(uint256 empty_, uint256 votersIndex_, uint256 lockIndex_) internal {
        assembly {
            let updateInfo
            updateInfo := or(updateInfo, shr(176, shl(176, empty_))) // [0:80] => empty_
            updateInfo := or(updateInfo, shr(88, shl(168, votersIndex_))) // [80:168] => votersIndex_
            updateInfo := or(updateInfo, shl(168, lockIndex_)) // [168:256] => lockIndex_
            sstore(_updateInfo.slot, updateInfo)
        }
        emit IncompletePremiumsCharge();
    }

    /// @notice Reset _updateInfo to starting state.
    /// @dev Avoid zero-value of storage slot.
    function _clearUpdateInfo() internal {
        uint256 bitmap = type(uint256).max;
        assembly {
            sstore(_updateInfo.slot, bitmap)
        }
    }

    /**
     * @notice Computes voting premium for voter.
     * @param voter_ Address of voter.
     * @param insuranceCapacity_ Solace Native insurance capacity.
     * @param votePowerSum_ Solace Native vote power sum.
     * @return premium Premium for voter.
     */
    function _calculateVotePremium(address voter_, uint256 insuranceCapacity_, uint256 votePowerSum_, uint256 epochLength_) internal view returns (uint256 premium) {
        GaugeStructs.Vote[] memory votes = IGaugeController(gaugeController).getVotes(address(this), voter_);
        uint256 voteCount = votes.length;

        if (voteCount > 0) {
            uint256 accummulator;
            uint256 globalNumerator = _lastProcessedVotePowerOf[voter_] * insuranceCapacity_ * epochLength_;
            // rateOnLine scaled to correct fraction for week => multiply by (WEEK / YEAR) * (1 / 1e18)
            // votePowerBPS scaled to correct fraction => multiply by (1 / 10000)
            uint256 globalDenominator = votePowerSum_ * YEAR * 1e18 * 10000;
            for (uint256 i = 0 ; i < voteCount; i++) {
                accummulator += IGaugeController(gaugeController).getRateOnLineOfGauge(votes[i].gaugeID) * votes[i].votePowerBPS;
            }
            return accummulator * globalNumerator / globalDenominator;
        } else {
            return 0;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./../interfaces/utils/IGovernable.sol";

/**
 * @title Governable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
   * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setpendinggovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./../interfaces/utils/ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
contract Governable is IGovernable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // Governor.
    address private _governance;

    // governance to take over.
    address private _pendingGovernance;

    bool private _locked;

    /**
     * @notice Constructs the governable contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) {
        require(governance_ != address(0x0), "zero address governance");
        _governance = governance_;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MODIFIERS
    ***************************************/

    // can only be called by governor
    // can only be called while unlocked
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    // can only be called by pending governor
    // can only be called while unlocked
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() public view override returns (address) {
        return _governance;
    }

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external override onlyGovernance {
        _pendingGovernance = pendingGovernance_;
        emit GovernancePending(pendingGovernance_);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
     */
    function acceptGovernance() external override onlyPendingGovernance {
        // sanity check against transferring governance to the zero address
        // if someone figures out how to sign transactions from the zero address
        // consider the entirety of ethereum to be rekt
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        // intentionally not using address(0x0), see re-initialization exploit
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IRegistry
 * @author solace.fi
 * @notice Tracks the contracts of the Solaverse.
 *
 * [**Governance**](/docs/protocol/governance) can set the contract addresses and anyone can look them up.
 *
 * A key is a unique identifier for each contract. Use [`get(key)`](#get) or [`tryGet(key)`](#tryget) to get the address of the contract. Enumerate the keys with [`length()`](#length) and [`getKey(index)`](#getkey).
 */
interface IRegistry {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a record is set.
    event RecordSet(string indexed key, address indexed value);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice The number of unique keys.
    function length() external view returns (uint256);

    /**
     * @notice Gets the `value` of a given `key`.
     * Reverts if the key is not in the mapping.
     * @param key The key to query.
     * @param value The value of the key.
     */
    function get(string calldata key) external view returns (address value);

    /**
     * @notice Gets the `value` of a given `key`.
     * Fails gracefully if the key is not in the mapping.
     * @param key The key to query.
     * @param success True if the key was found, false otherwise.
     * @param value The value of the key or zero if it was not found.
     */
    function tryGet(string calldata key) external view returns (bool success, address value);

    /**
     * @notice Gets the `key` of a given `index`.
     * @dev Iterable [1,length].
     * @param index The index to query.
     * @return key The key at that index.
     */
    function getKey(uint256 index) external view returns (string memory key);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets keys and values.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param keys The keys to set.
     * @param values The values to set.
     */
    function set(string[] calldata keys, address[] calldata values) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./../utils/IERC721Enhanced.sol";

/// @dev Defining Lock struct outside of the interface body causes this struct to be visible to contracts that import, but do not inherit, this file. If we otherwise define this struct in the interface body, it is only visible to contracts that both import and inherit this file.
struct Lock {
    uint256 amount;
    uint256 end;
}

/**
 * @title IUnderwritingLocker
 * @author solace.fi
 * @notice Having an underwriting lock is a requirement to vote on Solace Native insurance gauges.
 * To create an underwriting lock, $UWE must be locked for a minimum of 6 months.
 *
 * Locks are ERC721s and can be viewed with [`locks()`](#locks).
 * Each lock has an `amount` of locked $UWE, and an `end` timestamp.
 * Locks have a maximum duration of four years.
 *
 * Users can create locks via [`createLock()`](#createlock) or [`createLockSigned()`](#createlocksigned).
 * Users can deposit more $UWE into a lock via [`increaseAmount()`](#increaseamount), [`increaseAmountSigned()`] (#increaseamountsigned) or [`increaseAmountMultiple()`](#increaseamountmultiple).
 * Users can extend a lock via [`extendLock()`](#extendlock) or [`extendLockMultiple()`](#extendlockmultiple).
 * Users can withdraw from a lock via [`withdraw()`](#withdraw), [`withdrawInPart()`](#withdrawinpart), [`withdrawMultiple()`](#withdrawmultiple) or [`withdrawInPartMultiple()`](#withdrawinpartmultiple).
 *
 * Users and contracts may create a lock for another address.
 * Users and contracts may deposit into a lock that they do not own.
 * A portion (set by the funding rate) of withdraws will be burned. This is to incentivize longer staking periods - withdrawing later than other users will yield more tokens than withdrawing earlier.
 * Early withdrawls will incur an additional burn, which will increase with longer remaining lock duration.
 *
 * Any time a lock is minted, burned or otherwise modified it will notify the listener contracts.
 */
// solhint-disable-next-line contract-name-camelcase
interface IUnderwritingLocker is IERC721Enhanced {

    /***************************************
    CUSTOM ERRORS
    ***************************************/

    /// @notice Thrown when array arguments are mismatched in length (and need to have the same length);
    error ArrayArgumentsLengthMismatch();

    /// @notice Thrown when zero address is given as an argument.
    /// @param contractName Name of contract for which zero address was incorrectly provided.
    error ZeroAddressInput(string contractName);

    /// @notice Thrown when extend or withdraw is attempted by a party that is not the owner nor approved for a lock.
    error NotOwnerNorApproved();

    /// @notice Thrown when create lock is attempted with 0 deposit.
    error CannotCreateEmptyLock();

    /// @notice Thrown when a user attempts to create a new lock, when they already have MAX_NUM_LOCKS locks.
    error CreatedMaxLocks();

    /// @notice Thrown when createLock is attempted with lock duration < 6 months.
    error LockTimeTooShort();

    /// @notice Thrown when createLock or extendLock is attempted with lock duration > 4 years.
    error LockTimeTooLong();

    /// @notice Thrown when extendLock is attempted to shorten the lock duration.
    error LockTimeNotExtended();

    /// @notice Thrown when a withdraw is attempted for an `amount` that exceeds the lock balance.
    error ExcessWithdraw();

    /// @notice Thrown when funding rate is set above 100%
    error FundingRateAboveOne();

    /// @notice Emitted when chargePremium() is not called by the voting contract.
    error NotVotingContract();

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a lock is created.
    event LockCreated(uint256 indexed lockID);

    /// @notice Emitted when a new deposit is made into an existing lock.
    event LockIncreased(uint256 indexed lockID, uint256 newTotalAmount, uint256 depositAmount);

    /// @notice Emitted when a new deposit is made into an existing lock.
    event LockExtended(uint256 indexed lockID, uint256 newEndTimestamp);

    /// @notice Emitted when a lock is updated.
    event LockUpdated(uint256 indexed lockID, uint256 amount, uint256 end);

    /// @notice Emitted when a lock is withdrawn from.
    event Withdrawal(uint256 indexed lockID, uint256 requestedWithdrawAmount, uint256 actualWithdrawAmount, uint256 burnAmount);

    /// @notice Emitted when an early withdraw is made.
    event EarlyWithdrawal(uint256 indexed lockID, uint256 requestedWithdrawAmount, uint256 actualWithdrawAmount, uint256 burnAmount);

    /// @notice Emitted when a listener is added.
    event LockListenerAdded(address indexed listener);

    /// @notice Emitted when a listener is removed.
    event LockListenerRemoved(address indexed listener);

    /// @notice Emitted when the registry is set.
    event RegistrySet(address indexed registry);

    /// @notice Emitted when voting contract has been set
    event VotingContractSet(address indexed votingContract);

    /// @notice Emitted when funding rate is set.
    event FundingRateSet(uint256 indexed fundingRate);

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    /// @notice Token locked in the underwriting lock.
    function token() external view returns (address);

    /// @notice Registry address
    function registry() external view returns (address);

    /// @notice UnderwriterLockVoting.sol address.
    function votingContract() external view returns (address);

    /// @notice The total number of locks that have been created.
    function totalNumLocks() external view returns (uint256);

    /// @notice Funding rate - amount that will be charged and burned from a regular withdraw.
    /// @dev Value of 1e18 => 100%.
    function fundingRate() external view returns (uint256);

    /// @notice The minimum lock duration that a new lock must be created with.
    function MIN_LOCK_DURATION() external view returns (uint256);

    /// @notice The maximum time into the future that a lock can expire.
    function MAX_LOCK_DURATION() external view returns (uint256);

    /// @notice The maximum number of locks one user can create.
    function MAX_NUM_LOCKS() external view returns (uint256);

    /***************************************
    EXTERNAL VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Get `amount` and `end` values for a lockID.
     * @param lockID_ The ID of the lock to query.
     * @return lock_ Lock {uint256 amount, uint256 end}.
     */
    function locks(uint256 lockID_) external view returns (Lock memory lock_);


    /**
     * @notice Determines if the lock is currently locked.
     * @param lockID_ The ID of the lock to query.
     * @return locked True if the lock is locked, false if unlocked.
     */
    function isLocked(uint256 lockID_) external view returns (bool locked);

    /**
     * @notice Determines the time left until the lock unlocks.
     * @param lockID_ The ID of the lock to query.
     * @return time The time left in seconds, 0 if unlocked.
     */
    function timeLeft(uint256 lockID_) external view returns (uint256 time);

    /**
     * @notice Returns the total token amount that the user has staked in underwriting locks.
     * @param account_ The account to query.
     * @return balance The user's total staked token amount.
     */
    function totalStakedBalance(address account_) external view returns (uint256 balance);

    /**
     * @notice The list of contracts that are listening to lock updates.
     * @return listeners_ The list as an array.
     */
    function getLockListeners() external view returns (address[] memory listeners_);

    /**
     * @notice Computes amount of token that will be transferred to the user on full withdraw.
     * @param lockID_ The ID of the lock to query.
     * @return withdrawAmount Token amount that will be withdrawn.
     */
    function getWithdrawAmount(uint256 lockID_) external view returns (uint256 withdrawAmount);

    /**
     * @notice Computes amount of token that will be transferred to the user on partial withdraw.
     * @param lockID_ The ID of the lock to query.
     * @param amount_ The requested amount to withdraw.
     * @return withdrawAmount Token amount that will be withdrawn.
     */
    function getWithdrawInPartAmount(uint256 lockID_, uint256 amount_) external view returns (uint256 withdrawAmount);

    /**
     * @notice Computes amount of token that will be burned on full withdraw.
     * @param lockID_ The ID of the lock to query.
     * @return burnAmount Token amount that will be burned on withdraw.
     */
    function getBurnOnWithdrawAmount(uint256 lockID_) external view returns (uint256 burnAmount);

    /**
     * @notice Computes amount of token that will be burned on partial withdraw.
     * @param lockID_ The ID of the lock to query.
     * @param amount_ The requested amount to withdraw.
     * @return burnAmount Token amount that will be burned on withdraw.
     */
    function getBurnOnWithdrawInPartAmount(uint256 lockID_, uint256 amount_) external view returns (uint256 burnAmount);

    /**
     * @notice Gets multiplier (applied for voting boost, and for early withdrawals).
     * @param lockID_ The ID of the lock to query.
     * @return multiplier 1e18 => 1x multiplier, 2e18 => 2x multiplier.
     */
    function getLockMultiplier(uint256 lockID_) external view returns (uint256 multiplier);

    /**
     * @notice Gets all active lockIDs for a user.
     * @param user_ The address of user to query.
     * @return lockIDs Array of active lockIDs.
     */
    function getAllLockIDsOf(address user_) external view returns (uint256[] memory lockIDs);

    /***************************************
    EXTERNAL MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit token to create a new lock.
     * @dev Token is transferred from msg.sender, assumes its already approved.
     * @param recipient_ The account that will receive the lock.
     * @param amount_ The amount of token to deposit.
     * @param end_ The timestamp the lock will unlock.
     * @return lockID The ID of the newly created lock.
     */
    function createLock(address recipient_, uint256 amount_, uint256 end_) external returns (uint256 lockID);

    /**
     * @notice Deposit token to create a new lock.
     * @dev Token is transferred from msg.sender using ERC20Permit.
     * @dev recipient = msg.sender.
     * @param amount_ The amount of token to deposit.
     * @param end_ The timestamp the lock will unlock.
     * @param deadline_ Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     * @return lockID The ID of the newly created lock.
     */
    function createLockSigned(uint256 amount_, uint256 end_, uint256 deadline_, uint8 v, bytes32 r, bytes32 s) external returns (uint256 lockID);

    /**
     * @notice Deposit token to increase the value of an existing lock.
     * @dev Token is transferred from msg.sender, assumes its already approved.
     * @dev Anyone (not just the lock owner) can call increaseAmount() and deposit to an existing lock.
     * @param lockID_ The ID of the lock to update.
     * @param amount_ The amount of token to deposit.
     */
    function increaseAmount(uint256 lockID_, uint256 amount_) external;

    /**
     * @notice Deposit token to increase the value of multiple existing locks.
     * @dev Token is transferred from msg.sender, assumes its already approved.
     * @dev If a lockID does not exist, the corresponding amount will be refunded to msg.sender.
     * @dev Anyone (not just the lock owner) can call increaseAmountMultiple() and deposit to existing locks.
     * @param lockIDs_ Array of lock IDs to update.
     * @param amounts_ Array of token amounts to deposit.
     */
    function increaseAmountMultiple(uint256[] calldata lockIDs_, uint256[] calldata amounts_) external;

    /**
     * @notice Deposit token to increase the value of an existing lock.
     * @dev Token is transferred from msg.sender using ERC20Permit.
     * @dev Anyone (not just the lock owner) can call increaseAmount() and deposit to an existing lock.
     * @param lockID_ The ID of the lock to update.
     * @param amount_ The amount of token to deposit.
     * @param deadline_ Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function increaseAmountSigned(uint256 lockID_, uint256 amount_, uint256 deadline_, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @notice Extend a lock's duration.
     * @dev Can only be called by the lock owner or approved.
     * @param lockID_ The ID of the lock to update.
     * @param end_ The new time for the lock to unlock.
     */
    function extendLock(uint256 lockID_, uint256 end_) external;

    /**
     * @notice Extend multiple locks' duration.
     * @dev Can only be called by the lock owner or approved.
     * @dev If non-existing lockIDs are entered, these will be skipped.
     * @param lockIDs_ Array of lock IDs to update.
     * @param ends_ Array of new unlock times.
     */
    function extendLockMultiple(uint256[] calldata lockIDs_, uint256[] calldata ends_) external;

    /**
     * @notice Withdraw from a lock in full.
     * @dev Can only be called by the lock owner or approved.
     * @dev If called before `end` timestamp, will incur additional burn amount.
     * @param lockID_ The ID of the lock to withdraw from.
     * @param recipient_ The user to receive the lock's token.
     */
    function withdraw(uint256 lockID_, address recipient_) external;

    /**
     * @notice Withdraw from a lock in part.
     * @dev Can only be called by the lock owner or approved.
     * @dev If called before `end` timestamp, will incur additional burn amount.
     * @param lockID_ The ID of the lock to withdraw from.
     * @param amount_ The amount of token to withdraw.
     * @param recipient_ The user to receive the lock's token.
     */
    function withdrawInPart(uint256 lockID_, uint256 amount_, address recipient_) external;

    /**
     * @notice Withdraw from multiple locks in full.
     * @dev Can only be called by the lock owner or approved.
     * @dev If called before `end` timestamp, will incur additional burn amount.
     * @param lockIDs_ The ID of the locks to withdraw from.
     * @param recipient_ The user to receive the lock's token.
     */
    function withdrawMultiple(uint256[] calldata lockIDs_, address recipient_) external;

    /**
     * @notice Withdraw from multiple locks in part.
     * @dev Can only be called by the lock owner or approved.
     * @dev If called before `end` timestamp, will incur additional burn amount.
     * @param lockIDs_ The ID of the locks to withdraw from.
     * @param amounts_ Array of token amounts to withdraw
     * @param recipient_ The user to receive the lock's token.
     */
    function withdrawInPartMultiple(uint256[] calldata lockIDs_, uint256[] calldata amounts_ ,address recipient_) external;

    /***************************************
    VOTING CONTRACT FUNCTIONS
    ***************************************/

    /**
     * @notice Perform accounting for voting premiums to be charged by UnderwritingLockVoting.chargePremiums().
     * @dev Can only be called by votingContract set in the registry.
     * @param lockID_ The ID of the lock to charge premium.
     * @param premium_ Amount of tokens to charge as premium.
     */
    function chargePremium(uint256 lockID_, uint256 premium_) external;

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds a listener.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param listener_ The listener to add.
     */
    function addLockListener(address listener_) external;

    /**
     * @notice Removes a listener.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param listener_ The listener to remove.
     */
    function removeLockListener(address listener_) external;

    /**
     * @notice Sets the base URI for computing `tokenURI`.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) external;

    /**
     * @notice Sets the [`Registry`](./Registry) contract address.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param registry_ The address of `Registry` contract.
     */
    function setRegistry(address registry_) external;

    /**
     * @notice Sets votingContract and enable safeTransferFrom call by `underwritingLockVoting` address stored in Registry.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function setVotingContract() external;

    /**
     * @notice Sets fundingRate.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param fundingRate_ Desired funding rate, 1e18 => 100%
     */
    function setFundingRate(uint256 fundingRate_) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IGaugeVoter.sol";
import "./GaugeStructs.sol";

/**
 * @title IUnderwritingLockVoting
 * @author solace.fi
 * @notice Enables individual votes in Solace Native insurance gauges for owners of [`UnderwritingLocker`](./UnderwritingLocker).
 *
 * Any address owning an underwriting lock can vote and will have a votePower that can be viewed with [`getVotePower()`](#getVotePower)
 * An address' vote power is the sum of the vote power of its owned locks.
 * A lock's vote power scales linearly with locked amount, and through a sqrt formula with lock duration
 * Users cannot view the vote power of an individual lock through this contract, only the total vote power of an address.
 * This is an intentional design choice to abstract locks away from address-based voting.
 *
 * Voters can set a delegate who can vote on their behalf via [`setDelegate()`](#setDelegate).
 *
 * To cast a vote, either the voter or their delegate can call [`vote()`](#vote) or [`voteMultiple()`](#voteMultiple).
 * Votes can be cast among existing gaugeIDs (set in GaugeController.sol), and voters/delegates can set a custom proportion
 * of their total voting power for different gauges.
 * Voting power proportion is measured in bps, and total used voting power bps for a voter cannot exceed 10000.
 *
 * Votes are saved, so a vote today will count as the voter's vote for all future epochs until the voter modifies their votes.
 *
 * After each epoch (one-week) has passed, voting is frozen until governance has processed all the votes.
 * This is a two-step process:
 * GaugeController.updateGaugeWeights() - this will aggregate individual votes and update gauge weights accordingly
 * [`chargePremiums()`](#chargepremiums) - this will charge premiums for every vote. There is a voting premium
 * to be paid every epoch, this gets sent to the revenue router.
 */
interface IUnderwritingLockVoting is IGaugeVoter {

    /***************************************
    CUSTOM ERRORS
    ***************************************/

    /// @notice Thrown when zero address is given as an argument.
    /// @param contractName Name of contract for which zero address was incorrectly provided.
    error ZeroAddressInput(string contractName);

    /// @notice Thrown when array arguments are mismatched in length (and need to have the same length);
    error ArrayArgumentsLengthMismatch();

    /// @notice Thrown when setDelegate() attempted for a non-owner.
    error NotOwner();

    /// @notice Thrown when vote is attempted before last epoch's premiums have been successfully charged.
    error LastEpochPremiumsNotCharged();

    /// @notice Thrown when vote() attempted by a non-owner or non-delegate.
    error NotOwnerNorDelegate();

    /// @notice Thrown when vote is attempted for voter with no underwriting locks.
    error VoterHasNoLocks();

    /// @notice Thrown if attempt to vote with single vote having votePowerBPS > 10000.
    error SingleVotePowerBPSOver10000();

    /// @notice Thrown if attempt to vote with total votePowerBPS > 10000.
    error TotalVotePowerBPSOver10000();

    /// @notice Thrown when non-gaugeController attempts to call setLastRecordedVotePower().
    error NotGaugeController();

    /// @notice Thrown when chargePremiums is attempted before the last epoch's votes have been successfully processed through gaugeController.updateGaugeWeights().
    error GaugeWeightsNotYetUpdated();

    /// @notice Thrown when chargePremiums() attempted when all premiums have been charged for the last epoch.
    /// @param epochTime Timestamp of endtime for epoch already processed.
    error LastEpochPremiumsAlreadyProcessed(uint256 epochTime);

    /// @notice Thrown when chargePremiums() is called by neither governance nor updater, or governance is locked.
    error NotUpdaterNorGovernance();

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a delegate is set for a voter.
    event DelegateSet(address indexed voter, address indexed delegate);

    /// @notice Emitted when the Registry is set.
    event RegistrySet(address indexed registry);

    /// @notice Emitted when the Updater is set.
    event UpdaterSet(address indexed updater);

    /// @notice Emitted when the Bribe Controller is set.
    event BribeControllerSet(address indexed bribeController);

    /// @notice Emitted when a vote is added.
    event VoteAdded(address indexed voter, uint256 indexed gaugeID, uint256 votePowerBPS);

    /// @notice Emitted when a vote is added.
    event VoteChanged(address indexed voter, uint256 indexed gaugeID, uint256 newVotePowerBPS, uint256 oldVotePowerBPS);

    /// @notice Emitted when a vote is removed.
    event VoteRemoved(address indexed voter, uint256 indexed gaugeID);

    /// @notice Emitted when chargePremiums was partially completed and needs to be called again.
    event IncompletePremiumsCharge();

    /// @notice Emitted when premiums for all stored votes have been processed in an epoch.
    event AllPremiumsCharged(uint256 indexed epochTimestamp);

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    /// @notice Revenue router address ($UWE voting fees will be transferred here).
    function revenueRouter() external view returns (address);

    /// @notice Address of [`UnderwritingLocker`](./UnderwritingLocker)
    function underwritingLocker() external view returns (address);

    /// @notice Address of [`GaugeController`](./GaugeController).
    function gaugeController() external view returns (address);

    /// @notice Address of [`BribeController`](./BribeController).
    function bribeController() external view returns (address);

    /// @notice Registry address
    function registry() external view returns (address);

    /// @notice Updater address.
    function updater() external view returns (address);

    /**
     * @notice End timestamp for last epoch that premiums were charged for all stored votes.
     * @return timestamp_
     */
    function lastTimePremiumsCharged() external view returns (uint256 timestamp_);

    /**
     * @notice Get delegate for a given voter.
     * @param voter_ The address of the voter to query for.
     * @return delegate Zero address if no lock delegate.
     */
    function delegateOf(address voter_) external view returns (address delegate);

    /**
     * @notice voter => used voting power percentage (max of 10000 BPS)
     * @param voter_ The address of the voter to query for.
     * @return usedVotePowerBPS Total usedVotePowerBPS.
     */
    function usedVotePowerBPSOf(address voter_) external view returns (uint256 usedVotePowerBPS);

    /***************************************
    EXTERNAL VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Get all current votes for a voter.
     * @param voter_ Address of voter to query for.
     * @return votes Array of Vote{gaugeID, votePowerBPS}.
     */
    function getVotes(address voter_) external view returns (GaugeStructs.Vote[] memory votes);

    /**
     * @notice Get timestamp for the start of the current epoch.
     * @return timestamp
     */
    function getEpochStartTimestamp() external view returns (uint256 timestamp);

    /**
     * @notice Get timestamp for end of the current epoch.
     * @return timestamp
     */
    function getEpochEndTimestamp() external view returns (uint256 timestamp);

    /**
     * @notice Query whether voting is currently open.
     * @return True if voting is open for this epoch, false otherwise.
     */
    function isVotingOpen() external view returns (bool);

    /**
     * @notice Get array of voters who have delegated their vote to a given address.
     * @param delegate_ Address to query array of voting delegators for.
     * @return votingDelegators Array of voting delegators.
     */
    function getVotingDelegatorsOf(address delegate_) external view returns (address[] memory votingDelegators);

    /**
     * @notice Get last processed vote power for given voter.
     * @param voter_ Address of voter to query for.
     * @return lastProcessedVotePower
     */
    function getLastProcessedVotePowerOf(address voter_) external view returns (uint256 lastProcessedVotePower);

    /***************************************
    EXTERNAL MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Register a single vote for a gauge. Can either add or change a vote.
     * @notice Can also remove a vote (votePowerBPS_ == 0), the difference with removeVote() is that
     * vote() will revert if the voter has no locks (no locks => no right to vote, but may have votes from
     * locks that have since been burned).
     * @notice GaugeController.updateGaugeWeights() will remove voters with no voting power, however voters can
     * preemptively 'clean' the system.
     * @notice Votes are frozen after the end of every epoch, and resumed when all stored votes have been processed.
     * Can only be called by the voter or vote delegate.
     * @param voter_ The voter address.
     * @param gaugeID_ The ID of the gauge to vote for.
     * @param votePowerBPS_ Vote power BPS to assign to this vote
     */
    function vote(address voter_, uint256 gaugeID_, uint256 votePowerBPS_) external;

    /**
     * @notice Register multiple gauge votes.
     * Can only be called by the voter or vote delegate.
     * @param voter_ The voter address.
     * @param gaugeIDs_ Array of gauge IDs to vote for.
     * @param votePowerBPSs_ Array of corresponding vote power BPS values.
     */
    function voteMultiple(address voter_, uint256[] memory gaugeIDs_, uint256[] memory votePowerBPSs_) external;

    /**
     * @notice Register a single voting configuration for multiple voters.
     * Can only be called by the voter or vote delegate.
     * @param voters_ Array of voters.
     * @param gaugeIDs_ Array of gauge IDs to vote for.
     * @param votePowerBPSs_ Array of corresponding vote power BPS values.
     */
    function voteForMultipleVoters(address[] calldata voters_, uint256[] memory gaugeIDs_, uint256[] memory votePowerBPSs_) external;

    /**
     * @notice Removes a vote.
     * @notice Votes cannot be removed while voting is frozen.
     * Can only be called by the voter or vote delegate.
     * @param voter_ The voter address.
     * @param gaugeID_ The ID of the gauge to remove vote for.
     */
    function removeVote(address voter_, uint256 gaugeID_) external;

    /**
     * @notice Remove multiple gauge votes.
     * @notice Votes cannot be removed while voting is frozen.
     * Can only be called by the voter or vote delegate.
     * @param voter_ The voter address.
     * @param gaugeIDs_ Array of gauge IDs to remove votes for.
     */
    function removeVoteMultiple(address voter_, uint256[] memory gaugeIDs_) external;

    /**
     * @notice Remove gauge votes for multiple voters.
     * @notice Votes cannot be removed while voting is frozen.
     * Can only be called by the voter or vote delegate.
     * @param voters_ Array of voter addresses.
     * @param gaugeIDs_ Array of gauge IDs to remove votes for.
     */
    function removeVotesForMultipleVoters(address[] calldata voters_, uint256[] memory gaugeIDs_) external;

    /**
     * @notice Set the voting delegate for the caller.
     * To remove a delegate, the delegate can be set to the ZERO_ADDRESS - 0x0000000000000000000000000000000000000000.
     * @param delegate_ Address of intended delegate
     */
    function setDelegate(address delegate_) external;

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [`Registry`](./Registry) contract address.
     * @dev Requires 'uwe', 'revenueRouter' and 'underwritingLocker' addresses to be set in the Registry.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param registry_ The address of `Registry` contract.
     */
    function setRegistry(address registry_) external;

    /**
     * @notice Set updater address.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param updater_ The address of the new updater.
     */
    function setUpdater(address updater_) external;

    /**
     * @notice Sets bribeController as per `bribeController` address stored in Registry.
     * @dev We do not set this in constructor, because we expect BribeController.sol to be deployed after this contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function setBribeController() external;

    /**
     * @notice Charge premiums for votes.
     * @dev Designed to be called in a while-loop with the condition being `lastTimePremiumsCharged != epochStartTimestamp` and using the maximum custom gas limit.
     * @dev Requires GaugeController.updateGaugeWeights() to be run to completion for the last epoch.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function chargePremiums() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./GaugeStructs.sol";

/**
 * @title GaugeController
 * @author solace.fi
 * @notice Stores individual votes for Solace Native gauges, and maintains current gauge weights.
 *
 * Current gauge weights can be obtained through [`getGaugeWeight()`](#getgaugeweight) and [`getAllGaugeWeights()`](#getallgaugeweights)
 *
 * Only governance can make mutator calls to GaugeController.sol. There are no unpermissioned external mutator calls in this contract.
 *
 * After every epoch, governance must call [`updateGaugeWeights()`](#updategaugeweights). This will process the last epoch's votes (stored in this contract).
 *
 * Individual voters register and manage their vote through voting contracts that conform to IGaugeVoting.
 *
 * Governance can [`addGauge()`](#addgauge) or [`pauseGauge()`](#pausegauge).
 */
interface IGaugeController {

    /***************************************
    CUSTOM ERRORS
    ***************************************/

    /// @notice Thrown when zero address is given as an argument.
    /// @param contractName Name of contract for which zero address was incorrectly provided.
    error ZeroAddressInput(string contractName);

    /// @notice Thrown when array arguments are mismatched in length;
    error ArrayArgumentsLengthMismatch();

    /// @notice Thrown if pauseGauge() is attempted on a gauge that is already paused.
    /// @param gaugeID The gauge ID.
    error GaugeAlreadyPaused(uint256 gaugeID);

    /// @notice Thrown if unpauseGauge() is attempted on a gauge that is already paused.
    /// @param gaugeID The gauge ID.
    error GaugeAlreadyUnpaused(uint256 gaugeID);

    /// @notice Thrown if unpauseGauge() is attempted on gauge ID 0.
    error CannotUnpauseGaugeID0();

    /// @notice Thrown if vote() is attempted for gauge ID 0.
    error CannotVoteForGaugeID0();

    /// @notice Thrown if updateGaugeWeights() is called after gauge weights have been successfully updated in the current epoch.
    error GaugeWeightsAlreadyUpdated();

    /// @notice Thrown when vote attempted before gauge weights have been successfully updated for this epoch.
    error GaugeWeightsNotYetUpdated();

    /// @notice Thrown when vote() is called by an address not added as a voting contract.
    error NotVotingContract();

    /// @notice Thrown when removeVotingContract attempted for address that has not previously been added as a voting contract.
    error VotingContractNotAdded();

    /// @notice Thrown when vote() is called with gaugeID that does not exist.
    error GaugeIDNotExist();

    /// @notice Thrown when vote() is called with gaugeID that is paused.
    error GaugeIDPaused();

    /// @notice Thrown when getInsurancePremium() is called and there are no tokenholders added.
    error NoTokenholdersAdded();

    /// @notice Thrown when removeTokenholder() is attempted for an address not in the tokenholder set.
    error TokenholderNotPresent();

    /// @notice Thrown when updateGaugeWeights() is called by neither governance nor updater, or governance is locked.
    error NotUpdaterNorGovernance();

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a voting contract is added.
    event VotingContractAdded(address indexed votingContractAddress);

    /// @notice Emitted when a voting contract is removed.
    event VotingContractRemoved(address indexed votingContractAddress);

    /// @notice Emitted when a gauge is added.
    event GaugeAdded(uint256 indexed gaugeID, uint256 rateOnLine, string gaugeName);

    /// @notice Emitted when a gauge is paused.
    event GaugePaused(uint256 indexed gaugeID, string gaugeName);

    /// @notice Emitted when a gauge is unpaused.
    event GaugeUnpaused(uint256 indexed gaugeID, string gaugeName);

    /// @notice Emitted when leverage factor set.
    event LeverageFactorSet(uint256 indexed leverageFactor);

    /// @notice Emitted when rate on line for a gauge is set.
    event RateOnLineSet(uint256 indexed gaugeID, uint256 rateOnLine);

    /// @notice Emitted when address of underwriting equity token is set.
    event TokenSet(address indexed token);

    /// @notice Emitted when the epoch length is set.
    event EpochLengthSet(uint256 indexed weeks_);

    /// @notice Emitted when the Updater is set.
    event UpdaterSet(address indexed updater);

    /// @notice Emitted when address added to tokenholder set.
    event TokenholderAdded(address indexed tokenholder);

    /// @notice Emitted when address removed from tokenholder set.
    event TokenholderRemoved(address indexed tokenholder);

    /// @notice Emitted when updateGaugeWeights() does an incomplete update, and run again until completion.
    event IncompleteGaugeUpdate();

    /// @notice Emitted when gauge weights are updated.
    event GaugeWeightsUpdated(uint256 indexed updateTime);

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    /// @notice Underwriting equity token.
    function token() external view returns (address);

    /// @notice Updater address.
    function updater() external view returns (address);

    /// @notice Insurance leverage factor.
    function leverageFactor() external view returns (uint256);

    /// @notice The total number of gauges that have been created.
    function totalGauges() external view returns (uint256);

    /// @notice End timestamp for last epoch that all stored votes were processed.
    function lastTimeGaugeWeightsUpdated() external view returns (uint256);

    /***************************************
    EXTERNAL VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Get timestamp for the start of the current epoch.
     * @return timestamp
     */
    function getEpochStartTimestamp() external view returns (uint256 timestamp);

    /**
     * @notice Get timestamp for end of the current epoch.
     * @return timestamp
     */
    function getEpochEndTimestamp() external view returns (uint256 timestamp);

    /**
     * @notice Get current gauge weight of single gauge ID.
     * @dev Gauge weights must sum to 1e18, so a weight of 1e17 == 10% weight
     * @param gaugeID_ The ID of the gauge to query.
     * @return weight
     */
    function getGaugeWeight(uint256 gaugeID_) external view returns (uint256 weight);

    /**
     * @notice Get all gauge weights.
     * @dev Gauge weights must sum to 1e18, so a weight of 1e17 == 10% weight.
     * @dev weights[0] will always be 0, so that weights[1] maps to the weight of gaugeID 1.
     * @return weights
     */
    function getAllGaugeWeights() external view returns (uint256[] memory weights);

    /**
     * @notice Get number of active gauges.
     * @return numActiveGauges
     */
    function getNumActiveGauges() external view returns (uint256 numActiveGauges);

    /**
     * @notice Get number of paused gauges.
     * @return numPausedGauges
     */
    function getNumPausedGauges() external view returns (uint256 numPausedGauges);

    /**
     * @notice Get gauge name.
     * @param gaugeID_ The ID of the gauge to query.
     * @return gaugeName
     */
    function getGaugeName(uint256 gaugeID_) external view returns (string calldata gaugeName);

    /**
     * @notice Query whether gauge is active.
     * @param gaugeID_ The ID of the gauge to query.
     * @return gaugeActive True if active, false otherwise.
     */
    function isGaugeActive(uint256 gaugeID_) external view returns (bool gaugeActive);

    /**
     * @notice Obtain rate on line of gauge.
     * @param gaugeID_ The ID of the gauge to query.
     * @return rateOnLine_ Annual rate on line, 1e18 => 100%.
     */
    function getRateOnLineOfGauge(uint256 gaugeID_) external view returns (uint256 rateOnLine_);

    /**
     * @notice Obtain insurance capacity in $UWE terms.
     * @dev Leverage * UWE capacity.
     * @return insuranceCapacity Insurance capacity in $UWE.
     */
    function getInsuranceCapacity() external view returns (uint256 insuranceCapacity);

    /**
     * @notice Get vote power sum across all gauges.
     * @return votePowerSum
     */
    function getVotePowerSum() external view returns (uint256 votePowerSum);

    /**
     * @notice Get all votes for a given voter and voting contract.
     * @param votingContract_ Address of voting contract  - must have been added via addVotingContract().
     * @param voter_ Address of voter.
     * @return votes Array of Vote {gaugeID, votePowerBPS}.
     */
    function getVotes(address votingContract_, address voter_) external view returns (GaugeStructs.Vote[] memory votes);

    /**
     * @notice Get all voters for a given voting contract.
     * @param votingContract_ Address of voting contract  - must have been added via addVotingContract().
     * @return voters Array of voters
     */
    function getVoters(address votingContract_) external view returns (address[] memory voters);

    /**
     * @notice Get number of votes for a given voter and voting contract.
     * @param votingContract_ Address of voting contract  - must have been added via addVotingContract().
     * @param voter_ Address of voter.
     * @return voteCount Number of votes.
     */
    function getVoteCount(address votingContract_, address voter_) external view returns (uint256 voteCount);

    /**
     * @notice Get number of voters for a voting contract.
     * @param votingContract_ Address of voting contract  - must have been added via addVotingContract().
     * @return votersCount Number of votes.
     */
    function getVotersCount(address votingContract_) external view returns (uint256 votersCount);

    /**
     * @notice Get current epoch length in seconds.
     * @return epochLength
     */
    function getEpochLength() external view returns (uint256 epochLength);

    /***************************************
    VOTING CONTRACT FUNCTIONS
    ***************************************/

    /**
     * @notice Register votes.
     * @dev Can only be called by voting contracts that have been added via addVotingContract().
     * @param voter_ Address of voter.
     * @param gaugeID_ The ID of the voted gauge.
     * @param newVotePowerBPS_ Desired vote power BPS, 0 if removing vote.
     * @return oldVotePowerBPS Old votePowerBPS value, 0 if new vote.
     */
    function vote(address voter_, uint256 gaugeID_, uint256 newVotePowerBPS_) external returns (uint256 oldVotePowerBPS);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds a voting contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param votingContract_ The votingContract to add.
     */
    function addVotingContract(address votingContract_) external;

    /**
     * @notice Removes a voting contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param votingContract_ The votingContract to add.
     */
    function removeVotingContract(address votingContract_) external;

    /**
     * @notice Adds an insurance gauge.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param gaugeName_ Gauge name
     * @param rateOnLine_ Annual rate on line (1e18 => 100%).
     */
    function addGauge(string calldata gaugeName_, uint256 rateOnLine_) external;

    /**
     * @notice Pauses an insurance gauge.
     * @notice Paused gauges cannot have votes added or modified, and votes for a paused gauge will not be counted
     * in the next updateGaugeWeights() call.
     * @dev We do not include a removeGauge function as this would distort the order of the _gauges array
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param gaugeID_ ID of gauge to pause
     */
    function pauseGauge(uint256 gaugeID_) external;

    /**
     * @notice Unpauses an insurance gauge.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param gaugeID_ ID of gauge to pause
     */
    function unpauseGauge(uint256 gaugeID_) external;

    /**
     * @notice Set insurance leverage factor.
     * @dev 1e18 => 100%.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param leverageFactor_ Desired leverage factor.
     */
    function setLeverageFactor(uint256 leverageFactor_) external;

    /**
     * @notice Set underwriting token address.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param token_ The address of the new underwriting token.
     */
    function setToken(address token_) external;

    /**
     * @notice Set updater address.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param updater_ The address of the new updater.
     */
    function setUpdater(address updater_) external;

    /**
     * @notice Set epoch length (as an integer multiple of 1 week).
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param weeks_ Integer multiple of 1 week, to set epochLength to.
     */
    function setEpochLengthInWeeks(uint256 weeks_) external;

   /**
     * @notice Adds address to tokenholders set - these addresses will be queried for $UWE token balance and summed to determine the Solace Native insurance capacity.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param tokenholder_ Address of new tokenholder
     */
    function addTokenholder(address tokenholder_) external;

    /**
     * @notice Removes an address from the tokenholder set - these addresses will be queried for $UWE token balance and summed to determine the Solace Native insurance capacity.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param tokenholder_ Address of new tokenholder.
     */
    function removeTokenholder(address tokenholder_) external;

    /**
     * @notice Set annual rate-on-line for selected gaugeIDs
     * @dev 1e18 => 100%
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param gaugeIDs_ Array of gaugeIDs.
     * @param rateOnLines_ Array of corresponding annual rate on lines.
     */
    function setRateOnLine(uint256[] calldata gaugeIDs_, uint256[] calldata rateOnLines_) external;

    /**
     * @notice Updates gauge weights by processing votes for the last epoch.
     * @dev Designed to be called in a while-loop with custom gas limit of 6M until `lastTimePremiumsCharged == epochStartTimestamp`.
     * Can only be called by the current [**governor**](/docs/protocol/governance) or the updater role.
     */
    function updateGaugeWeights() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IGovernable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
 * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setpendinggovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);
    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);
    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view returns (address);

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view returns (address);

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view returns (bool);

    /***************************************
    MUTATORS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from OpenZeppelin and @uniswap/v3-periphery
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title ERC721Enhanced
 * @author solace.fi
 * @notice An extension of `ERC721`.
 *
 * The base is OpenZeppelin's `ERC721Enumerable` which also includes the `Metadata` extension. This extension includes simpler transfers, gasless approvals, and changeable URIs.
 */
interface IERC721Enhanced is IERC721Enumerable {

    /***************************************
    SIMPLER TRANSFERS
    ***************************************/

    /**
     * @notice Transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `transferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function transfer(address to, uint256 tokenID) external;

    /**
     * @notice Safely transfers `tokenID` from `msg.sender` to `to`.
     * @dev This was excluded from the official `ERC721` standard in favor of `safeTransferFrom(address from, address to, uint256 tokenID)`. We elect to include it.
     * @param to The receipient of the token.
     * @param tokenID The token to transfer.
     */
    function safeTransfer(address to, uint256 tokenID) external;

    /***************************************
    GASLESS APPROVALS
    ***************************************/

    /**
     * @notice Approve of a specific `tokenID` for spending by `spender` via signature.
     * @param spender The account that is being approved.
     * @param tokenID The ID of the token that is being approved for spending.
     * @param deadline The deadline timestamp by which the call must be mined for the approve to work.
     * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`.
     * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`.
     * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`.
     */
    function permit(
        address spender,
        uint256 tokenID,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Returns the current nonce for `tokenID`. This value must be
     * included whenever a signature is generated for `permit`.
     * Every successful call to `permit` increases ``tokenID``'s nonce by one. This
     * prevents a signature from being used multiple times.
     * @param tokenID ID of the token to request nonce.
     * @return nonce Nonce of the token.
     */
    function nonces(uint256 tokenID) external view returns (uint256 nonce);

    /**
     * @notice The permit typehash used in the `permit` signature.
     * @return typehash The typehash for the `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function PERMIT_TYPEHASH() external view returns (bytes32 typehash);

    /**
     * @notice The domain separator used in the encoding of the signature for `permit`, as defined by `EIP712`.
     * @return seperator The domain seperator for `permit`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32 seperator);

    /***************************************
    CHANGEABLE URIS
    ***************************************/

    /// @notice Emitted when the base URI is set.
    event BaseURISet(string baseURI);

    /***************************************
    MISC
    ***************************************/

    /**
     * @notice Determines if a token exists or not.
     * @param tokenID The ID of the token to query.
     * @return status True if the token exists, false if it doesn't.
     */
    function exists(uint256 tokenID) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IGaugeVoter
 * @author solace.fi
 * @notice A standard interface for a contract that interacts with GaugeController.sol to register votes.
 */
interface IGaugeVoter {
    /**
     * @notice Get vote power for a voter.
     * @param voter_ The address of the voter to query.
     * @return votePower
     */
    function getVotePower(address voter_) external view returns (uint256 votePower);

    /**
     * @notice Cache last processed vote power for a vote ID.
     * @dev Can only be called by the gaugeController contract.
     * @dev For chargePremiums() calculations.
     * @param voter_ Address of voter.
     * @param votePower_ Vote power.
     */
    function cacheLastProcessedVotePower(address voter_, uint256 votePower_) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

library GaugeStructs {
    struct Vote {
        uint256 gaugeID;
        uint256 votePowerBPS;
    }

    /// @dev Struct pack into single 32-byte word
    /// @param _votingContractsIndex Index for _votingContracts for last incomplete updateGaugeWeights() call.
    /// @param _votersIndex Index for _voters[savedIndex_votingContracts] for last incomplete updateGaugeWeights() call.
    /// @param _votesIndex Index for _votes[savedIndex_votingContracts][savedIndex_voters] for last incomplete updateGaugeWeights() call.
    struct UpdateInfo {
        uint80 _votingContractsIndex; // [0:80]
        uint88 _votersIndex; // [80:168]
        uint88 _votesIndex; // [168:256]
    }

    struct Gauge { 
        bool active; // [0:8]
        uint248 rateOnLine; // [8:256] Max value we reasonably expect is ~20% or 2e17. We only need log 2 2e17 = ~58 bits for this.
        string name;
    }
}