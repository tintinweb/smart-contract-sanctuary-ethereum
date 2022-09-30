// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./../interfaces/native/IBribeController.sol";
import "./../interfaces/native/IUnderwritingLockVoting.sol";
import "./../interfaces/native/IGaugeController.sol";
import "./../interfaces/utils/IRegistry.sol";
import "./../utils/EnumerableMapS.sol";
import "./../utils/Governable.sol";

contract BribeController is 
        IBribeController, 
        ReentrancyGuard, 
        Governable 
    {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMapS for EnumerableMapS.AddressToUintMap;
    using EnumerableMapS for EnumerableMapS.UintToUintMap;

    /***************************************
    GLOBAL PUBLIC VARIABLES
    ***************************************/

    /// @notice Registry address
    address public override registry;

    /// @notice GaugeController.sol address
    address public override gaugeController;

    /// @notice UnderwriterLockVoting.sol address
    address public override votingContract;

    /// @notice End timestamp for last epoch that bribes were processed for all stored votes.
    uint256 public override lastTimeBribesProcessed;

    /***************************************
    GLOBAL INTERNAL VARIABLES
    ***************************************/

    /// @notice gaugeID => bribeToken => bribeAmount.
    mapping(uint256 => EnumerableMapS.AddressToUintMap) internal _providedBribes;

    /// @notice briber => bribeToken => lifetimeOfferedBribeAmount.
    mapping(address => EnumerableMapS.AddressToUintMap) internal _lifetimeProvidedBribes;

    /// @notice voter => bribeToken => claimableBribeAmount.
    mapping(address => EnumerableMapS.AddressToUintMap) internal _claimableBribes;

    /// @notice gaugeID => total vote power
    EnumerableMapS.UintToUintMap internal _gaugeToTotalVotePower;

    /// @notice Collection of gauges with current bribes.
    EnumerableSet.UintSet internal _gaugesWithBribes;

    /// @notice gaugeID => voter => votePowerBPS.
    mapping(uint256 => EnumerableMapS.AddressToUintMap) internal _votes;

    /// @notice Address => gaugeID => votePowerBPS
    /// @dev _votes will be cleaned up in processBribes(), _votesMirror will not be.
    /// @dev This will enable _voteForBribe to remove previous epoch's voteForBribes.
    mapping(address => EnumerableMapS.UintToUintMap) internal _votesMirror;

    /// @notice whitelist of tokens that can be accepted as bribes
    EnumerableSet.AddressSet internal _bribeTokenWhitelist;

    /// @notice State of last [`distributeBribes()`](#distributeBribes) call.
    GaugeStructs.UpdateInfo internal _updateInfo;

    /***************************************
    CONSTRUCTOR
    ***************************************/

    /**
     * @notice Constructs the UnderwritingLocker contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param registry_ The [`Registry`](./Registry) contract address.
     */
    constructor(address governance_, address registry_)
        Governable(governance_)
    {
        _setRegistry(registry_);
        _clearUpdateInfo();
        lastTimeBribesProcessed = _getEpochStartTimestamp();
    }

    /***************************************
    INTERNAL VIEW FUNCTIONS
    ***************************************/

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
     * @notice Get unused votePowerBPS for a voter.
     * @param voter_ The address of the voter to query for.
     * @return unusedVotePowerBPS
     */
    function _getUnusedVotePowerBPS(address voter_) internal view returns (uint256 unusedVotePowerBPS) {
        return (10000 - IUnderwritingLockVoting(votingContract).usedVotePowerBPSOf(voter_));
    }

    /**
     * @notice Get votePowerBPS available for voteForBribes.
     * @param voter_ The address of the voter to query for.
     * @return availableVotePowerBPS
     */
    function _getAvailableVotePowerBPS(address voter_) internal view returns (uint256 availableVotePowerBPS) {
        (,uint256 epochEndTimestamp) = _votesMirror[voter_].tryGet(0);
        if (epochEndTimestamp == _getEpochEndTimestamp()) {
            return _getUnusedVotePowerBPS(voter_);
        } else {
            uint256 length = _votesMirror[voter_].length();
            uint256 staleVotePowerBPS = 0;
            for (uint256 i = 0; i < length; i++) {
                (uint256 gaugeID, uint256 votePowerBPS) = _votesMirror[voter_].at(i);
                if (gaugeID != 0) {staleVotePowerBPS += votePowerBPS;}
            }
            return (10000 - IUnderwritingLockVoting(votingContract).usedVotePowerBPSOf(voter_) + staleVotePowerBPS);
        }
    }

    /***************************************
    EXTERNAL VIEW FUNCTIONS
    ***************************************/

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
     * @notice Get unused votePowerBPS for a voter.
     * @param voter_ The address of the voter to query for.
     * @return unusedVotePowerBPS
     */
    function getUnusedVotePowerBPS(address voter_) external view override returns (uint256 unusedVotePowerBPS) {
        return _getUnusedVotePowerBPS(voter_);
    }

    /**
     * @notice Get votePowerBPS available for voteForBribes.
     * @param voter_ The address of the voter to query for.
     * @return availableVotePowerBPS
     */
    function getAvailableVotePowerBPS(address voter_) external view override returns (uint256 availableVotePowerBPS) {
        return _getAvailableVotePowerBPS(voter_);
    }

    /**
     * @notice Get list of whitelisted bribe tokens.
     * @return whitelist
     */
    function getBribeTokenWhitelist() external view override returns (address[] memory whitelist) {
        uint256 length = _bribeTokenWhitelist.length();
        whitelist = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            whitelist[i] = _bribeTokenWhitelist.at(i);
        }
    }

    /**
     * @notice Get claimable bribes for a given voter.
     * @param voter_ Voter to query for.
     * @return bribes Array of claimable bribes.
     */
    function getClaimableBribes(address voter_) external view override returns (Bribe[] memory bribes) {
        uint256 length = _claimableBribes[voter_].length();
        uint256 bribesLength = 0;
        for (uint256 i = 0; i < length; i++) {
            (, uint256 bribeAmount) = _claimableBribes[voter_].at(i);
            if (bribeAmount != type(uint256).max) {bribesLength += 1;}
        }
        bribes = new Bribe[](bribesLength);
        for (uint256 i = 0; i < length; i++) {
            (address bribeToken, uint256 bribeAmount) = _claimableBribes[voter_].at(i);
            if (bribeAmount == type(uint256).max) {continue;}
            bribes[i] = Bribe(bribeToken, bribeAmount);
        }
        return bribes;
    }

    /**
     * @notice Get all gaugeIDs with bribe/s offered in the present epoch.
     * @return gauges Array of gaugeIDs with current bribe.
     */
    function getAllGaugesWithBribe() external view override returns (uint256[] memory gauges) {
        uint256 length = _gaugesWithBribes.length();
        gauges = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            gauges[i] = _gaugesWithBribes.at(i);
        }
    }

    /**
     * @notice Get all bribes which have been offered for a given gauge.
     * @param gaugeID_ GaugeID to query for.
     * @return bribes Array of provided bribes.
     */
    function getProvidedBribesForGauge(uint256 gaugeID_) external view override returns (Bribe[] memory bribes) {
        uint256 length = _providedBribes[gaugeID_].length();
        bribes = new Bribe[](length);
        for (uint256 i = 0; i < length; i++) {
            (address bribeToken, uint256 bribeAmount) = _providedBribes[gaugeID_].at(i);
            bribes[i] = Bribe(bribeToken, bribeAmount);
        }
        return bribes;
    }

    /**
     * @notice Get lifetime provided bribes for a given briber.
     * @param briber_ Briber to query for.
     * @return bribes Array of lifetime provided bribes.
     */
    function getLifetimeProvidedBribes(address briber_) external view override returns (Bribe[] memory bribes) {
        uint256 length = _lifetimeProvidedBribes[briber_].length();
        bribes = new Bribe[](length);
        for (uint256 i = 0; i < length; i++) {
            (address bribeToken, uint256 bribeAmount) = _lifetimeProvidedBribes[briber_].at(i);
            bribes[i] = Bribe(bribeToken, bribeAmount);
        }
        return bribes;
    }

    /**
     * @notice Get all current voteForBribes for a given voter.
     * @dev Inefficient implementation to avoid 
     * @param voter_ Voter to query for.
     * @return votes Array of Votes {uint256 gaugeID, uint256 votePowerBPS}.
     */
    function getVotesForVoter(address voter_) external view override returns (GaugeStructs.Vote[] memory votes) {
        // Get num of votes
        uint256 numVotes = 0;

        // Iterate by gauge
        for (uint256 i = 0; i < _gaugeToTotalVotePower.length(); i++) {
            (uint256 gaugeID,) = _gaugeToTotalVotePower.at(i);
            // Iterate by vote
            for (uint256 j = 0; j < _votes[gaugeID].length(); j++) {
                (address voter,) = _votes[gaugeID].at(j);
                if (voter == voter_) numVotes += 1;
            }
        }

        // Define return array
        votes = new GaugeStructs.Vote[](numVotes);
        uint256 votes_index = 0;

        // Iterate by gauge
        for (uint256 i = 0; i < _gaugeToTotalVotePower.length(); i++) {
            (uint256 gaugeID,) = _gaugeToTotalVotePower.at(i);
            // Iterate by vote
            for (uint256 j = 0; j < _votes[gaugeID].length(); j++) {
                (address voter, uint256 votePowerBPS) = _votes[gaugeID].at(j);
                if (voter == voter_) {
                    votes[votes_index] = GaugeStructs.Vote(gaugeID, votePowerBPS);
                    votes_index += 1;
                    if (votes_index == numVotes) return votes;
                }
            }
        }
    }

    /**
     * @notice Get all current voteForBribes for a given gaugeID.
     * @param gaugeID_ GaugeID to query for.
     * @return votes Array of VoteForGauge {address voter, uint256 votePowerBPS}.
     */
    function getVotesForGauge(uint256 gaugeID_) external view override returns (VoteForGauge[] memory votes) {
        uint256 length = _votes[gaugeID_].length();
        votes = new VoteForGauge[](length);
        for (uint256 i = 0; i < length; i++) {
            (address voter, uint256 votePowerBPS) = _votes[gaugeID_].at(i);
            votes[i] = VoteForGauge(voter, votePowerBPS);
        }
    }

    /**
     * @notice Query whether bribing is currently open.
     * @return True if bribing is open for this epoch, false otherwise.
     */
    function isBribingOpen() external view override returns (bool) {
        uint256 epochStartTime = _getEpochStartTimestamp();
        return (epochStartTime == IGaugeController(gaugeController).lastTimeGaugeWeightsUpdated() 
        && epochStartTime == IUnderwritingLockVoting(votingContract).lastTimePremiumsCharged() 
        && epochStartTime == lastTimeBribesProcessed);
    }

    /***************************************
    INTERNAL MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Sets registry and related contract addresses.
     * @dev Requires 'uwe' and 'underwritingLocker' addresses to be set in the Registry.
     * @param _registry The registry address to set.
     */
    function _setRegistry(address _registry) internal {
        if(_registry == address(0x0)) revert ZeroAddressInput("registry");
        registry = _registry;
        IRegistry reg = IRegistry(_registry);
        // set gaugeController
        (, address gaugeControllerAddr) = reg.tryGet("gaugeController");
        if(gaugeControllerAddr == address(0x0)) revert ZeroAddressInput("gaugeController");
        gaugeController = gaugeControllerAddr;
        // set votingContract
        (, address underwritingLockVoting) = reg.tryGet("underwritingLockVoting");
        if(underwritingLockVoting == address(0x0)) revert ZeroAddressInput("underwritingLockVoting");
        votingContract = underwritingLockVoting;
        emit RegistrySet(_registry);
    }

    /**
     * @notice Remove vote for gaugeID with bribe.
     * @param voter_ address of voter.
     * @param gaugeID_ The ID of the gauge to remove vote for.
     */
    function _removeVoteForBribeInternal(address voter_, uint256 gaugeID_) internal {
        uint256[] memory gaugeIDs_ = new uint256[](1);
        uint256[] memory votePowerBPSs_ = new uint256[](1);
        gaugeIDs_[0] = gaugeID_;
        votePowerBPSs_[0] = 0;
        _voteForBribe(voter_, gaugeIDs_, votePowerBPSs_, true);
    }

    /**
     * @notice Add, change or remove vote for bribe.
     * Can only be called by the voter or their delegate.
     * @dev Remove NonReentrant modifier from internal function => 5K gas cost saving
     * @param voter_ The voter address.
     * @param gaugeIDs_ The array of gaugeIDs to vote for.
     * @param votePowerBPSs_ The corresponding array of votePowerBPS values. Can be from 0-10000.
     * @param isInternalCall_ True if called through processBribes, false otherwise.
     */
    function _voteForBribe(address voter_, uint256[] memory gaugeIDs_, uint256[] memory votePowerBPSs_, bool isInternalCall_) internal {
        // CHECKS
        if (gaugeIDs_.length != votePowerBPSs_.length) revert ArrayArgumentsLengthMismatch();

        // ENABLE INTERNAL CALL TO SKIP CHECKS (which otherwise block processBribes)
        if (!isInternalCall_) {
            if (_getEpochStartTimestamp() > lastTimeBribesProcessed) revert LastEpochBribesNotProcessed();
            if (voter_ != msg.sender && IUnderwritingLockVoting(votingContract).delegateOf(voter_) != msg.sender) revert NotOwnerNorDelegate();

            // If stale _votesMirror, empty _votesMirror and do external calls to remove vote
            if (_votesMirror[voter_].length() != 0) {
                (,uint256 epochEndTimestamp) = _votesMirror[voter_].tryGet(0);
                if (epochEndTimestamp < _getEpochEndTimestamp()) {
                    while(_votesMirror[voter_].length() > 0) {
                        (uint256 gaugeID, uint256 votePowerBPS) = _votesMirror[voter_].at(0);
                        _votesMirror[voter_].remove(gaugeID);
                        // 'Try' here for edge case where premiums charged => voter removes vote via UnderwritingLockVoting => bribe processed => Vote exists in BribeController.sol, but not in GaugeController.sol => Following call can fail.
                        if (gaugeID != 0) {try IUnderwritingLockVoting(votingContract).vote(voter_, gaugeID, 0) {} catch {}}
                    }
                }
            }   
        }

        for(uint256 i = 0; i < gaugeIDs_.length; i++) {
            uint256 gaugeID = gaugeIDs_[i];
            uint256 votePowerBPS = votePowerBPSs_[i];
            if (_providedBribes[gaugeID].length() == 0) revert NoBribesForSelectedGauge();
            // USE CHECKS IN EXTERNAL CALLS BEFORE FURTHER INTERNAL STATE MUTATIONS
            (, uint256 oldVotePowerBPS) = _votes[gaugeID].tryGet(voter_);
            if(!isInternalCall_) {IUnderwritingLockVoting(votingContract).vote(voter_, gaugeID, votePowerBPS);}
            // If remove vote
            if (votePowerBPS == 0) {
                if(!isInternalCall_) _votesMirror[voter_].remove(gaugeID);
                _votes[gaugeID].remove(voter_); // This step costs 15-25K gas, wonder if more efficient implementation.
                if (_votes[gaugeID].length() == 0) _gaugeToTotalVotePower.remove(gaugeID); // This step can cost up to 20K gas
                if(!isInternalCall_) {emit VoteForBribeRemoved(voter_, gaugeID);} // 5K gas cost to emit, avoid in unbounded loop
            } else {
                _gaugeToTotalVotePower.set(gaugeID, 1); // Do not set to 0 to avoid SSTORE penalty for 0 slot in processBribes().
                _votes[gaugeID].set(voter_, votePowerBPS);
                if ( _votesMirror[voter_].length() == 0) _votesMirror[voter_].set(0, _getEpochEndTimestamp());
                _votesMirror[voter_].set(gaugeID, votePowerBPS);
                // Change vote
                if(oldVotePowerBPS > 0) {
                    emit VoteForBribeChanged(voter_, gaugeID, votePowerBPS, oldVotePowerBPS);
                // Add vote
                } else {
                    _preInitializeClaimableBribes(gaugeID, voter_);
                    emit VoteForBribeAdded(voter_, gaugeID, votePowerBPS);
                }
            }
        }
    }

    /**
     * @notice Pre-initialize claimableBribes mapping to save SSTORE cost for zero-slot in processBribes()
     * @dev ~5% gas saving in processBribes().
     * @param gaugeID_ GaugeID.
     * @param voter_ Voter.
     */
    function _preInitializeClaimableBribes(uint256 gaugeID_, address voter_) internal {
        uint256 numBribeTokens = _providedBribes[gaugeID_].length();
        for (uint256 i = 0; i < numBribeTokens; i++) {
            (address bribeToken, ) = _providedBribes[gaugeID_].at(i);
            _claimableBribes[voter_].set(bribeToken, type(uint256).max);
        }
    }

    /***************************************
    BRIBER FUNCTIONS
    ***************************************/

    /**
     * @notice Provide bribe/s.
     * @param bribeTokens_ Array of bribe token addresses.
     * @param bribeAmounts_ Array of bribe token amounts.
     * @param gaugeID_ Gauge ID to bribe for.
     */
    function provideBribes(
        address[] calldata bribeTokens_, 
        uint256[] calldata bribeAmounts_,
        uint256 gaugeID_
    ) external override nonReentrant {
        // CHECKS
        if (_getEpochStartTimestamp() > lastTimeBribesProcessed) revert LastEpochBribesNotProcessed();
        if (bribeTokens_.length != bribeAmounts_.length) revert ArrayArgumentsLengthMismatch();
        try IGaugeController(gaugeController).isGaugeActive(gaugeID_) returns (bool gaugeActive) {
            if (!gaugeActive) revert CannotBribeForInactiveGauge();
        } catch {
            revert CannotBribeForNonExistentGauge();
        }

        uint256 length = bribeTokens_.length;
        for (uint256 i = 0; i < length; i++) {
            if (!_bribeTokenWhitelist.contains(bribeTokens_[i])) revert CannotBribeWithNonWhitelistedToken();
        }
        
        // INTERNAL STATE MUTATIONS
        _gaugesWithBribes.add(gaugeID_);

        for (uint256 i = 0; i < length; i++) {
            (,uint256 previousBribeSum) = _providedBribes[gaugeID_].tryGet(bribeTokens_[i]);
            _providedBribes[gaugeID_].set(bribeTokens_[i], previousBribeSum + bribeAmounts_[i]);
            (,uint256 lifetimeBribeTotal) = _lifetimeProvidedBribes[msg.sender].tryGet(bribeTokens_[i]);
            _lifetimeProvidedBribes[msg.sender].set(bribeTokens_[i], lifetimeBribeTotal + bribeAmounts_[i]);
        }

        // EXTERNAL CALLS + EVENTS
        for (uint256 i = 0; i < length; i++) {
            SafeERC20.safeTransferFrom(
                IERC20(bribeTokens_[i]),
                msg.sender,
                address(this),
                bribeAmounts_[i]
            );

            emit BribeProvided(msg.sender, gaugeID_, bribeTokens_[i], bribeAmounts_[i]);
        }
    }

    /***************************************
    VOTER FUNCTIONS
    ***************************************/

    /**
     * @notice Vote for gaugeID with bribe.
     * @param voter_ address of voter.
     * @param gaugeID_ gaugeID to vote for
     * @param votePowerBPS_ Vote power BPS to assign to this vote.
     */
    function voteForBribe(address voter_, uint256 gaugeID_, uint256 votePowerBPS_) external override nonReentrant {
        uint256[] memory gaugeIDs_ = new uint256[](1);
        uint256[] memory votePowerBPSs_ = new uint256[](1);
        gaugeIDs_[0] = gaugeID_;
        votePowerBPSs_[0] = votePowerBPS_;
        _voteForBribe(voter_, gaugeIDs_, votePowerBPSs_, false);
    }

    /**
     * @notice Vote for multiple gaugeIDs with bribes.
     * @param voter_ address of voter.
     * @param gaugeIDs_ Array of gaugeIDs to vote for
     * @param votePowerBPSs_ Array of corresponding vote power BPS values.
     */
    function voteForMultipleBribes(address voter_, uint256[] calldata gaugeIDs_, uint256[] calldata votePowerBPSs_) external override nonReentrant {
        _voteForBribe(voter_, gaugeIDs_, votePowerBPSs_, false);
    }

    /**
     * @notice Register a single voting configuration for multiple voters.
     * Can only be called by the voter or vote delegate.
     * @param voters_ Array of voters.
     * @param gaugeIDs_ Array of gauge IDs to vote for.
     * @param votePowerBPSs_ Array of corresponding vote power BPS values.
     */
    function voteForBribeForMultipleVoters(address[] calldata voters_, uint256[] memory gaugeIDs_, uint256[] memory votePowerBPSs_) external override nonReentrant {
        uint256 length = voters_.length;
        for (uint256 i = 0; i < length; i++) {
            _voteForBribe(voters_[i], gaugeIDs_, votePowerBPSs_, false);
        }
    }

    /**
     * @notice Remove vote for gaugeID with bribe.
     * @param voter_ address of voter.
     * @param gaugeID_ The ID of the gauge to remove vote for.
     */
    function removeVoteForBribe(address voter_, uint256 gaugeID_) external override nonReentrant {
        uint256[] memory gaugeIDs_ = new uint256[](1);
        uint256[] memory votePowerBPSs_ = new uint256[](1);
        gaugeIDs_[0] = gaugeID_;
        votePowerBPSs_[0] = 0;
        _voteForBribe(voter_, gaugeIDs_, votePowerBPSs_, false);
    }

    /**
     * @notice Remove multiple votes for bribes.
     * @param voter_ address of voter.
     * @param gaugeIDs_ Array of gaugeIDs to remove votes for
     */
    function removeVotesForMultipleBribes(address voter_, uint256[] calldata gaugeIDs_) external override nonReentrant {
        uint256[] memory votePowerBPSs_ = new uint256[](gaugeIDs_.length);
        for(uint256 i = 0; i < gaugeIDs_.length; i++) {votePowerBPSs_[i] = 0;}
        _voteForBribe(voter_, gaugeIDs_, votePowerBPSs_, false);
    }

    /**
     * @notice Remove gauge votes for multiple voters.
     * @notice Votes cannot be removed while voting is frozen.
     * Can only be called by the voter or vote delegate.
     * @param voters_ Array of voter addresses.
     * @param gaugeIDs_ Array of gauge IDs to remove votes for.
     */
    function removeVotesForBribeForMultipleVoters(address[] calldata voters_, uint256[] memory gaugeIDs_) external override nonReentrant {
        uint256 length = voters_.length;
        uint256[] memory votePowerBPSs_ = new uint256[](gaugeIDs_.length);
        for(uint256 i = 0; i < gaugeIDs_.length; i++) {votePowerBPSs_[i] = 0;}
        for (uint256 i = 0; i < length; i++) {
            _voteForBribe(voters_[i], gaugeIDs_, votePowerBPSs_, false);
        }
    }

    // Should delegate also be able to claim bribes for user?
    /**
     * @notice Claim bribes.
     */
    function claimBribes() external override nonReentrant {
        uint256 length = _claimableBribes[msg.sender].length();
        if (length == 0) revert NoClaimableBribes();
        while (_claimableBribes[msg.sender].length() != 0) {
            (address bribeToken, uint256 bribeAmount) = _claimableBribes[msg.sender].at(0);
            _claimableBribes[msg.sender].remove(bribeToken);
            if (bribeAmount == type(uint256).max) {continue;}
            SafeERC20.safeTransfer(IERC20(bribeToken), msg.sender, bribeAmount);
            emit BribeClaimed(msg.sender, bribeToken, bribeAmount);
        }
    }

    /***************************************
    RECEIVE NOTIFICATION HOOK
    ***************************************/

    /**
     * @notice Hook that enables this contract to be informed of votes made via UnderwritingLockVoting.sol.
     * @dev Required to prevent edge case where voteForBribe made via BribeController, is then modified via this contract, and the vote modifications are not reflected in BribeController _votes and _votesMirror storage data structures.
     * @dev The above will result in an edge case where a voter can claim more bribes than they are actually eligible for (votePowerBPS in BribeController _votes data structure that is processed in processBribes(), will be higher than actual votePowerBPS used.)
     * @param voter_ The voter address.
     * @param gaugeID_ The gaugeID to vote for.
     * @param votePowerBPS_ votePowerBPS value. Can be from 0-10000.
     */
    function receiveVoteNotification(address voter_, uint256 gaugeID_, uint256 votePowerBPS_) external override {
        if (msg.sender != votingContract) revert NotVotingContract();

        // Check if vote exists in _votes.
        if(_votes[gaugeID_].contains(voter_)) _votes[gaugeID_].set(voter_, votePowerBPS_);

        // Check if vote exists in _votesMirror.
        if(_votesMirror[voter_].contains(gaugeID_)) _votesMirror[voter_].set(gaugeID_, votePowerBPS_);
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [`Registry`](./Registry) contract address.
     * @dev Requires 'uwe' and 'underwritingLocker' addresses to be set in the Registry.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param registry_ The address of `Registry` contract.
     */
    function setRegistry(address registry_) external override onlyGovernance {
        _setRegistry(registry_);
    }

    /**
     * @notice Adds token to whitelist of accepted bribe tokens.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param bribeToken_ Address of bribe token.
     */
    function addBribeToken(address bribeToken_) external override onlyGovernance {
        _bribeTokenWhitelist.add(bribeToken_);
        emit BribeTokenAdded(bribeToken_);
    }

    /**
     * @notice Removes tokens from whitelist of accepted bribe tokens.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param bribeToken_ Address of bribe token.
     */
    function removeBribeToken(address bribeToken_) external override onlyGovernance {
        bool success = _bribeTokenWhitelist.remove(bribeToken_);
        if (!success) revert BribeTokenNotAdded();
        emit BribeTokenRemoved(bribeToken_);
    }

    /**
     * @notice Rescues misplaced and remaining bribes (from Solidity rounding down, and bribing rounds with no voters).
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param tokens_ Array of tokens to rescue.
     * @param receiver_ The receiver of the tokens.
     */
    function rescueTokens(address[] memory tokens_, address receiver_) external override onlyGovernance {
        uint256 length = tokens_.length;
        for(uint256 i = 0; i < length; i++) {
            IERC20 token = IERC20(tokens_[i]);
            uint256 balance = token.balanceOf(address(this));
            SafeERC20.safeTransfer(token, receiver_, balance);
            emit TokenRescued(address(token), receiver_, balance);
        }
    }

    /********************************************
     UPDATER FUNCTION TO BE RUN AFTER EACH EPOCH
    ********************************************/

    /**
     * @notice Processes bribes, and makes bribes claimable by eligible voters.
     * @dev Designed to be called in a while-loop with custom gas limit of 6M until `lastTimeBribesProcessed == epochStartTimestamp`.
     */
    function processBribes() external override {
        // CHECKS
        uint256 currentEpochStartTime = _getEpochStartTimestamp();
        if (lastTimeBribesProcessed >= currentEpochStartTime) revert BribesAlreadyProcessed();
        // Require gauge weights to have been updated for this epoch => ensure state we are querying from is < 1 WEEK old.
        if (IUnderwritingLockVoting(votingContract).lastTimePremiumsCharged() < currentEpochStartTime) revert LastEpochPremiumsNotCharged();

        // If no votes to process 
        // => early cleanup of _gaugesWithBribes and _providedBribes mappings
        // => bribes stay custodied on bribing contract
        // => early return
        if (_gaugeToTotalVotePower.length() == 0) {return _concludeProcessBribes(currentEpochStartTime);}

        // LOOP 1 - GET TOTAL VOTE POWER CHASING BRIBES FOR EACH GAUGE 
        // Block-scope to avoid stack too deep error
        {
        uint256 numGauges = _gaugeToTotalVotePower.length();        
        // Iterate by gauge
        for (uint256 i = _updateInfo.index1 == type(uint80).max ? 0 : _updateInfo.index1; i < numGauges; i++) {
            // Iterate by vote
            (uint256 gaugeID,) = _gaugeToTotalVotePower.at(i);
            uint256 numVotes = _votes[gaugeID].length();
            
            // 7-13K gas per loop
            for (uint256 j = _updateInfo.index2 == type(uint88).max || i != _updateInfo.index1 ? 0 : _updateInfo.index2; j < numVotes; j++) {
                // Checkpoint 1
                if (gasleft() < 20000) {return _saveUpdateState(i, j, type(uint88).max);}
                uint256 runningVotePowerSum = _gaugeToTotalVotePower.get(gaugeID);
                (address voter, uint256 votePowerBPS) = _votes[gaugeID].at(j);
                uint256 votePower = IUnderwritingLockVoting(votingContract).getLastProcessedVotePowerOf(voter);
                // State mutation 1
                _gaugeToTotalVotePower.set(gaugeID, runningVotePowerSum + (votePower * votePowerBPS) / 10000);
            }
        }
        }

        // LOOP 2 - DO ACCOUNTING FOR _claimableBribes AND _providedBribes MAPPINGS
        // _gaugeToTotalVotePower, _votes and _providedBribes enumerable collections should be empty at the end.
        {
        // Iterate by gauge
        while (_gaugeToTotalVotePower.length() > 0) {
            (uint256 gaugeID, uint256 votePowerSum) = _gaugeToTotalVotePower.at(0);

            // Iterate by vote - 30-60K gas per loop
            while(_votes[gaugeID].length() > 0) {
                (address voter, uint256 votePowerBPS) = _votes[gaugeID].at(0);
                // `votePowerSum - 1` to nullify initiating _gaugeToTotalVotePower values at 1 rather than 0.
                uint256 bribeProportion = 1e18 * (IUnderwritingLockVoting(votingContract).getLastProcessedVotePowerOf(voter) * votePowerBPS / 10000) / (votePowerSum - 1);

                // Iterate by bribeToken
                uint256 numBribeTokens = _providedBribes[gaugeID].length();
                for (uint256 k = _updateInfo.index3 == type(uint88).max ? 0 : _updateInfo.index3; k < numBribeTokens; k++) {
                    // Checkpoint 2
                    if (gasleft() < 120000) {
                        return _saveUpdateState(type(uint80).max - 1, type(uint88).max - 1, k);
                    }
                    (address bribeToken, uint256 totalBribeAmount) = _providedBribes[gaugeID].at(k);
                    (, uint256 runningClaimableAmount) = _claimableBribes[voter].tryGet(bribeToken);
                    if (runningClaimableAmount == type(uint256).max) {runningClaimableAmount = 0;}
                    uint256 bribeAmount = totalBribeAmount * bribeProportion / 1e18;
                    // State mutation 2
                    _claimableBribes[voter].set(bribeToken, runningClaimableAmount + bribeAmount);
                }
                if (_updateInfo.index3 != 0) {_updateInfo.index3 = type(uint88).max;}
                // Cleanup _votes, _gaugeToTotalVotePower enumerable collections.
                if (gasleft() < 110000) {return _saveUpdateState(type(uint80).max - 1, type(uint88).max - 1, type(uint88).max - 1);}
                _removeVoteForBribeInternal(voter, gaugeID); // 20-30K gas per call
            }
        }
        }

        // Cleanup _gaugesWithBribes and _providedBribes enumerable collections.
        return _concludeProcessBribes(currentEpochStartTime);
    }

    /***************************************
     processBribes() HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Save state of processing bribes to _updateInfo.
     * @param loop1GaugeIndex_ Current index of _gaugeToTotalVotePower in loop 1.
     * @param loop1VoteIndex_ Current index of _votes[gaugeID] in loop 1.
     * @param loop2BribeTokenIndex_ Current index of _providedBribes[gaugeID] in loop 2.
     */
    function _saveUpdateState(uint256 loop1GaugeIndex_, uint256 loop1VoteIndex_, uint256 loop2BribeTokenIndex_) internal {
        assembly {
            let updateInfo
            updateInfo := or(updateInfo, shr(176, shl(176, loop1GaugeIndex_))) // [0:80] => votingContractsIndex_
            updateInfo := or(updateInfo, shr(88, shl(168, loop1VoteIndex_))) // [80:168] => votersIndex_
            updateInfo := or(updateInfo, shl(168, loop2BribeTokenIndex_)) // [168:256] => votesIndex_
            sstore(_updateInfo.slot, updateInfo) 
        }
        emit IncompleteBribesProcessing();
    }

    /// @notice Reset _updateInfo to starting state.
    /// @dev Avoid zero-value of storage slot.
    function _clearUpdateInfo() internal {
        uint256 bitmap = type(uint256).max;
        assembly {
            sstore(_updateInfo.slot, bitmap)
        }
    }

    /// @notice Finishing code block of processBribes.
    /// @param currentEpochStartTime_ Current epoch start timestamp.
    function _concludeProcessBribes(uint256 currentEpochStartTime_) internal {
        while(_gaugesWithBribes.length() > 0) {
            uint256 gaugeID = _gaugesWithBribes.at(0);
            while(_providedBribes[gaugeID].length() > 0) {
                if (gasleft() < 45000) {return _saveUpdateState(type(uint80).max - 1, type(uint88).max - 1, type(uint88).max - 1);}
                (address bribeToken,) = _providedBribes[gaugeID].at(0);
                _providedBribes[gaugeID].remove(bribeToken);
            }
            _gaugesWithBribes.remove(gaugeID);
        }

        lastTimeBribesProcessed = currentEpochStartTime_;
        emit BribesProcessed(currentEpochStartTime_);
        _clearUpdateInfo();
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

import "./GaugeStructs.sol";
import "./IVoteListener.sol";

interface IBribeController is IVoteListener {
    /***************************************
    STRUCTS
    ***************************************/

    struct Bribe {
        address bribeToken;
        uint256 bribeAmount;
    }

    struct VoteForGauge {
        address voter;
        uint256 votePowerBPS;
    }

    /***************************************
    CUSTOM ERRORS
    ***************************************/

    /// @notice Thrown when zero address is given as an argument.
    /// @param contractName Name of contract for which zero address was incorrectly provided.
    error ZeroAddressInput(string contractName);
    
    /// @notice Thrown when array arguments are mismatched in length;
    error ArrayArgumentsLengthMismatch();

    /// @notice Thrown when removeBribeToken() is attempted for non-whitelisted token.
    error BribeTokenNotAdded();

    /// @notice Thrown when provideBribe attempted for inactive gauge.
    error CannotBribeForInactiveGauge();

    /// @notice Thrown when provideBribe attempted for non-existing gauge.
    error CannotBribeForNonExistentGauge();

    /// @notice Thrown when provideBribe attempted unwhitelisted bribe token.
    error CannotBribeWithNonWhitelistedToken();

    /// @notice Thrown when attempt to claim bribes when no bribe rewards are claimable.
    error NoClaimableBribes();

    /// @notice Thrown when receiveVoteNotification() called by an address that is not the underwritingLockVoting contract.
    error NotVotingContract();

    /// @notice Thrown when voteForBribe() attempted by a non-owner or non-delegate.
    error NotOwnerNorDelegate();

    /// @notice Thrown when voteForBribe() attempted for gauge without bribe.
    error NoBribesForSelectedGauge();

    /// @notice Thrown when offerBribe() or voteForBribe() attempted before last epoch bribes are processed.
    error LastEpochBribesNotProcessed();

    /// @notice Thrown if processBribes() is called after bribes have already been successfully processed in the current epoch.
    error BribesAlreadyProcessed();

    /// @notice Thrown when processBribes is attempted before the last epoch's premiums have been successfully charged through underwritingLockVoting.chargePremiums().
    error LastEpochPremiumsNotCharged();

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when bribe is provided.
    event BribeProvided(address indexed briber, uint256 indexed gaugeID, address indexed bribeToken, uint256 bribeAmount);

    /// @notice Emitted when a vote is added.
    event VoteForBribeAdded(address indexed voter, uint256 indexed gaugeID, uint256 votePowerBPS);

    /// @notice Emitted when a vote is added.
    event VoteForBribeChanged(address indexed voter, uint256 indexed gaugeID, uint256 newVotePowerBPS, uint256 oldVotePowerBPS);

    /// @notice Emitted when a vote is removed.
    event VoteForBribeRemoved(address indexed voter, uint256 indexed gaugeID);

    /// @notice Emitted when bribe is claimed.
    event BribeClaimed(address indexed briber, address indexed bribeToken, uint256 bribeAmount);

    /// @notice Emitted when registry set.
    event RegistrySet(address indexed registry);

    /// @notice Emitted when bribe token added to whitelist.
    event BribeTokenAdded(address indexed bribeToken);

    /// @notice Emitted when bribe token removed from whitelist.
    event BribeTokenRemoved(address indexed bribeToken);
    
    /// @notice Emitted when token rescued.
    event TokenRescued(address indexed token, address indexed receiver, uint256 balance);

    /// @notice Emitted when processBribes() does an incomplete update, and will need to be run again until completion.
    event IncompleteBribesProcessing();

    /// @notice Emitted when bribes distributed for an epoch.
    event BribesProcessed(uint256 indexed epochEndTimestamp);

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    /// @notice Registry address.
    function registry() external view returns (address);

    /// @notice Address of GaugeController.sol.
    function gaugeController() external view returns (address);

    /// @notice Address of UnderwritingLockVoting.sol
    function votingContract() external view returns (address);

    /// @notice End timestamp for last epoch that bribes were processed for all stored votes.
    function lastTimeBribesProcessed() external view returns (uint256);

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
     * @notice Get unused votePowerBPS for a voter.
     * @param voter_ The address of the voter to query for.
     * @return unusedVotePowerBPS
     */
    function getUnusedVotePowerBPS(address voter_) external view returns (uint256 unusedVotePowerBPS);

    /**
     * @notice Get votePowerBPS available for voteForBribes.
     * @param voter_ The address of the voter to query for.
     * @return availableVotePowerBPS
     */
    function getAvailableVotePowerBPS(address voter_) external view returns (uint256 availableVotePowerBPS);
    /**
     * @notice Get list of whitelisted bribe tokens.
     * @return whitelist
     */
    function getBribeTokenWhitelist() external view returns (address[] memory whitelist);

    /**
     * @notice Get claimable bribes for a given voter.
     * @param voter_ Voter to query for.
     * @return bribes Array of claimable bribes.
     */
    function getClaimableBribes(address voter_) external view returns (Bribe[] memory bribes);

    /**
     * @notice Get all gaugeIDs with bribe/s offered in the present epoch.
     * @return gauges Array of gaugeIDs with current bribe.
     */
    function getAllGaugesWithBribe() external view returns (uint256[] memory gauges);

    /**
     * @notice Get all bribes which have been offered for a given gauge.
     * @param gaugeID_ GaugeID to query for.
     * @return bribes Array of provided bribes.
     */
    function getProvidedBribesForGauge(uint256 gaugeID_) external view returns (Bribe[] memory bribes);

    /**
     * @notice Get lifetime provided bribes for a given briber.
     * @param briber_ Briber to query for.
     * @return bribes Array of lifetime provided bribes.
     */
    function getLifetimeProvidedBribes(address briber_) external view returns (Bribe[] memory bribes);

    /**
     * @notice Get all current voteForBribes for a given voter.
     * @param voter_ Voter to query for.
     * @return votes Array of Votes {uint256 gaugeID, uint256 votePowerBPS}.
     */
    function getVotesForVoter(address voter_) external view returns (GaugeStructs.Vote[] memory votes);

    /**
     * @notice Get all current voteForBribes for a given gaugeID.
     * @param gaugeID_ GaugeID to query for.
     * @return votes Array of VoteForGauge {address voter, uint256 votePowerBPS}.
     */
    function getVotesForGauge(uint256 gaugeID_) external view returns (VoteForGauge[] memory votes);

    /**
     * @notice Query whether bribing is currently open.
     * @return True if bribing is open for this epoch, false otherwise.
     */
    function isBribingOpen() external view returns (bool);

    /***************************************
    BRIBER FUNCTIONS
    ***************************************/

    /**
     * @notice Provide bribe/s.
     * @param bribeTokens_ Array of bribe token addresses.
     * @param bribeAmounts_ Array of bribe token amounts.
     * @param gaugeID_ Gauge ID to bribe for.
     */
    function provideBribes(
        address[] calldata bribeTokens_, 
        uint256[] calldata bribeAmounts_,
        uint256 gaugeID_
    ) external;

    /***************************************
    VOTER FUNCTIONS
    ***************************************/

    /**
     * @notice Vote for gaugeID with bribe.
     * @param voter_ address of voter.
     * @param gaugeID_ gaugeID to vote for
     * @param votePowerBPS_ Vote power BPS to assign to this vote.
     */
    function voteForBribe(address voter_, uint256 gaugeID_, uint256 votePowerBPS_) external;

    /**
     * @notice Vote for multiple gaugeIDs with bribes.
     * @param voter_ address of voter.
     * @param gaugeIDs_ Array of gaugeIDs to vote for
     * @param votePowerBPSs_ Array of corresponding vote power BPS values.
     */
    function voteForMultipleBribes(address voter_, uint256[] calldata gaugeIDs_, uint256[] calldata votePowerBPSs_) external;

    /**
     * @notice Register a single voting configuration for multiple voters.
     * Can only be called by the voter or vote delegate.
     * @param voters_ Array of voters.
     * @param gaugeIDs_ Array of gauge IDs to vote for.
     * @param votePowerBPSs_ Array of corresponding vote power BPS values.
     */
    function voteForBribeForMultipleVoters(address[] calldata voters_, uint256[] memory gaugeIDs_, uint256[] memory votePowerBPSs_) external;

    /**
     * @notice Remove vote for gaugeID with bribe.
     * @param voter_ address of voter.
     * @param gaugeID_ The ID of the gauge to remove vote for.
     */
    function removeVoteForBribe(address voter_, uint256 gaugeID_) external;

    /**
     * @notice Remove multiple votes for bribes.
     * @param voter_ address of voter.
     * @param gaugeIDs_ Array of gaugeIDs to remove votes for
     */
    function removeVotesForMultipleBribes(address voter_, uint256[] calldata gaugeIDs_) external;

    /**
     * @notice Remove gauge votes for multiple voters.
     * @notice Votes cannot be removed while voting is frozen.
     * Can only be called by the voter or vote delegate.
     * @param voters_ Array of voter addresses.
     * @param gaugeIDs_ Array of gauge IDs to remove votes for.
     */
    function removeVotesForBribeForMultipleVoters(address[] calldata voters_, uint256[] memory gaugeIDs_) external;

    /**
     * @notice Claim bribes.
     */
    function claimBribes() external;
    
    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [`Registry`](./Registry) contract address.
     * @dev Requires 'uwe' and 'underwritingLocker' addresses to be set in the Registry.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param registry_ The address of `Registry` contract.
     */
    function setRegistry(address registry_) external;

    /**
     * @notice Adds token to whitelist of accepted bribe tokens.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param bribeToken_ Address of bribe token.
     */
    function addBribeToken(address bribeToken_) external;

    /**
     * @notice Removes tokens from whitelist of accepted bribe tokens.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param bribeToken_ Address of bribe token.
     */
    function removeBribeToken(address bribeToken_) external;

    /**
     * @notice Rescues misplaced and remaining bribes (from Solidity rounding down).
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param tokens_ Array of tokens to rescue.
     * @param receiver_ The receiver of the tokens.
     */
    function rescueTokens(address[] memory tokens_, address receiver_) external;

    /***************************************
    UPDATER FUNCTION
    ***************************************/

    /**
     * @notice Processes bribes, and makes bribes claimable by eligible voters.
     * @dev Designed to be called in a while-loop with custom gas limit of 6M until `lastTimeBribesDistributed == epochStartTimestamp`.
     */
    function processBribes() external;
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

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a delegate is set for a voter.
    event DelegateSet(address indexed voter, address indexed delegate);

    /// @notice Emitted when the Registry is set.
    event RegistrySet(address indexed registry);

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
     * @notice Sets bribeController as per `bribeController` address stored in Registry.
     * @dev We do not set this in constructor, because we expect BribeController.sol to be deployed after this contract.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function setBribeController() external;

    /**
     * @notice Charge premiums for votes.
     * @dev Designed to be called in a while-loop with the condition being `lastTimePremiumsCharged != epochStartTimestamp` and using the maximum custom gas limit.
     * @dev Requires GaugeController.updateGaugeWeights() to be run to completion for the last epoch.
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

    /// @notice Thrown if attempt to setEpochLength to 0.
    error CannotSetEpochLengthTo0();

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
     */
    function updateGaugeWeights() external;
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

// ^4.7.1 of OpenZeppelin EnumerableMap.sol
// Created as local copy in Solace repo to enable use of single updated EnumerableMap.sol file while maintaining @openzeppelin dependencies at ~4.3.2.
// Initializable pattern used in Solace repo broken with ^4.7.1

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableMap.sol)

pragma solidity 0.8.6;

import "./EnumerableSetS.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an array of EnumerableMap.
 * ====
 */
library EnumerableMapS {
    using EnumerableSetS for EnumerableSetS.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSetS.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
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

library GaugeStructs {
    struct Vote {
        uint256 gaugeID;
        uint256 votePowerBPS;
    }

    /// @dev Struct pack into single 32-byte word
    struct UpdateInfo {
        uint80 index1; // [0:80]
        uint88 index2; // [80:168]
        uint88 index3; // [168:256]
    }

    struct Gauge { 
        bool active; // [0:8]
        uint248 rateOnLine; // [8:256] Max value we reasonably expect is ~20% or 2e17. We only need log 2 2e17 = ~58 bits for this.
        string name;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IVoteListener
 * @author solace.fi
 * @notice A standard interface for notifying a contract about votes made via UnderwritingLockVoting.sol.
 */
interface IVoteListener {
    /**
     * @notice Called when vote is made (hook called at the end of vote function logic).
     * @param voter_ The voter address.
     * @param gaugeID_ The gaugeID to vote for.
     * @param votePowerBPS_ votePowerBPS value. Can be from 0-10000.
     */
    function receiveVoteNotification(address voter_, uint256 gaugeID_, uint256 votePowerBPS_) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity 0.8.6;

// NOTE: this is the EnumerableSet implementation of OpenZeppelin 4.7.1
// we copy it here because the version of OpenZeppelin that we use (4.3.2) does not include EnumerableMap.UintToUintMap

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetS {
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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