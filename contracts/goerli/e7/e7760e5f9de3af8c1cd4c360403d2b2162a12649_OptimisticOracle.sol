// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Guarded} from "fiat/utils/Guarded.sol";
import {ICollybus} from "fiat/interfaces/ICollybus.sol";

import {IValidator} from "./interfaces/IValidator.sol";
import {IChainlinkValidator} from "./interfaces/IChainlinkValidator.sol";
import {IProofValidator} from "./interfaces/IProofValidator.sol";

/// @title OptimisticOracle
/// @notice The Optimistic Oracle allows for gas-efficient oracle value updates.
/// Bonded proposers can optimistically propose a value for the next spot and discount rate for a given RateId which
/// can be disputed within `disputeWindow` by computing the value on-chain.
/// Proposers are not rewarded for doing so directly and instead are only compensated in the event that they call the
/// `dispute` function, as `dispute` is a gas intensive operation due to its computation of the expected value on-chain.
/// Compensation is sourced from the bond put up by the malicious proposer.

contract OptimisticOracle is Guarded {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error OptimisticOracle__setParam_unrecognizedParam();
    error OptimisticOracle__setRateConfig_rateConfigSet(bytes32 rateId);
    error OptimisticOracle__unsetRateConfig_rateNotFound(bytes32 rateId);
    error OptimisticOracle__shift_invalidPreviousProposal();
    error OptimisticOracle__shift_canNotShift();
    error OptimisticOracle__shift_unbondedProposer();
    error OptimisticOracle__dispute_rateConfigNotSet();
    error OptimisticOracle__dispute_invalidDispute();
    error OptimisticOracle__push_invalidRelayerType(RateType relayerType);
    error OptimisticOracle__settleDispute_unknownProposal();
    error OptimisticOracle__settleDispute_alreadyDisputed();
    error OptimisticOracle__bond_bondedProposer(bytes32 rateId);
    error OptimisticOracle__bond_noRateConfig(bytes32 rateId);
    error OptimisticOracle__unbond_unbondedProposer();
    error OptimisticOracle__unbond_isProposing();
    error OptimisticOracle__claimBond_unbondedProposer();

    /// ======== Clear bond

    /// @notice Collybus rate types
    enum RateType {
        // Discount Rate
        Discount,
        // Spot Rate
        Spot
    }

    /// @notice Rate configuration
    struct RateConfig {
        // Address of the Validator
        address validator;
        // Encoded rate type (see RateType)
        uint96 rateType;
    }

    /// @notice Address of Collybus
    address public immutable collybus;
    /// @notice Address of the token for which a proposer puts up a bond
    IERC20 public immutable bondToken;
    /// @notice Amount of `bondToken` proposers have to bond for each "rate feed" [scale of bondToken]
    uint256 public immutable bondSize;

    /// @notice Map of ProposalIds by RateId
    /// For each "rate feed" (id. by RateId) only the current proposal is stored.
    /// Instead of storing all the data associated with a proposal, only the keccak256 hash of the data
    /// is stored as the ProposalId. The ProposalId is derived via `computeProposalId`.
    /// @dev RateId => ProposalId
    mapping(bytes32 => bytes32) public proposals;

    /// @notice Map of RateConfigs for each RateId
    /// @dev RateId => RateConfig
    mapping(bytes32 => RateConfig) public rateConfigs;

    /// @notice Mapping of Bonds
    /// The Optimistic Oracle needs to ensure that there's a bond attached to every proposal made which can be claimed
    /// if the proposal is incorrect. In practice this requires that:
    /// - a proposer can't reuse their bond for multiple proposals (for the same or different rateIds)
    /// - a proposer can't unbond a proposal which hasn't passed `disputeWindow`
    /// For each "rate feed" (id. by RateId) it is required that a proposer submit proposals with a bond of `bondSize`.
    /// @dev Proposer => RateId => bonded
    mapping(address => mapping(bytes32 => bool)) public bonds;

    /// ======== Events ======== ///

    event SetParam(bytes32 rateId, bytes32 param, address value);
    event Push(bytes32 rateId, uint256 value);
    event Propose(
        bytes32 rateId,
        address proposer,
        uint256 value,
        bytes32 nonce
    );
    event Dispute(
        bytes32 rateId,
        address proposer,
        address disputer,
        uint256 proposedValue,
        uint256 validatorValue
    );
    event Bond(address proposer, bytes32[] rateIds);
    event Unbond(address proposer, bytes32 rateId, address receiver);
    event ClaimBond(address proposer, bytes32 rateId, address receiver);

    /// @param collybus_ Address of Collybus
    /// @param bondToken_ Address of the ERC20 token used by the bonding proposers
    /// @param bondSize_ Amount of `bondToken` a proposer has to bond in order to submit proposals for each `rateId`
    constructor(
        address collybus_,
        IERC20 bondToken_,
        uint256 bondSize_
    ) {
        collybus = collybus_;
        bondToken = bondToken_;
        bondSize = bondSize_;
    }

    /// ======== Configuration ======== ///

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param rateId RateId
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable
    function setParam(
        bytes32 rateId,
        bytes32 param,
        address data
    ) public checkCaller {
        if (param == "validator") {
            rateConfigs[rateId].validator = data;
        } else revert OptimisticOracle__setParam_unrecognizedParam();

        emit SetParam(rateId, param, data);
    }

    /// @notice Sets the initial configuration for a RateId
    /// @dev Sender has to be allowed to call this method. Reverts if the configuration was already set.
    /// @param rateId RateId (see Collybus)
    /// @param rateType RateType (see Collybus) [Discount, Spot]
    /// @param validator Address of Validator
    function setRateConfig(
        bytes32 rateId,
        uint256 rateType,
        address validator
    ) external checkCaller {
        if (rateConfigs[rateId].validator != address(0)) {
            revert OptimisticOracle__setRateConfig_rateConfigSet(rateId);
        }

        rateConfigs[rateId] = RateConfig(validator, uint96(rateType));

        // Set the initial proposal that will be referenced during the first shift
        proposals[rateId] = computeProposalId(rateId, address(0), 0, 0);
    }

    /// @notice Unsets the current configuration for a RateId
    /// @dev Sender has to be allowed to call this method. Reverts if the configuration was already set.
    /// @param rateId RateId (see Collybus)
    function unsetRateConfig(bytes32 rateId) external checkCaller {
        if (rateConfigs[rateId].validator == address(0)) {
            revert OptimisticOracle__unsetRateConfig_rateNotFound(rateId);
        }

        delete rateConfigs[rateId];
    }

    /// ======== Proposal Management ======== ///

    /// @notice Queues a new proposed `value` for a given `rateId` and pushes `prevValue` to Collybus
    /// @dev Can only be called by a bonded proposer. Reverts if:
    /// - specified previous proposal is invalid
    /// - `proposeWindow` exceeded or `disputeWindow` still active
    /// - if the current proposed value is disputable (`dispute` has to be called beforehand)
    /// For the initial shift for a given `RateId`, `prevProposer`, `prevValue` and `prevNonce` have to be 0.
    /// @param rateId RateId (see Collybus) for which to shift the proposals
    /// @param prevProposer Address of the previous proposer
    /// @param prevValue Value of the previous proposal
    /// @param prevNonce Nonce of the previous proposal [block number, (roundId, roundTimestamp)]
    /// @param value Value of the new proposal [wad]
    /// @param nonce Nonce of the new proposal [block number, (roundId, roundTimestamp)]
    function shift(
        bytes32 rateId,
        address prevProposer,
        uint256 prevValue,
        bytes32 prevNonce,
        uint256 value,
        bytes32 nonce
    ) external {
        // Check that proposer is bonded for the given `rateId`
        if (!isBonded(msg.sender, rateId))
            revert OptimisticOracle__shift_unbondedProposer();

        // Verify that the previous proposal exists
        if (
            proposals[rateId] !=
            computeProposalId(
                rateId,
                prevProposer,
                prevValue,
                uint256(prevNonce)
            )
        ) {
            revert OptimisticOracle__shift_invalidPreviousProposal();
        }

        // Check `disputeWindow` and `proposeWindow` for the previous and the current proposal
        RateConfig memory rateConfig = rateConfigs[rateId];
        if (
            !IValidator(address(rateConfig.validator)).canShift(
                prevNonce,
                nonce
            )
        ) {
            revert OptimisticOracle__shift_canNotShift();
        }

        // Push the previous value to Collybus
        // Skip if `prevNonce` is 0 (initial shift) since it is just a placeholder and not an actual proposal
        if (prevNonce != 0)
            _push(RateType(rateConfig.rateType), rateId, prevValue);

        // Update the proposal with the new values
        proposals[rateId] = computeProposalId(
            rateId,
            msg.sender,
            value,
            uint256(nonce)
        );

        emit Propose(rateId, msg.sender, value, nonce);
    }

    /// @notice Disputes a proposed value using storage-proofs.
    /// The bond of the proposer of the disputed value is sent to the `receiver`.
    /// @param rateId RateId (see Collybus) of the proposal being disputed
    /// @param proposer Address of the proposer of the proposal being disputed
    /// @param receiver Address of the receiver of the `proposer`'s bond
    /// @param value Value of the proposal being disputed [wad]
    /// @param nonce Nonce of the proposal being disputed [block number, (roundId, roundTimestamp)]
    /// @param blockHeaderRlpBytes RLP-encoded blockheader at which the proposed value was derived
    /// @param proofRlpBytes RLP-encoded storage-proof to validate the data used to derive the proposed value
    /// @dev Reverts if the dispute is not valid
    function dispute(
        bytes32 rateId,
        address proposer,
        address receiver,
        uint256 value,
        bytes32 nonce,
        bytes calldata blockHeaderRlpBytes,
        bytes calldata proofRlpBytes
    ) external {
        RateConfig memory rateConfig = rateConfigs[rateId];
        if (rateConfig.validator == address(0))
            revert OptimisticOracle__dispute_rateConfigNotSet();

        // Validate the proposed value via storage-proofs
        (bool proposalIsValid, uint256 verifiedValue) = IProofValidator(
            address(rateConfig.validator)
        ).validate(value, uint256(nonce), blockHeaderRlpBytes, proofRlpBytes);

        // Revert if the proposal is valid
        if (proposalIsValid) revert OptimisticOracle__dispute_invalidDispute();

        _settleDispute(
            rateId,
            proposer,
            receiver,
            value,
            verifiedValue,
            nonce,
            address(rateConfig.validator)
        );
    }

    /// @notice Disputes a proposed value by fetching the correct value from the corresponding Chainlink feed.
    /// The bond of the proposer of the disputed value is sent to the `receiver`.
    /// @param rateId RateId (see Collybus) of the proposal being disputed
    /// @param proposer Address of the proposer of the proposal being disputed
    /// @param receiver Address of the receiver of the `proposer`'s bond
    /// @param value Value of the proposal being disputed [wad]
    /// @param nonce Nonce of the proposal being disputed [block number, (roundId, roundTimestamp)]
    function dispute(
        bytes32 rateId,
        address proposer,
        address receiver,
        uint256 value,
        bytes32 nonce
    ) external {
        RateConfig memory rateConfig = rateConfigs[rateId];
        if (rateConfig.validator == address(0))
            revert OptimisticOracle__dispute_rateConfigNotSet();

        // Validate the proposed value by fetching it from the corresponding Chainlink feed
        (bool proposalIsValid, uint256 verifiedValue) = IChainlinkValidator(
            address(rateConfig.validator)
        ).validate(
                value,
                address(uint160(uint256(rateId))), // RateId encodes the address of the token
                nonce // Nonce encoded the roundId and the roundTimestamp
            );

        // Proposal has to be invalid
        if (proposalIsValid) revert OptimisticOracle__dispute_invalidDispute();

        _settleDispute(
            rateId,
            proposer,
            receiver,
            value,
            verifiedValue,
            nonce,
            address(rateConfig.validator)
        );
    }

    /// @notice Settles the dispute by overwriting the invalid proposal with a new proposal
    /// containing the computed value and claiming the proposer's bond
    /// @param rateId RateId (see Collybus) of the proposal to dispute
    /// @param proposer Address of the proposer of the proposal to dispute
    /// @param receiver Address of the bond receiver
    /// @param value Value of the proposal to dispute [wad]
    /// @param computedValue Value computed by the validator [wad]
    /// @param nonce Nonce of the proposal to dispute [block number, (roundId, roundTimestamp)]
    function _settleDispute(
        bytes32 rateId,
        address proposer,
        address receiver,
        uint256 value,
        uint256 computedValue,
        bytes32 nonce,
        address validator
    ) private {
        if (proposer == validator) {
            revert OptimisticOracle__settleDispute_alreadyDisputed();
        }

        // Verify the proposal data
        if (
            proposals[rateId] !=
            computeProposalId(rateId, proposer, value, uint256(nonce))
        ) {
            revert OptimisticOracle__settleDispute_unknownProposal();
        }

        // Overwrite the proposal with the value computed by the Validator
        proposals[rateId] = computeProposalId(
            rateId,
            address(validator),
            computedValue,
            uint256(nonce)
        );

        emit Propose(rateId, validator, computedValue, nonce);

        // Transfer the bond to the receiver
        _claimBond(proposer, rateId, receiver);

        emit Dispute(rateId, proposer, msg.sender, value, computedValue);
    }

    /// @notice Pushes a proposed value to Collybus
    /// @param rateType RateType (see Collybus) [SpotRate, DiscountRate]
    /// @param rateId RateId (see Collybus)
    /// @param value Value that will be pushed to Collybus [wad]
    function _push(
        RateType rateType,
        bytes32 rateId,
        uint256 value
    ) internal {
        if (rateType == RateType.Discount) {
            ICollybus(collybus).updateDiscountRate(uint256(rateId), value);
        } else if (rateType == RateType.Spot) {
            ICollybus(collybus).updateSpot(
                address(uint160(uint256(rateId))),
                value
            );
        } else {
            revert OptimisticOracle__push_invalidRelayerType(rateType);
        }

        emit Push(rateId, value);
    }

    /// @notice Computes the ProposalId
    /// @param rateId RateId (see Collybus)
    /// @param proposer Address of the proposer
    /// @param value Proposed value [wad]
    /// @param nonce Nonce of the proposal [block number, (roundId, roundTimestamp)]
    /// @return proposalId Computed proposalId
    function computeProposalId(
        bytes32 rateId,
        address proposer,
        uint256 value,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(rateId, proposer, value, nonce));
    }

    /// @notice Returns the Validator address for a given rateId
    /// @param rateId RateId (see Collybus)
    /// @return address Address of the Validator
    function getValidator(bytes32 rateId) external view returns (address) {
        return address(rateConfigs[rateId].validator);
    }

    /// ======== Bond Management ======== ///

    /// @notice Deposits  for a given `proposer` for the specified `rateIds`
    /// in return for an amount of `bondSize` of `bondToken` the `proposer` has to deposit for each specified `rateId`
    /// @dev Requires `proposer` to set an allowance for this contract.
    /// Reverts if `proposer` already deposited a bond for a given `rateId`.
    /// @param proposer Address of the proposer
    /// @param rateIds List of `rateId`'s for each which `proposer` wants to submit proposals for
    /// @return bondedRateIds RateIds for which `proposer` deposited a bond
    function bond(address proposer, bytes32[] calldata rateIds)
        public
        returns (bytes32[] memory bondedRateIds)
    {
        // Transfer the total amount to bond (rateIds.length * bondSize) from the sender
        bondToken.safeTransferFrom(
            msg.sender,
            address(this),
            rateIds.length * bondSize
        );

        // Mark the proposer as bonded for each rateId
        bondedRateIds = new bytes32[](rateIds.length);
        for (uint256 i = 0; i < rateIds.length; ++i) {
            bytes32 rateId = rateIds[i];

            // RateConfig needs to be set
            if (rateConfigs[rateId].validator == address(0)) {
                revert OptimisticOracle__bond_noRateConfig(rateId);
            }

            // `proposer` should be unbonded for the specified `rateId`'s
            if (isBonded(proposer, rateId)) {
                revert OptimisticOracle__bond_bondedProposer(rateId);
            }

            bonds[proposer][rateId] = true;
            bondedRateIds[i] = rateId;
        }

        emit Bond(proposer, bondedRateIds);
    }

    /// @notice Unbond a proposer for a given `rateId` and sends the bonded amount to `receiver`.
    /// Proposers can retrieve their bond if:
    /// - the last proposal was made by another proposer,
    /// - `disputeWindow` for the last proposal has elapsed,
    /// - `RateConfig` has been cleared for a given `RateId`.
    /// @param rateId RateId (see Collybus) for which to unbond
    /// @param value Value of the current proposal made for `rateId`
    /// @param nonce Nonce of the current proposal made for `rateId`
    /// @param receiver Address of the recipient of the bonded amount
    function unbond(
        bytes32 rateId,
        uint256 value,
        bytes32 nonce,
        address receiver
    ) public {
        bytes32 proposalId = computeProposalId(
            rateId,
            msg.sender,
            value,
            uint256(nonce)
        );

        // Current proposal has not been made by `msg.sender` or it has passed `disputeWindow`
        // or the rateConfig has been unset
        RateConfig memory rateConfig = rateConfigs[rateId];
        if (
            proposals[rateId] == proposalId &&
            rateConfig.validator != address(0) &&
            IValidator(rateConfig.validator).canDispute(nonce)
        ) {
            revert OptimisticOracle__unbond_isProposing();
        }

        // `msg.sender` is bonded
        if (!isBonded(msg.sender, rateId))
            revert OptimisticOracle__unbond_unbondedProposer();

        delete bonds[msg.sender][rateId];
        bondToken.safeTransfer(receiver, bondSize);

        emit Unbond(msg.sender, rateId, receiver);
    }

    /// @notice Allows an allowed sender to claim all the bonds in case of an emergency
    /// @dev Sender has to be allowed to call this method
    /// @param proposer Address of the proposer from which to claim the bond
    /// @param rateId RateId (see Collybus) for which the proposer bonded
    /// @param receiver Address of the recipient of the claimed bond
    function claimBond(
        address proposer,
        bytes32 rateId,
        address receiver
    ) external checkCaller {
        if (!isBonded(proposer, rateId))
            revert OptimisticOracle__claimBond_unbondedProposer();
        _claimBond(proposer, rateId, receiver);
    }

    /// @notice Claims the bond of `proposer` for `rateId` and sends the bonded amount (`bondSize`) of `bondToken`
    /// to `recipient`
    /// @dev Does not revert if the `proposer` is unbonded for a given `rateId` to avoid deadlocks
    /// @param proposer Address of the proposer from which to claim the bond
    /// @param rateId RateId (see Collybus) for which the proposer bonded
    /// @param receiver Address of the recipient of the claimed bond
    function _claimBond(
        address proposer,
        bytes32 rateId,
        address receiver
    ) internal {
        if (!isBonded(proposer, rateId)) return;

        // Clear bond
        delete bonds[proposer][rateId];

        // Transfer bonded amount to `receiver`
        bondToken.safeTransfer(receiver, bondSize);

        emit ClaimBond(proposer, rateId, receiver);
    }

    /// @notice Checks that `proposer` is bonded for a given `rateId`
    /// @param proposer Address of the proposer
    /// @param rateId RateId (see Collybus)
    /// @return isBonded True if `proposer` is bonded
    function isBonded(address proposer, bytes32 rateId)
        public
        view
        returns (bool)
    {
        return bonds[proposer][rateId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IGuarded} from "../interfaces/IGuarded.sol";

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
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function allowCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = true;
        emit AllowCaller(sig, who);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = false;
        emit BlockCaller(sig, who);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function canCall(bytes32 sig, address who) public view override returns (bool) {
        return (_canCall[sig][who] || _canCall[ANY_SIG][who] || _canCall[sig][ANY_CALLER]);
    }

    /// @notice Sets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be set as root
    function _setRoot(address root) internal {
        _canCall[ANY_SIG][root] = true;
        emit AllowCaller(ANY_SIG, root);
    }

    /// @notice Unsets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be unset as root
    function _unsetRoot(address root) internal {
        _canCall[ANY_SIG][root] = false;
        emit AllowCaller(ANY_SIG, root);
    }
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IValidator {
    function canShift(bytes32 prevNonce, bytes32 nonce)
        external
        view
        returns (bool);

    function canPropose(bytes32 nonce) external view returns (bool);

    function canDispute(bytes32 nonce) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IValidator} from "./IValidator.sol";

interface IChainlinkValidator {
    function value(address token) external view returns (uint256, bytes32);

    function validate(
        uint256 value_,
        address token,
        bytes32 nonce
    ) external returns (bool, uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IValidator} from "./IValidator.sol";

interface IProofValidator {
    function value() external returns (uint256, bytes32);

    function validate(
        uint256 value_,
        uint256 blockNumber,
        bytes memory blockHeaderRlpBytes,
        bytes memory proofRlpBytes
    ) external returns (bool, uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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