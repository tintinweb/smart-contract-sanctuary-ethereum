// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {sub, wdiv, min} from "fiat/core/utils/Math.sol";
import {ICollybus} from "fiat/interfaces/ICollybus.sol";

import {OptimisticOracle} from "./OptimisticOracle.sol";
import {IOptimistic3PoolChainlinkValue} from "./interfaces/IOptimistic3PoolChainlinkValue.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";

/// @title Optimistic3PoolChainlinkOracle
/// @notice Implementation of the OptimisticOracle for any 3-Token-Pool.
/// The oracle uses the chainlink feeds to fetch prices and
/// computes the minimum across the three assets.
/// Assumptions: If a Chainlink Aggregator is not working as intended (e.g. calls revert (excl. getRoundData))
/// then the methods `value` and `validate` and subsequently `dispute` will revert as well
contract Optimistic3PoolChainlinkOracle is
    OptimisticOracle,
    IOptimistic3PoolChainlinkValue
{
    /// ======== Custom Errors ======== ///

    error Optimistic3PoolChainlinkOracle__fetchLatestValue_invalidTimestamp();
    error Optimistic3PoolChainlinkOracle__encodeNonce_staleProposal();
    error Optimistic3PoolChainlinkOracle__encodeNonce_activeDisputeWindow();
    error Optimistic3PoolChainlinkOracle__push_inactiveRateId();
    error Optimistic3PoolChainlinkOracle__encodeNonce_invalidTimestamp();
    error Optimistic3PoolChainlinkOracle__validate_invalidData();

    /// ======== Storage ======== ///

    // @notice Chainlink Feeds
    address public immutable aggregatorFeed1;
    address public immutable aggregatorFeed2;
    address public immutable aggregatorFeed3;

    /// @notice A proposals validation result, as determined in `validate`
    enum ValidateResult {
        Success,
        InvalidRoundId,
        InvalidDataOrNonce,
        InvalidValue
    }

    /// ======== Events ======== ///

    /// @param target Address of target
    /// @param oracleType Unique identifier
    /// @param bondToken Address of the ERC20 token used by the bonding proposers
    /// @param bondSize Amount of `bondToken` a proposer has to bond in order to submit proposals for each `rateId`
    /// @param disputeWindow Period until a proposed value can not be disputed anymore [seconds]
    /// @param aggregatorFeed1_ Address of the first chainlink aggregator feed
    /// @param aggregatorFeed2_ Address of the second chainlink aggregator feed
    /// @param aggregatorFeed3_ Address of the third chainlink aggregator feed
    constructor(
        address target,
        bytes32 oracleType,
        IERC20 bondToken,
        uint256 bondSize,
        uint256 disputeWindow,
        address aggregatorFeed1_,
        address aggregatorFeed2_,
        address aggregatorFeed3_
    ) OptimisticOracle(target, oracleType, bondToken, bondSize, disputeWindow) {
        aggregatorFeed1 = aggregatorFeed1_;
        aggregatorFeed2 = aggregatorFeed2_;
        aggregatorFeed3 = aggregatorFeed3_;
    }

    /// ======== Chainlink Oracle Implementation ======== ///

    /// @notice Retrieves the latest spot price from each Chainlink feed
    /// and computes the minimum price.
    /// @dev Assumes that the Chainlink Aggregators work as intended
    /// @return value_ Minimum spot price across the three feeds [wad]
    /// @return data Latest round ids and round timestamps for the
    /// Chainlink feeds[uint80,uint64,uint80,uint64,uint80,uint64]
    function value()
        public
        view
        override
        returns (uint256 value_, bytes memory data)
    {
        (
            uint256 value1,
            uint80 roundId1,
            uint64 timestamp1
        ) = _fetchLatestValue(aggregatorFeed1);

        (
            uint256 value2,
            uint80 roundId2,
            uint64 timestamp2
        ) = _fetchLatestValue(aggregatorFeed2);

        (
            uint256 value3,
            uint80 roundId3,
            uint64 timestamp3
        ) = _fetchLatestValue(aggregatorFeed3);

        // compute the min value between the three feeds
        value_ = min(value1, min(value2, value3));

        data = abi.encode(
            roundId1,
            timestamp1,
            roundId2,
            timestamp2,
            roundId3,
            timestamp3
        );
    }

    /// ======== Proposal Management ======== ///

    /// @notice Validates `proposedValue` for given `nonce` via the corresponding Chainlink feeds
    /// @param proposedValue Value to be validated [wad]
    /// @param *rateId RateId (see target) of the proposal being validated
    /// @param nonce Nonce of the `proposedValue`
    /// @param data Data used to generate `nonce`
    /// @return result Result of the validation [ValidateResult]
    /// @return validValue The minimum value retrieved from the chainlink feeds [wad]
    /// @return validData Data corresponding to `validValue`
    function validate(
        uint256 proposedValue,
        bytes32, /*rateId*/
        bytes32 nonce,
        bytes memory data
    )
        public
        view
        override(OptimisticOracle)
        returns (
            uint256 result,
            uint256 validValue,
            bytes memory validData
        )
    {
        // validate the data length
        if (data.length != 192) {
            revert Optimistic3PoolChainlinkOracle__validate_invalidData();
        } else {
            (
                uint80 roundId1,
                uint64 timestamp1,
                uint80 roundId2,
                uint64 timestamp2,
                uint80 roundId3,
                uint64 timestamp3
            ) = abi.decode(
                    data,
                    (uint80, uint64, uint80, uint64, uint80, uint64)
                );

            // validate the feed 1 chainlink round
            validValue = _fetchAndValidate(
                aggregatorFeed1,
                roundId1,
                timestamp1
            );
            // validate the feed 2 chainlink round, skip if validation failed previously
            if (validValue != 0) {
                validValue = min(
                    validValue,
                    _fetchAndValidate(aggregatorFeed2, roundId2, timestamp2)
                );
            }
            // validate the feed 3 chainlink round, skip if validation failed previously
            if (validValue != 0) {
                validValue = min(
                    validValue,
                    _fetchAndValidate(aggregatorFeed3, roundId3, timestamp3)
                );
            }

            // `validValue` will be 0 if any feed fails the verification
            if (validValue == 0) {
                result = uint256(ValidateResult.InvalidRoundId);
            } else {
                // create the nonce from the validated data
                uint64 minTimestamp = uint64(
                    min(timestamp1, min(timestamp2, timestamp3))
                );

                bytes32 computedNonce = _encodeNonce(
                    keccak256(data),
                    minTimestamp,
                    uint64(uint256(nonce))
                );

                if (computedNonce != nonce) {
                    result = uint256(ValidateResult.InvalidDataOrNonce);
                } else {
                    result = (validValue == proposedValue)
                        ? uint256(ValidateResult.Success)
                        : uint256(ValidateResult.InvalidValue);
                }
            }
        }

        // retrieve fresh data in case the validation process failed
        if (result != uint256(ValidateResult.Success)) {
            (validValue, validData) = value();
        }
    }

    /// @notice Fetches the latest value from a Chainlink Aggregator feed
    /// @param feed Address of the Chainlink Aggregator
    /// @return value_ Latest value fetched [wad]
    /// @return roundId_ RoundId for `value_`
    /// @return roundTimestamp_ The timestamp at which the latest round was created
    function _fetchLatestValue(address feed)
        private
        view
        returns (
            uint256 value_,
            uint80 roundId_,
            uint64 roundTimestamp_
        )
    {
        (
            uint80 roundId,
            int256 feedValue,
            ,
            uint256 roundTimestamp,

        ) = AggregatorV3Interface(feed).latestRoundData();

        if (roundTimestamp > type(uint64).max)
            revert Optimistic3PoolChainlinkOracle__fetchLatestValue_invalidTimestamp();

        roundTimestamp_ = uint64(roundTimestamp);
        roundId_ = roundId;

        unchecked {
            // scale to WAD
            value_ = wdiv(
                uint256(feedValue),
                10**AggregatorV3Interface(feed).decimals()
            );
        }
    }

    /// @notice Fetches round value from a Chainlink Aggregator feed for a given `roundId`
    /// @param feed Address of the Chainlink Aggregator
    /// @param roundId RoundId of the Chainlink Aggregator to fetch round data for
    /// @param roundTimestamp The timestamp used to validate the round data
    /// @return roundValue Value fetched for the given `roundId` [wad]
    /// @dev Returns 0 if the round is not found or if `roundTimestamp` does not match the retrieved round timestamp
    function _fetchAndValidate(
        address feed,
        uint256 roundId,
        uint256 roundTimestamp
    ) private view returns (uint256 roundValue) {
        try AggregatorV3Interface(feed).getRoundData(uint80(roundId)) returns (
            uint80, /*roundId*/
            int256 roundValue_,
            uint256, /*startedAt*/
            uint256 roundTimestamp_,
            uint80 /*answeredInRound*/
        ) {
            // set the return value only if the timestamp is checked
            if (roundTimestamp_ == roundTimestamp) {
                unchecked {
                    // scale to WAD
                    roundValue = wdiv(
                        uint256(roundValue_),
                        10**AggregatorV3Interface(feed).decimals()
                    );
                }
            }
        } catch {}
    }

    /// @notice Pushes a value directly to target by computing it on-chain
    /// without going through the shift / dispute process
    /// @dev Overwrites the current queued proposal with the blank (initial) proposal
    /// @param rateId RateId (see target)
    function push(bytes32 rateId) public override(OptimisticOracle) {
        if (!activeRateIds[rateId])
            revert Optimistic3PoolChainlinkOracle__push_inactiveRateId();

        // fetch the latest value from the Chainlink Aggregators
        (uint256 value1, , uint64 timestamp1) = _fetchLatestValue(
            aggregatorFeed1
        );
        (uint256 value2, , uint64 timestamp2) = _fetchLatestValue(
            aggregatorFeed2
        );
        (uint256 value3, , uint64 timestamp3) = _fetchLatestValue(
            aggregatorFeed3
        );

        // compute the min value
        uint256 value_ = min(value1, min(value2, value3));

        // compute the min round timestamp
        uint64 minTimestamp = uint64(
            min(timestamp1, min(timestamp2, timestamp3))
        );

        bytes32 nonce = _encodeNonce(0, minTimestamp, 0);
        // reset the current proposal
        proposals[rateId] = computeProposalId(rateId, address(0), 0, nonce);

        // push the value to target
        _push(rateId, value_);

        emit Push(rateId, nonce, value_);
    }

    /// @notice Pushes a proposed value to target
    /// @param rateId RateId (see target)
    /// @param value_ Value that will be pushed to target [wad]
    function _push(bytes32 rateId, uint256 value_)
        internal
        override(OptimisticOracle)
    {
        // the OptimisticOracle ignores any exceptions that could be raised in the contract where the values are pushed
        // to - otherwise the shift / dispute flow would halt
        try
            ICollybus(target).updateSpot(
                address(uint160(uint256(rateId))),
                value_
            )
        {} catch {}
    }

    /// @notice Checks that the dispute operation can be performed by the Oracle given `nonce`.
    /// `proposeTimestamp` encoded in `nonce` has to be less than `disputeWindow`
    /// @param nonce Nonce of the current proposal
    /// @return canDispute True if dispute operation can be performed
    function canDispute(bytes32 nonce)
        public
        view
        override(OptimisticOracle)
        returns (bool)
    {
        return (sub(block.timestamp, uint64(uint256(nonce))) <= disputeWindow);
    }

    /// @notice Derives the nonce of a proposal from `data` and block.timestamp
    /// @param prevNonce Nonce of the previous proposal
    /// @param data Encoded round ids and round timestamps for the
    /// chainlink rounds [uint80,uint64,uint80,uint64,uint80,uint64]
    /// @return nonce Nonce of the current proposal
    /// @dev Reverts if the `disputeWindow` is still active
    /// Reverts if the current proposal is older than the previous proposal
    function encodeNonce(bytes32 prevNonce, bytes memory data)
        public
        view
        override(OptimisticOracle)
        returns (bytes32 nonce)
    {
        // decode the timestamp of each round, must revert if data cannot be decoded
        (
            ,
            uint64 roundTimestamp1,
            ,
            uint64 roundTimestamp2,
            ,
            uint64 roundTimestamp3
        ) = abi.decode(data, (uint80, uint64, uint80, uint64, uint80, uint64));

        // compute the min between the three timestamps
        uint64 minTimestamp = uint64(
            min(roundTimestamp1, min(roundTimestamp2, roundTimestamp3))
        );

        // skip the time window checks for the initial proposal
        if (prevNonce != 0) {
            // decode the round timestamp of the previous proposal from `nonce`
            (
                ,
                uint64 prevTimestamp,
                uint64 prevProposeTimestamp
            ) = _decodeNonce(prevNonce);

            // revert if the current proposal is older than the previous proposal
            if (prevTimestamp >= uint64(minTimestamp)) {
                revert Optimistic3PoolChainlinkOracle__encodeNonce_staleProposal();
            }

            // revert if prev. proposal is still within `disputeWindow`
            if (sub(block.timestamp, prevProposeTimestamp) <= disputeWindow) {
                revert Optimistic3PoolChainlinkOracle__encodeNonce_activeDisputeWindow();
            }
        }

        // create the nonce
        nonce = _encodeNonce(
            keccak256(data),
            uint64(minTimestamp),
            uint64(block.timestamp)
        );
    }

    /// @notice Decodes `nonce` into `dataHash` and `proposeTimestamp`
    /// @param nonce Nonce of a proposal
    /// @return noncePrefix The prefix of nonce [dataHash,round timestamp]
    /// @return proposeTimestamp Timestamp at which the proposal was created
    function decodeNonce(bytes32 nonce)
        public
        pure
        override(OptimisticOracle)
        returns (bytes32 noncePrefix, uint64 proposeTimestamp)
    {
        (
            bytes32 dataHash,
            uint64 roundTimestamp,
            uint64 proposeTimestamp_
        ) = _decodeNonce(nonce);
        noncePrefix = bytes32(
            (uint256(dataHash << 128) + uint256(roundTimestamp)) << 64
        );
        proposeTimestamp = proposeTimestamp_;
    }

    /// @notice Encodes `dataHash`, `roundTimestamp` and `proposeTimestamp` as `nonce`
    /// @param dataHash The keccak hash of the proposal data
    /// @param roundTimestamp Timestamp of the Chainlink round
    /// @param proposeTimestamp Timestamp at which the proposal was created
    /// @return nonce Nonce [dataHash, roundTimestamp, proposeTimestamp]
    function _encodeNonce(
        bytes32 dataHash,
        uint64 roundTimestamp,
        uint64 proposeTimestamp
    ) internal pure returns (bytes32 nonce) {
        unchecked {
            nonce = bytes32(
                (uint256(dataHash) << 128) +
                    (uint256(roundTimestamp) << 64) +
                    uint256(proposeTimestamp)
            );
        }
    }

    /// @notice Decodes the `dataHash`, `roundTimestamp` and `proposeTimestamp` from `nonce`
    /// @param nonce bytes32 containing [roundId, roundTimestamp, proposeTimestamp]
    /// @return dataHash Hash of the proposal data contained in the nonce
    /// @return roundTimestamp Timestamp of the Chainlink round
    /// @return proposeTimestamp Timestamp at which the proposal was created

    function _decodeNonce(bytes32 nonce)
        internal
        pure
        returns (
            bytes32 dataHash,
            uint64 roundTimestamp,
            uint64 proposeTimestamp
        )
    {
        dataHash = bytes32(uint256(nonce >> 128));
        roundTimestamp = uint64(uint256(nonce >> 64));
        proposeTimestamp = uint64(uint256(nonce));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {mul} from "fiat/core/utils/Math.sol";
import {Guarded} from "fiat/core/utils/Guarded.sol";

import {IOptimisticOracle} from "./interfaces/IOptimisticOracle.sol";

/// @title OptimisticOracle
/// @notice The Optimistic Oracle allows for gas-efficient oracle value updates.
/// Bonded proposers can optimistically propose a value for a given RateId which can be disputed within a set time
/// interval by computing the value on-chain. Proposers are not rewarded for doing so directly and instead are only
/// compensated in the event that they call the `dispute` function, as `dispute` is a gas intensive operation due to its
/// computation of the expected value on-chain. Compensation is sourced from the bond put up by the malicious proposer.
/// This is an abstract contract which provides the base logic for shifting and disputing proposals and bond management.
abstract contract OptimisticOracle is IOptimisticOracle, Guarded {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error OptimisticOracle__activateRateId_activeRateId(bytes32 rateId);
    error OptimisticOracle__deactivateRateId_inactiveRateId(bytes32 rateId);
    error OptimisticOracle__shift_invalidPreviousProposal();
    error OptimisticOracle__shift_unbondedProposer();
    error OptimisticOracle__dispute_inactiveRateId();
    error OptimisticOracle__dispute_invalidDispute();
    error OptimisticOracle__settleDispute_unknownProposal();
    error OptimisticOracle__settleDispute_alreadyDisputed();
    error OptimisticOracle__bond_bondedProposer(bytes32 rateId);
    error OptimisticOracle__bond_inactiveRateId(bytes32 rateId);
    error OptimisticOracle__unbond_unbondedProposer();
    error OptimisticOracle__unbond_invalidProposal();
    error OptimisticOracle__unbond_isProposing();
    error OptimisticOracle__recover_unbondedProposer();
    error OptimisticOracle__recover_notLocked();

    /// @notice Address of the target where values should be pushed to
    address public immutable target;
    /// @notice Address of the bonded token
    IERC20 public immutable bondToken;
    /// @notice Amount of `bondToken` proposers have to bond for each "rate feed" [precision of bondToken]
    uint256 public immutable bondSize;
    /// @notice Oracle type (metadata)
    bytes32 public immutable oracleType;
    /// @notice Time until a proposed value can not be disputed anymore
    uint256 public immutable disputeWindow;

    /// @notice Map of ProposalIds by RateId
    /// For each "rate feed" (id. by RateId) only the current proposal is stored.
    /// Instead of storing all the data associated with a proposal, only the keccak256 hash of the data
    /// is stored as the ProposalId. The ProposalId is derived via `computeProposalId`.
    /// @dev RateId => ProposalId
    mapping(bytes32 => bytes32) public proposals;

    /// @notice Map of active RateIds
    /// A `rateId` has to be activated in order for proposer to deposit a bond for it and dispute proposals which
    /// reference the `rateId`.
    /// @dev RateId => bool
    mapping(bytes32 => bool) public activeRateIds;

    /// @notice Mapping of Bonds
    /// The Optimistic Oracle needs to ensure that there's a bond attached to every proposal made which can be claimed
    /// if the proposal is incorrect. In practice this requires that:
    /// - a proposer can't reuse their bond for multiple proposals (for the same or different rateIds)
    /// - a proposer can't unbond a proposal which hasn't passed `disputeWindow`
    /// For each "rate feed" (id. by RateId) it is required that a proposer submit proposals with a bond of `bondSize`.
    /// @dev Proposer => RateId => bonded
    mapping(address => mapping(bytes32 => bool)) public bonds;

    /// @param target_ Address of target
    /// @param oracleType_ Unique identifier
    /// @param bondToken_ Address of the ERC20 token used for bonding proposers
    /// @param bondSize_ Amount of `bondToken` a proposer has to bond in order to submit proposals for each `rateId`
    /// @param disputeWindow_ Protocol specific period until a proposed value can not be disputed [seconds//blocks]
    constructor(
        address target_,
        bytes32 oracleType_,
        IERC20 bondToken_,
        uint256 bondSize_,
        uint256 disputeWindow_
    ) {
        target = target_;
        bondToken = bondToken_;
        bondSize = bondSize_;
        oracleType = oracleType_;
        disputeWindow = disputeWindow_;
    }

    /// ======== Rate Configuration ======== ///

    /// @notice Activates proposing for a given `rateId` and creates the initial / blank proposal for it.
    /// @dev Sender has to be allowed to call this method. Reverts if the `rateId` is already active.
    /// @param rateId RateId
    function activateRateId(bytes32 rateId) public checkCaller {
        if (activeRateIds[rateId])
            revert OptimisticOracle__activateRateId_activeRateId(rateId);

        activeRateIds[rateId] = true;

        // update target and set the current proposal as a blank (initial) proposal
        push(rateId);
    }

    /// @notice Deactivates proposing for a given `rateId` and removes the last proposal which references it.
    /// @dev Sender has to be allowed to call this method. Reverts if the `rateId` is already inactive.
    /// @param rateId RateId
    function deactivateRateId(bytes32 rateId) public checkCaller {
        if (!activeRateIds[rateId]) {
            revert OptimisticOracle__deactivateRateId_inactiveRateId(rateId);
        }

        delete activeRateIds[rateId];

        // clear the current proposal to stop bonded proposers to `shift` new values for this rateId
        // without a valid current proposal, no new shifts can be made
        delete proposals[rateId];
    }

    /// ======== Proposal Management ======== ///

    /// @notice Queues a new proposed `value` for a given `rateId` and pushes `prevValue` to target
    /// @dev Can only be called by a bonded proposer. Reverts if either:
    /// - the specified previous proposal (`prevProposer`, `prevValue`, `prevNonce`) is invalid / non existent,
    /// - `disputeWindow` still active,
    /// - current proposed value is disputable (`dispute` has to be called beforehand)
    /// For the initial shift for a given `rateId` - `prevProposer`, `prevValue` and `prevNonce` are set to 0.
    /// @param rateId RateId for which to shift the proposals
    /// @param prevProposer Address of the previous proposer
    /// @param prevValue Value of the previous proposal
    /// @param prevNonce Nonce of the previous proposal
    /// @param value Value of the new proposal [wad]
    /// @param data Data of the new proposal
    function shift(
        bytes32 rateId,
        address prevProposer,
        uint256 prevValue,
        bytes32 prevNonce,
        uint256 value,
        bytes memory data
    ) external override(IOptimisticOracle) {
        // check that proposer is bonded for the given `rateId`
        if (!isBonded(msg.sender, rateId))
            revert OptimisticOracle__shift_unbondedProposer();

        // verify that the previous proposal exists
        if (
            proposals[rateId] !=
            computeProposalId(rateId, prevProposer, prevValue, prevNonce)
        ) {
            revert OptimisticOracle__shift_invalidPreviousProposal();
        }

        // derive the nonce of the new proposal from `data` (reverts if prev. proposal is within the `disputeWindow`)
        bytes32 nonce = encodeNonce(prevNonce, data);

        // push the previous value to target
        // skip if `prevNonce` is 0 (blank (initial) proposal) since it is not an actual proposal
        if (prevNonce != 0 && prevValue != 0) _push(rateId, prevValue);

        // update the proposal with the new values
        proposals[rateId] = computeProposalId(rateId, msg.sender, value, nonce);

        emit Propose(rateId, nonce);
    }

    /// @notice Disputes a proposed value by fetching the correct value from the implementation's data feed.
    /// The bond of the proposer of the disputed value is sent to the `receiver`.
    /// @param rateId RateId of the proposal being disputed
    /// @param proposer Address of the proposer of the proposal being disputed
    /// @param receiver Address of the receiver of the `proposer`'s bond
    /// @param value_ Value of the proposal being disputed [wad]
    /// @param nonce Nonce of the proposal being disputed
    /// @param data Additional encoded data required for disputes
    function dispute(
        bytes32 rateId,
        address proposer,
        address receiver,
        uint256 value_,
        bytes32 nonce,
        bytes memory data
    ) external override(IOptimisticOracle) {
        if (!activeRateIds[rateId])
            revert OptimisticOracle__dispute_inactiveRateId();

        // validate the proposed value
        (uint256 result, uint256 validValue, bytes memory validData) = validate(
            value_,
            rateId,
            nonce,
            data
        );

        // if result is zero then the validation was successful
        if (result == 0) revert OptimisticOracle__dispute_invalidDispute();

        emit Validate(rateId, proposer, result);

        // skip the dispute window check when replacing the invalid nonce
        bytes32 validNonce = encodeNonce(bytes32(0), validData);

        _settleDispute(
            rateId,
            proposer,
            receiver,
            value_,
            nonce,
            validValue,
            validNonce
        );

        emit Propose(rateId, validNonce);
    }

    /// @notice Validates `proposedValue` for a given `nonce`
    /// @param proposedValue Value to be validated [wad]
    /// @param rateId RateId
    /// @param nonce Protocol specific nonce of the `proposedValue`
    /// @param data Protocol specific data buffer corresponding to `proposedValue`
    /// @return result 0 for success, otherwise a protocol specific validation failure code is returned
    /// @return validValue Value that was computed onchain
    /// @return validData Data corresponding to `validValue`
    function validate(
        uint256 proposedValue,
        bytes32 rateId,
        bytes32 nonce,
        bytes memory data
    )
        public
        virtual
        override(IOptimisticOracle)
        returns (
            uint256 result,
            uint256 validValue,
            bytes memory validData
        );

    /// @notice Settles the dispute by overwriting the invalid proposal with a new proposal
    /// and claims the malicious proposer's bond
    /// @param rateId RateId of the proposal to dispute
    /// @param proposer Address of the proposer of the disputed proposal
    /// @param receiver Address of the bond receiver
    /// @param value Value of the proposal to dispute [wad]
    /// @param nonce Nonce of the proposal to dispute
    /// @param validValue Value computed by the validator [wad]
    /// @param validNonce Nonce computed by the validator
    function _settleDispute(
        bytes32 rateId,
        address proposer,
        address receiver,
        uint256 value,
        bytes32 nonce,
        uint256 validValue,
        bytes32 validNonce
    ) internal {
        if (proposer == address(this)) {
            revert OptimisticOracle__settleDispute_alreadyDisputed();
        }

        // verify the proposal data
        if (
            proposals[rateId] !=
            computeProposalId(rateId, proposer, value, nonce)
        ) {
            revert OptimisticOracle__settleDispute_unknownProposal();
        }

        // overwrite the proposal with the value computed by the Validator
        proposals[rateId] = computeProposalId(
            rateId,
            address(this),
            validValue,
            validNonce
        );

        // block the proposer from further bonding
        _blockCaller(bytes4(keccak256("bond(bytes32[])")), proposer);

        // transfer the bond to the receiver (disregard the outcome)
        _claimBond(proposer, rateId, receiver);

        emit Dispute(rateId, proposer, msg.sender, value, validValue);
    }

    /// @notice Pushes a value directly to target by computing it on-chain
    /// without going through the shift / dispute process
    /// @dev Overwrites the current queued proposal with the blank (initial) proposal
    /// @param rateId RateId
    function push(bytes32 rateId) public virtual override(IOptimisticOracle);

    /// @notice Pushes a proposed value to target
    /// @param rateId RateId
    /// @param value Value that will be pushed to target [wad]
    function _push(bytes32 rateId, uint256 value) internal virtual;

    /// @notice Computes the ProposalId
    /// @param rateId RateId
    /// @param proposer Address of the proposer
    /// @param value Proposed value [wad]
    /// @param nonce Nonce of the proposal
    /// @return proposalId Computed proposalId
    function computeProposalId(
        bytes32 rateId,
        address proposer,
        uint256 value,
        bytes32 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(rateId, proposer, value, nonce));
    }

    /// @notice Derive the nonce of a proposal from `prevNonce` and `data`.
    /// @dev Must revert if the `disputeWindow` is still active
    /// @param prevNonce Nonce of the previous proposal
    /// @param data Data of the current proposal
    /// @return nonce of the current proposal
    function encodeNonce(bytes32 prevNonce, bytes memory data)
        public
        view
        virtual
        override(IOptimisticOracle)
        returns (bytes32);

    /// @notice Decode the data hash and the `proposeTimestamp` from a proposal `nonce`
    /// @dev Reverts if the `disputeWindow` is still active
    /// @param nonce Protocol specific nonce containing `proposeTimestamp`
    /// @return dataHash Pre-image of `nonce`
    /// @return proposeTimestamp Timestamp at which the proposal was made [uint64]
    function decodeNonce(bytes32 nonce)
        public
        view
        virtual
        override(IOptimisticOracle)
        returns (bytes32 dataHash, uint64 proposeTimestamp);

    /// @notice Checks that the dispute operation can be performed by the OptimisticOracle given `nonce`
    /// @return canDispute True if dispute operation can be performed
    function canDispute(bytes32 nonce)
        public
        view
        virtual
        override(IOptimisticOracle)
        returns (bool);

    /// ======== Bond Management ======== ///

    /// @notice Deposits `bondToken`'s for the specified `rateIds`
    /// The total bonded amount is `rateIds.length * bondSize`
    /// The caller needs to be whitelisted by the oracle owner
    /// @dev Reverts if the caller already deposited a bond for a given `rateId`
    /// Requires the caller to set an allowance for this contract
    /// @param rateIds List of `rateId`'s for each which sender wants to submit proposals for
    function bond(bytes32[] calldata rateIds)
        public
        override(IOptimisticOracle)
        checkCaller
    {
        _bond(msg.sender, rateIds);
    }

    /// @notice Deposits `bondToken`'s for a given `proposer` for the specified `rateIds`.
    /// The total bonded amount is `rateIds.length * bondSize`.
    /// @dev Requires the caller to set an allowance for this contract.
    /// Reverts if `proposer` already deposited a bond for a given `rateId`.
    /// @param proposer Address of the proposer
    /// @param rateIds List of `rateId`'s for each which `proposer` wants to submit proposals for
    function bond(address proposer, bytes32[] calldata rateIds)
        public
        override(IOptimisticOracle)
        checkCaller
    {
        _bond(proposer, rateIds);
    }

    /// @notice Deposits `bondToken`'s for a given `proposer` for the specified `rateIds`.
    /// The total bonded amount is `rateIds.length * bondSize`.
    /// @dev Requires the caller to set an allowance for this contract.
    /// Reverts if `proposer` already deposited a bond for a given `rateId`.
    /// @param proposer Address of the proposer
    /// @param rateIds List of `rateId`'s for each which `proposer` wants to submit proposals for
    function _bond(address proposer, bytes32[] calldata rateIds) private {
        // transfer the total amount to bond from the caller
        bondToken.safeTransferFrom(
            msg.sender,
            address(this),
            mul(rateIds.length, bondSize)
        );

        // mark the `proposer` as bonded for each rateId
        for (uint256 i = 0; i < rateIds.length; ++i) {
            bytes32 rateId = rateIds[i];

            // `rateId` needs to be active
            if (!activeRateIds[rateId]) {
                revert OptimisticOracle__bond_inactiveRateId(rateId);
            }

            // `proposer` should be unbonded for the specified `rateId`'s
            if (isBonded(proposer, rateId)) {
                revert OptimisticOracle__bond_bondedProposer(rateId);
            }

            bonds[proposer][rateId] = true;
        }

        emit Bond(proposer, rateIds);
    }

    /// @notice Unbond the caller for a given `rateId` and send the bonded amount to `receiver`
    /// Proposers can retrieve their bond if either:
    /// - the last proposal was made by another proposer,
    /// - `disputeWindow` for the last proposal has elapsed,
    /// - `rateId` is inactive
    /// @dev Reverts if the caller is not bonded for a given `rateId`
    /// @param rateId RateId for which to unbond
    /// @param lastProposerForRateId Address of the last proposer for `rateId`
    /// @param value Value of the current proposal made for `rateId`
    /// @param nonce Nonce of the current proposal made for `rateId`
    /// @param receiver Address of the recipient of the bonded amount
    function unbond(
        bytes32 rateId,
        address lastProposerForRateId,
        uint256 value,
        bytes32 nonce,
        address receiver
    ) public override(IOptimisticOracle) {
        bytes32 proposalId = computeProposalId(
            rateId,
            lastProposerForRateId,
            value,
            nonce
        );

        // revert if `proposalId` is invalid
        if (proposals[rateId] != proposalId)
            revert OptimisticOracle__unbond_invalidProposal();

        // revert if the `proposer` is `msg.sender` and the dispute window is active
        // skipping and allowing unbond if the rate is removed is intended
        if (
            lastProposerForRateId == msg.sender &&
            activeRateIds[rateId] &&
            canDispute(nonce)
        ) {
            revert OptimisticOracle__unbond_isProposing();
        }

        // revert if `msg.sender` is not bonded
        if (!isBonded(msg.sender, rateId))
            revert OptimisticOracle__unbond_unbondedProposer();

        delete bonds[msg.sender][rateId];
        bondToken.safeTransfer(receiver, bondSize);

        emit Unbond(msg.sender, rateId, receiver);
    }

    /// @notice Claims the bond of `proposer` for `rateId` and sends the bonded amount (`bondSize`) of `bondToken`
    /// to `receiver`
    /// @dev Does not revert if the `proposer` is unbonded for a given `rateId` to avoid deadlocks
    /// @param proposer Address of the proposer from which to claim the bond
    /// @param rateId RateId for which the proposer bonded
    /// @param receiver Address of the recipient of the claimed bond
    function _claimBond(
        address proposer,
        bytes32 rateId,
        address receiver
    ) internal returns (bool) {
        if (!isBonded(proposer, rateId)) return false;

        // clear bond
        delete bonds[proposer][rateId];

        // avoids blocking the dispute in case the transfer fails
        try bondToken.transfer(receiver, bondSize) {} catch {}

        emit ClaimBond(proposer, rateId, receiver);

        return true;
    }

    /// @notice Checks that `proposer` is bonded for a given `rateId`
    /// @param proposer Address of the proposer
    /// @param rateId RateId
    /// @return isBonded True if `proposer` is bonded
    function isBonded(address proposer, bytes32 rateId)
        public
        view
        override(IOptimisticOracle)
        returns (bool)
    {
        return bonds[proposer][rateId];
    }

    /// @notice Allow `proposer` to call `bond`
    /// @dev Sender has to be allowed to call this method
    /// @param proposer Address of the proposer
    function allowProposer(address proposer)
        external
        override(IOptimisticOracle)
        checkCaller
    {
        _allowCaller(bytes4(keccak256("bond(bytes32[])")), proposer);
    }

    /// ======== Shutdown ======== ///

    /// @notice Locks `shift`, `dispute` operations for a given set of `rateId`s.
    /// @dev Sender has to be allowed to call this method. Reverts if the rate was already unregistered.
    /// @param rateIds RateIds for which to lock `shift` and `dispute`
    function lock(bytes32[] calldata rateIds)
        public
        override(IOptimisticOracle)
        checkCaller
    {
        uint256 length = rateIds.length;
        for (uint256 rateIdx = 0; rateIdx < length; ) {
            deactivateRateId(rateIds[rateIdx]);
            unchecked {
                ++rateIdx;
            }
        }

        emit Lock();
    }

    /// @notice Allows proposers to withdraw their bond for a given `rateId` in case after the oracle is locked
    /// @param rateId RateId for which the proposer wants to withdraw the bond
    /// @param receiver Address that will receive the bond
    function recover(bytes32 rateId, address receiver)
        public
        override(IOptimisticOracle)
    {
        if (activeRateIds[rateId]) {
            revert OptimisticOracle__recover_notLocked();
        }

        // transfer and clear the bond
        if (!_claimBond(msg.sender, rateId, receiver)) {
            revert OptimisticOracle__recover_unbondedProposer();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Copied from:
/// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
/// at commit a64a7fc38b647c490416091bccf39e85ded3961d
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IOptimistic3PoolChainlinkValue {
    function value() external view returns (uint256 value_, bytes memory data);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IOptimisticOracle {
    event Propose(bytes32 indexed rateId, bytes32 nonce);

    event Dispute(
        bytes32 indexed rateId,
        address indexed proposer,
        address indexed disputer,
        uint256 proposedValue,
        uint256 validValue
    );

    event Validate(
        bytes32 indexed token,
        address indexed proposer,
        uint256 result
    );
    event Push(bytes32 indexed rateId, bytes32 nonce, uint256 value);
    event Bond(address indexed proposer, bytes32[] rateIds);
    event Unbond(address indexed proposer, bytes32 rateId, address receiver);
    event ClaimBond(address indexed proposer, bytes32 rateId, address receiver);
    event Lock();

    function target() external view returns (address);

    function bondToken() external view returns (IERC20);

    function bondSize() external view returns (uint256);

    function oracleType() external view returns (bytes32);

    function disputeWindow() external view returns (uint256);

    function proposals(bytes32 rateId) external view returns (bytes32);

    function activeRateIds(bytes32 rateId) external view returns (bool);

    function bonds(address, bytes32) external view returns (bool);

    function bond(address proposer, bytes32[] calldata rateIds) external;

    function bond(bytes32[] calldata rateIds) external;

    function unbond(
        bytes32 rateId,
        address proposer,
        uint256 value,
        bytes32 nonce,
        address receiver
    ) external;

    function isBonded(address proposer, bytes32 rateId)
        external
        view
        returns (bool);

    function shift(
        bytes32 rateId,
        address prevProposer,
        uint256 prevValue,
        bytes32 prevNonce,
        uint256 value,
        bytes memory data
    ) external;

    function dispute(
        bytes32 rateId,
        address proposer,
        address receiver,
        uint256 value_,
        bytes32 nonce,
        bytes memory data
    ) external;

    function validate(
        uint256 proposedValue,
        bytes32 rateId,
        bytes32 nonce,
        bytes memory data
    )
        external
        returns (
            uint256,
            uint256,
            bytes memory
        );

    function push(bytes32 rateId) external;

    function encodeNonce(bytes32 prevNonce, bytes memory data)
        external
        view
        returns (bytes32);

    function decodeNonce(bytes32 nonce)
        external
        view
        returns (bytes32 dataHash, uint64 proposeTimestamp);

    function canDispute(bytes32 nonce) external view returns (bool);

    function allowProposer(address proposer) external;

    function lock(bytes32[] calldata rateIds_) external;

    function recover(bytes32 rateId, address receiver) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IGuarded} from "../../interfaces/IGuarded.sol";

/// @title Guarded
/// @notice Mixin implementing an authentication scheme on a method level
abstract contract Guarded is IGuarded {
    /// ======== Custom Errors ======== ///

    error Guarded__notRoot();
    error Guarded__notGranted();

    /// ======== Storage ======== ///

    /// @notice Wildcard for granting a caller to call every guarded method
    bytes32 public constant override ANY_SIG = keccak256("ANY_SIG");
    /// @notice Wildcard for granting a caller to call every guarded method
    address public constant override ANY_CALLER = address(uint160(uint256(bytes32(keccak256("ANY_CALLER")))));

    /// @notice Mapping storing who is granted to which method
    /// @dev Method Signature => Caller => Bool
    mapping(bytes32 => mapping(address => bool)) private _canCall;

    /// ======== Events ======== ///

    event AllowCaller(bytes32 sig, address who);
    event BlockCaller(bytes32 sig, address who);

    constructor() {
        // set root
        _setRoot(msg.sender);
    }

    /// ======== Auth ======== ///

    modifier callerIsRoot() {
        if (_canCall[ANY_SIG][msg.sender]) {
            _;
        } else revert Guarded__notRoot();
    }

    modifier checkCaller() {
        if (canCall(msg.sig, msg.sender)) {
            _;
        } else revert Guarded__notGranted();
    }

    /// @notice Grant the right to call method `sig` to `who`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function _allowCaller(bytes32 sig, address who) internal {
        _canCall[sig][who] = true;
        emit AllowCaller(sig, who);        
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should not be able to call `sig` anymore
    function _blockCaller(bytes32 sig, address who) internal {
        _canCall[sig][who] = false;
        emit BlockCaller(sig, who);
    }

    /// @notice Sets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be set as root
    function _setRoot(address root) internal {
        _allowCaller(ANY_SIG, root);
    }

    /// @notice Unsets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be unset as root
    function _unsetRoot(address root) internal {
        _blockCaller(ANY_SIG, root);
    }

    /// @notice Grant the right to call method `sig` to `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function allowCaller(bytes32 sig, address who) public override callerIsRoot {
        _allowCaller(sig, who);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig, address who) public override callerIsRoot {
        _blockCaller(sig, who);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function canCall(bytes32 sig, address who) public view override returns (bool) {
        return (_canCall[sig][who] || _canCall[ANY_SIG][who] || _canCall[sig][ANY_CALLER]);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
pragma solidity ^0.8.4;

uint256 constant MLN = 10**6;
uint256 constant BLN = 10**9;
uint256 constant WAD = 10**18;
uint256 constant RAY = 10**18;
uint256 constant RAD = 10**18;

/* solhint-disable func-visibility, no-inline-assembly */

error Math__toInt256_overflow(uint256 x);

function toInt256(uint256 x) pure returns (int256) {
    if (x > uint256(type(int256).max)) revert Math__toInt256_overflow(x);
    return int256(x);
}

function min(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x <= y ? x : y;
    }
}

function max(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x >= y ? x : y;
    }
}

error Math__diff_overflow(uint256 x, uint256 y);

function diff(uint256 x, uint256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) - int256(y);
        if (!(int256(x) >= 0 && int256(y) >= 0)) revert Math__diff_overflow(x, y);
    }
}

error Math__add_overflow(uint256 x, uint256 y);

function add(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add_overflow(x, y);
    }
}

error Math__add48_overflow(uint256 x, uint256 y);

function add48(uint48 x, uint48 y) pure returns (uint48 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add48_overflow(x, y);
    }
}

error Math__add_overflow_signed(uint256 x, int256 y);

function add(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x + uint256(y);
        if (!(y >= 0 || z <= x)) revert Math__add_overflow_signed(x, y);
        if (!(y <= 0 || z >= x)) revert Math__add_overflow_signed(x, y);
    }
}

error Math__sub_overflow(uint256 x, uint256 y);

function sub(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x - y) > x) revert Math__sub_overflow(x, y);
    }
}

error Math__sub_overflow_signed(uint256 x, int256 y);

function sub(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x - uint256(y);
        if (!(y <= 0 || z <= x)) revert Math__sub_overflow_signed(x, y);
        if (!(y >= 0 || z >= x)) revert Math__sub_overflow_signed(x, y);
    }
}

error Math__mul_overflow(uint256 x, uint256 y);

function mul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (!(y == 0 || (z = x * y) / y == x)) revert Math__mul_overflow(x, y);
    }
}

error Math__mul_overflow_signed(uint256 x, int256 y);

function mul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) * y;
        if (int256(x) < 0) revert Math__mul_overflow_signed(x, y);
        if (!(y == 0 || z / y == int256(x))) revert Math__mul_overflow_signed(x, y);
    }
}

function wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, y) / WAD;
    }
}

function wmul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = mul(x, y) / int256(WAD);
    }
}

error Math__div_overflow(uint256 x, uint256 y);

function div(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (y == 0) revert Math__div_overflow(x, y);
        return x / y;
    }
}

function wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, WAD) / y;
    }
}

// optimized version from dss PR #78
function wpow(
    uint256 x,
    uint256 n,
    uint256 b
) pure returns (uint256 z) {
    unchecked {
        assembly {
            switch n
            case 0 {
                z := b
            }
            default {
                switch x
                case 0 {
                    z := 0
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if shr(128, x) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }
}

/* solhint-disable func-visibility, no-inline-assembly */

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface ICodex {
    function init(address vault) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address,
        bytes32,
        uint256
    ) external;

    function credit(address) external view returns (uint256);

    function unbackedDebt(address) external view returns (uint256);

    function balances(
        address,
        uint256,
        address
    ) external view returns (uint256);

    function vaults(address vault)
        external
        view
        returns (
            uint256 totalNormalDebt,
            uint256 rate,
            uint256 debtCeiling,
            uint256 debtFloor
        );

    function positions(
        address vault,
        uint256 tokenId,
        address position
    ) external view returns (uint256 collateral, uint256 normalDebt);

    function globalDebt() external view returns (uint256);

    function globalUnbackedDebt() external view returns (uint256);

    function globalDebtCeiling() external view returns (uint256);

    function delegates(address, address) external view returns (uint256);

    function grantDelegate(address) external;

    function revokeDelegate(address) external;

    function modifyBalance(
        address,
        uint256,
        address,
        int256
    ) external;

    function transferBalance(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        uint256 amount
    ) external;

    function transferCredit(
        address src,
        address dst,
        uint256 amount
    ) external;

    function modifyCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function transferCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function confiscateCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function settleUnbackedDebt(uint256 debt) external;

    function createUnbackedDebt(
        address debtor,
        address creditor,
        uint256 debt
    ) external;

    function modifyRate(
        address vault,
        address creditor,
        int256 rate
    ) external;

    function live() external view returns (uint256);

    function lock() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {ICodex} from "./ICodex.sol";

interface IPriceFeed {
    function peek() external returns (bytes32, bool);

    function read() external view returns (bytes32);
}

interface ICollybus {
    function vaults(address) external view returns (uint128, uint128);

    function spots(address) external view returns (uint256);

    function rates(uint256) external view returns (uint256);

    function rateIds(address, uint256) external view returns (uint256);

    function redemptionPrice() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address vault,
        bytes32 param,
        uint128 data
    ) external;

    function setParam(
        address vault,
        uint256 tokenId,
        bytes32 param,
        uint256 data
    ) external;

    function updateDiscountRate(uint256 rateId, uint256 rate) external;

    function updateSpot(address token, uint256 spot) external;

    function read(
        address vault,
        address underlier,
        uint256 tokenId,
        uint256 maturity,
        bool net
    ) external view returns (uint256 price);

    function lock() external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface IGuarded {
    function ANY_SIG() external view returns (bytes32);

    function ANY_CALLER() external view returns (address);

    function allowCaller(bytes32 sig, address who) external;

    function blockCaller(bytes32 sig, address who) external;

    function canCall(bytes32 sig, address who) external view returns (bool);
}