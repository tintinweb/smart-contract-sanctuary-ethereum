// SPDX-License-Identifier: Apache-2.0
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
/// Bonded proposers can optimistically propose the next value for a spot and discount rate which
/// can be disputed within `disputeWindow` by computing the value on-chain.
contract OptimisticOracle is Guarded {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error OptimisticOracle__setRateConfig_rateAlreadyRegistered(bytes32 rateId);
    error OptimisticOracle__unsetRateConfig_rateNotFound(bytes32 rateId);

    error OptimisticOracle__shift_invalidPreviousProposal();
    error OptimisticOracle__shift_canNotShift();

    error OptimisticOracle__dispute_invalidDispute();

    error OptimisticOracle__settleDispute_invalidProposal();
    error OptimisticOracle__settleDispute_alreadyDisputed();

    error OptimisticOracle__push_invalidRelayerType(RateType relayerType);
    error OptimisticOracle__setParam_unrecognizedParam();

    error OptimisticOracle__shift_invalidProposer(
        address proposer,
        bytes32 rateId
    );
    error OptimisticOracle__claimBond_invalidProposerKey(bytes32 proposerKey);
    error OptimisticOracle__obtainProposerKey_alreadyRegisteredForRate(
        bytes32 rateId,
        bytes32 proposerKey
    );
    error OptimisticOracle__returnProposerKey_invalidParams();

    /// ======== Storage ======== ///

    /// @notice Collybus rate types
    enum RateType {
        // Discount Rate
        Discount,
        // Spot Rate
        Spot
    }

    /// @notice Rate configuration
    struct RateConfig {
        // Encoded address of the Validator
        uint160 validator;
        // Encoded rate type (see RateType)
        uint96 rateType;
    }

    /// @notice Address of Collybus
    address public immutable collybus;
    /// @notice Address of the token used for the `proposerKey` bond
    IERC20 public immutable bondToken;
    /// @notice Amount of `bondToken` proposers have to bond for each `proposerKey` [scale of bondToken]
    uint256 public immutable bondSize;

    /// @notice Map of ProposalIds by RateId
    /// @dev RateId => ProposalId
    mapping(bytes32 => bytes32) public proposals;

    /// @notice Map of rate configs for each RateId
    /// @dev RateId => RateConfig
    mapping(bytes32 => RateConfig) public rates;

    ///@notice Mapping of ProposerKeys
    ///@dev ProposerKey => isActive
    mapping(bytes32 => bool) public proposerKeys;

    /// ======== Events ======== ///

    event SetParam(bytes32 rateId, bytes32 param, address value);
    event Push(bytes32 rateId, uint256 value);
    event Propose(
        bytes32 rateId,
        bytes32 proposerKey,
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
    event ObtainProposerKey(address proposer, bytes32[] proposerKeys);
    event ReturnProposerKey(
        bytes32 proposerKey,
        bytes32 rateId,
        address receiver
    );
    event TransferBond(address receiver, bytes32 proposerKey);

    /// @param collybus_ Address of Collybus
    /// @param bondToken_ Address of the ERC20 token used for bonding proposers
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
            rates[rateId].validator = uint160(data);
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
        if (rates[rateId].validator != 0) {
            revert OptimisticOracle__setRateConfig_rateAlreadyRegistered(
                rateId
            );
        }

        rates[rateId] = RateConfig(uint160(validator), uint96(rateType));

        // Set the initial proposal that will be referenced during the first shift
        proposals[rateId] = computeProposalId(0, 0, 0);
    }

    /// @notice Unsets the current configuration for a RateId
    /// @dev Sender has to be allowed to call this method. Reverts if the configuration was already set.
    /// @param rateId RateId (see Collybus)
    function unsetRateConfig(bytes32 rateId) external checkCaller {
        if (rates[rateId].validator == 0) {
            revert OptimisticOracle__unsetRateConfig_rateNotFound(rateId);
        }

        delete rates[rateId];
    }

    /// ======== Rate Proposal Management ======== ///

    /// @notice Queues a new proposed `value` for a given `rateId` and pushes `prevValue` to Collybus
    /// @dev Can only be called using an active `ProposerKey`. Reverts if:
    /// - invalid previous proposal
    /// - `proposeWindow` exceeded or `disputeWindow` still active
    /// - if the current proposed value is disputable then `dispute` method should be used instead of `shift`.
    /// For the initial shift for a given `RateId` `prevProposerKey`, `prevValue` and `prevNonce` have to be 0.
    /// @param rateId RateId (see Collybus) for which to shift the proposals
    /// @param prevProposerKey ProposerKey used for the previous proposal
    /// @param prevValue Value of the previous proposal
    /// @param prevNonce Nonce of the previous proposal [block number, (roundId, roundTimestamp)]
    /// @param value Value of the new proposal [wad]
    /// @param nonce Nonce of the new proposal [block number, (roundId, roundTimestamp)]
    function shift(
        bytes32 rateId,
        bytes32 prevProposerKey,
        uint256 prevValue,
        bytes32 prevNonce,
        uint256 value,
        bytes32 nonce
    ) external {
        // Check if the proposerKey is registered
        bytes32 proposerKey = computeProposerKey(msg.sender, rateId);
        if (!proposerKeys[proposerKey]) {
            revert OptimisticOracle__shift_invalidProposer(msg.sender, rateId);
        }

        bytes32 prevProposalId = computeProposalId(
            prevProposerKey,
            prevValue,
            uint256(prevNonce)
        );

        // Verify that the previous proposal exists
        if (proposals[rateId] != prevProposalId) {
            revert OptimisticOracle__shift_invalidPreviousProposal();
        }

        // Check `disputeWindow` and `proposeWindow` for the previous and the current proposal
        RateConfig memory rateConfig = rates[rateId];
        if (
            !IValidator(address(rateConfig.validator)).canShift(
                prevNonce,
                nonce
            )
        ) {
            revert OptimisticOracle__shift_canNotShift();
        }

        // Push previous proposed value to Collybus
        // Skip if `prevNonce` is 0 (initial shift) since it is just a placeholder and not an actual proposal
        if (prevNonce != 0) {
            _push(RateType(rateConfig.rateType), rateId, prevValue);
        }

        // Update the proposal with the new values
        proposals[rateId] = computeProposalId(
            proposerKey,
            value,
            uint256(nonce)
        );

        emit Propose(rateId, proposerKey, value, nonce);
    }

    /// @notice Disputes a proposed value using storage-proofs and pushes the computed value to Collybus.
    /// The bond of the proposers `proposerKey` of the disputed value is send to the `receiver`.
    /// @param rateId RateId (see Collybus) of the proposal to dispute
    /// @param proposer Address of the proposer of the proposal to dispute
    /// @param receiver Address of the bond receiver
    /// @param value Value of the proposal to dispute [wad]
    /// @param nonce Nonce of the proposal to dispute [block number, (roundId, roundTimestamp)]
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
        RateConfig memory rateConfig = rates[rateId];
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

    /// @notice Disputes a proposed value by fetching the correct value from the corresponding Chainlink
    /// feed and pushes it to Collybus.
    /// The bond of the proposers `proposerKey` of the disputed value is send to the `receiver`.
    /// @param rateId RateId (see Collybus) of the proposal to dispute
    /// @param proposer Address of the proposer of the proposal to dispute
    /// @param receiver Address of the bond receiver
    /// @param value Value of the proposal to dispute [wad]
    /// @param nonce Nonce of the proposal to dispute [block number, (roundId, roundTimestamp)]
    /// @dev Reverts if the dispute is not valid
    function dispute(
        bytes32 rateId,
        address proposer,
        address receiver,
        uint256 value,
        bytes32 nonce
    ) external {
        RateConfig memory rateConfig = rates[rateId];
        // Validate the proposed value by fetching it from the corresponding Chainlink feed
        (bool proposalIsValid, uint256 verifiedValue) = IChainlinkValidator(
            address(rateConfig.validator)
        ).validate(
                value,
                address(uint160(uint256(rateId))), // RateId encodes the address of the token
                nonce // Nonce encoded the roundId and the roundTimestamp
            );

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

    /// @notice Settles the dispute, removes the invalid proposal, creates a new proposal
    /// with the verified value and transfers the bond
    /// @param rateId RateId (see Collybus) of the proposal to dispute
    /// @param proposer Address of the proposer of the proposal to dispute
    /// @param receiver Address of the bond receiver
    /// @param value Value of the proposal to dispute [wad]
    /// @param verifiedValue Value retrieved from the validator [wad]
    /// @param nonce Nonce of the proposal to dispute [block number, (roundId, roundTimestamp)]
    /// @dev Reverts if the dispute is not valid
    function _settleDispute(
        bytes32 rateId,
        address proposer,
        address receiver,
        uint256 value,
        uint256 verifiedValue,
        bytes32 nonce,
        address validator
    ) private {
        if (proposer == validator) {
            revert OptimisticOracle__settleDispute_alreadyDisputed();
        }

        // Verify the previous proposal
        bytes32 proposerKey = computeProposerKey(proposer, rateId);
        bytes32 disputedProposalId = computeProposalId(
            proposerKey,
            value,
            uint256(nonce)
        );

        if (proposals[rateId] != disputedProposalId) {
            revert OptimisticOracle__settleDispute_invalidProposal();
        }

        bytes32 validatorProposerKey = computeProposerKey(
            address(validator),
            rateId
        );
        // Update the proposal with the validated data
        bytes32 validatedProposalId = computeProposalId(
            validatorProposerKey,
            verifiedValue,
            uint256(nonce)
        );
        proposals[rateId] = validatedProposalId;

        emit Propose(rateId, validatorProposerKey, verifiedValue, nonce);

        // Transfer the bond to the receiver
        _claimBond(proposerKey, receiver);

        emit Dispute(rateId, proposer, msg.sender, value, verifiedValue);
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
    /// @param proposerKey ProposerKey used to submit the proposal
    /// @param value Proposed value [wad]
    /// @param nonce Nonce of the proposal [block number, (roundId, roundTimestamp)]
    /// @return proposalId Computed proposalId
    function computeProposalId(
        bytes32 proposerKey,
        uint256 value,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(proposerKey, value, nonce));
    }

    /// @notice Returns the Validator address for a given rateId
    /// @param rateId RateId (see Collybus)
    /// @return address Address of the Validator
    function getValidator(bytes32 rateId) external view returns (address) {
        return address(rates[rateId].validator);
    }

    /// ======== Value Proposer Management ======== ///

    /// @notice Assigns a new `proposerKey` to `proposer`
    /// in return for an amount of `bondSize` of `bondToken` the `proposer` has to deposit for each specified `rateId`
    /// @dev Requires `proposer` to set an allowance for this contract.
    /// Reverts if `proposer` already obtained a `proposerKey` for a given `rateId`.
    /// @param proposer Address of the proposer
    /// @param rateIds List of `rateId`'s for each which `proposer` wants to submit proposals for
    /// @return obtainedProposerKeys Obtained `proposerKeys`
    function obtainProposerKey(address proposer, bytes32[] calldata rateIds)
        public
        returns (bytes32[] memory obtainedProposerKeys)
    {
        // Transfer the total amount to bond (rateIds.length * bondSize) from the sender
        uint256 len = rateIds.length;
        bondToken.safeTransferFrom(msg.sender, address(this), len * bondSize);

        // Create and store a proposerKey for each rateId
        obtainedProposerKeys = new bytes32[](len);
        for (uint256 i = 0; i < len; ++i) {
            bytes32 proposerKey = computeProposerKey(proposer, rateIds[i]);

            // Revert if proposerKey has already been assigned
            if (proposerKeys[proposerKey]) {
                revert OptimisticOracle__obtainProposerKey_alreadyRegisteredForRate(
                    rateIds[i],
                    proposerKey
                );
            }

            // Store the proposerKey
            proposerKeys[proposerKey] = true;
            obtainedProposerKeys[i] = proposerKey;
        }

        emit ObtainProposerKey(proposer, obtainedProposerKeys);
    }

    /// @notice Un-registers the caller as a proposer.
    /// Deletes the proposerKey and transfers the bond value back to a specified receiver.
    /// @param rateId The rate id
    /// @param proposerKey The proposer key used to make the active proposal
    /// @param value The value of the current proposal
    /// @param nonce The nonce of the current proposal
    /// @param receiver The address of the bond receiver
    /// @dev Reverts if the active proposal was made by the caller
    /// @dev Reverts if the caller is not a proposer
    /// @dev Reverts if the total bond value transfer fails.
    function returnProposerKey(
        bytes32 rateId,
        bytes32 proposerKey,
        uint256 value,
        bytes32 nonce,
        address receiver
    ) public {
        bytes32 proposalId = computeProposalId(
            proposerKey,
            value,
            uint256(nonce)
        );

        if (proposals[rateId] != proposalId) {
            revert OptimisticOracle__returnProposerKey_invalidParams();
        }

        bytes32 callerProposerKey = computeProposerKey(msg.sender, rateId);
        // Check if the active proposal was made by the caller
        if (callerProposerKey == proposerKey) {
            revert OptimisticOracle__returnProposerKey_invalidParams();
        }

        // Check if the key is valid
        if (!proposerKeys[callerProposerKey]) {
            revert OptimisticOracle__returnProposerKey_invalidParams();
        }

        delete proposerKeys[callerProposerKey];
        bondToken.safeTransfer(receiver, bondSize);

        emit ReturnProposerKey(proposerKey, rateId, receiver);
    }

    /// @notice Returns whether a user is a proposer for a rateId
    /// @param user Address of the user that will be verified
    /// @param rateId The rateId
    function isProposer(address user, bytes32 rateId)
        public
        view
        returns (bool)
    {
        return proposerKeys[computeProposerKey(user, rateId)];
    }

    /// @notice Checks if `proposer` has a `proposerKey` for a given `rateId`
    /// @param proposer Address of the proposer
    /// @param rateId RateId (see Collybus)
    /// @return hasProposerKey True if `proposer` has `proposerKey`
    function hasProposerKey(address proposer, bytes32 rateId)
        public
        view
        returns (bool)
    {
        return proposerKeys[computeProposerKey(proposer, rateId)];
    }

    /// @notice Returns the `proposerKey` for a given `proposer` and `rateId`
    /// @param proposer Address of the proposer
    /// @param rateId RateId (see Collybus)
    function computeProposerKey(address proposer, bytes32 rateId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(proposer, rateId));
    }

    /// @notice Clears a `proposerKey` and sends the `bondSize` amount of `bondToken` to `recipient`
    /// @dev Reverts if the `proposerKey` does not exist
    /// @param proposerKey ProposerKey for which to claim the bonded amount
    /// @param receiver Address of the recipient of the claimed bond
    function _claimBond(bytes32 proposerKey, address receiver) internal {
        if (!proposerKeys[proposerKey]) {
            revert OptimisticOracle__claimBond_invalidProposerKey(proposerKey);
        }

        // Clear `proposerKey`
        delete proposerKeys[proposerKey];

        // Transfer bonded amount to `receiver`
        bondToken.safeTransfer(receiver, bondSize);

        emit TransferBond(receiver, proposerKey);
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

// SPDX-License-Identifier: Unlicensed
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IValidator {
    function canShift(bytes32 prevNonce, bytes32 nonce)
        external
        view
        returns (bool);

    function canPropose(bytes32 nonce) external view returns (bool);

    function canDispute(bytes32 nonce) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {IValidator} from "./IValidator.sol";

interface IChainlinkValidator {
    function value(address tokenAddress)
        external
        view
        returns (uint256, bytes32);

    function validate(
        uint256 value_,
        address tokenAddress,
        bytes32 nonce
    ) external returns (bool, uint256);
}

// SPDX-License-Identifier: Apache-2.0
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

    function lock() external;
}