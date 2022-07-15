// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Guarded} from "fiat/utils/Guarded.sol";
import {ICollybus} from "fiat/interfaces/ICollybus.sol";
import {IValidator} from "./interfaces/IValidator.sol";
import {IChainlinkValidator} from "./interfaces/IChainlinkValidator.sol";
import {IProofValidator} from "./interfaces/IProofValidator.sol";
import {BondManager} from "./BondManager.sol";

contract OptimisticOracle is Guarded, BondManager {
    /// ======== Errors ======== ///
    error OptimisticOracle__registerRate_rateAlreadyRegistered(bytes32 rateId_);
    error OptimisticOracle__registerRate_rateNotFound(bytes32 rateId_);
    error OptimisticOracle__unregisterRate_rateNotFound(bytes32 rateId_);

    error OptimisticOracle__propose_invalidBlockNumber(bytes32 rateId_);
    error OptimisticOracle__propose_inDispute(bytes32 rateId_);

    error OptimisticOracle__shift_invalidPreviousProposal(bytes32 rateId_);
    error OptimisticOracle__shift_invalidParams(bytes32 rateId_);

    error OptimisticOracle__disputeCheck_rateNotRegistered(bytes32 rateId_);
    error OptimisticOracle__disputeCheck_invalidProposal(bytes32 rateId_);
    error OptimisticOracle__disputeCheck_invalidDispute(bytes32 rateId_);

    error OptimisticOracle__updateCollybus_invalidRelayerType(
        uint256 relayerType_
    );

    error OptimisticOracle__setParam_unrecognizedParam(
        bytes32 rateId_,
        bytes32 param_
    );

    /// ======== Events ======== ///
    event SetParam(bytes32 rateId_, bytes32 param_, bytes32 value_);
    event Shift(
        bytes32 rateId_,
        address proposer_,
        bytes32 proposalId_,
        uint256 value_,
        bytes32 auxData_
    );
    event DisputeValue(
        address disputer_,
        bytes32 rateId_,
        uint256 verifiedValue_,
        uint256 proposedValue_,
        bool disputeIsValid_
    );

    /// ======== Enums ======== ///
    enum RateType {
        Discount,
        Spot,
        COUNT
    }

    enum ProposalState {
        // No active proposals are made for this rate
        Inactive,
        // There is an active proposal which is in the dispute window
        Active,
        // When a proposal was disputed and settled
        Executed
    }

    /// ======== Structs ======== ///
    struct RateState {
        uint160 validator;
        uint96 rateType;
    }

    /// ======== Storage ======== ///
    // Mapping that will hold a proposal hash matching each proposal to it's internal state.
    // The hash is computed by encoding the rateId, proposed value and an extra auxiliary data parameter
    // which in most cases will determine the age of the value(either block number or block timestamp)
    mapping(bytes32 => ProposalState) public proposals;

    // The rateId is an simple encoding depending on rateType because of how Collybus stores discount rates/spots
    // Discount : uint256
    // Spot : address
    mapping(bytes32 => RateState) public rates;

    // Address of the deployed Collybus contracts for which the Optimistic Oracle manages rate/spot updates
    address public immutable collybus;

    /// ======== Code ======== ///
    /// @param collybus_ Collybus address where the Oracle needs to be whitelisted to be able to call update sport/discount
    /// @param token_ The ERC20 token used by the Bond Management system for staking
    /// @param bondValue_ The value that needs to be paid by an actor to become a proposer for a rate
    /// @dev The token_ and the bondValue_ are used by the Bond Manager
    constructor(
        address collybus_,
        IERC20 token_,
        uint256 bondValue_
    ) BondManager(token_, bondValue_) {
        collybus = collybus_;
    }

    /// @notice Sets a OptimisticOracle parameter
    /// Supported parameters are:
    /// - validator
    /// @param param_ The identifier of the parameter that should be updated
    /// @param value_ The new value
    /// @dev Reverts if parameter is not found
    /// @dev Guarded call, check the Guarded contract for more information about the permission system
    function setParam(
        bytes32 rateId_,
        bytes32 param_,
        bytes32 value_
    ) public checkCaller {
        if (param_ == "validator") {
            rates[rateId_].validator = uint160(uint256(value_));
        } else
            revert OptimisticOracle__setParam_unrecognizedParam(
                rateId_,
                param_
            );

        emit SetParam(rateId_, param_, value_);
    }

    /// @notice Registers a rate with the Oracle in order to submit price updates to Collybus
    /// Each rate needs a corresponding Validator contract that will handle and settle optimistically
    /// proposed price updates
    /// @param rateId_ Unique id for a rate that will be used when data is updated in Collybus
    /// @param rateType_ The Optimistic Oracle supports two rate types:
    /// Discount : will trigger updateDiscountRate calls to Collybus
    /// Spot : will trigger updateSpot calls to Collybus
    /// @param validator_ The validator is used as an onchain dispute settle mechanism. The Validator is able
    /// to confirm historical accurate prices via either Merkle Proofs or by retrieving historical data from
    /// onchain providers(eg: Chainlink Feeds)
    /// @dev Reverts if a rate was already registered
    /// @dev Guarded call, check the Guarded contract for more information about the permission system
    function registerRate(
        bytes32 rateId_,
        uint256 rateType_,
        address validator_
    ) external checkCaller {
        if (rates[rateId_].validator != 0) {
            revert OptimisticOracle__registerRate_rateAlreadyRegistered(
                rateId_
            );
        }

        rates[rateId_].validator = uint160(validator_);
        rates[rateId_].rateType = uint96(rateType_);

        // Initialize the start proposal hash that will be used for the first shift
        // This is the only situation in which auxData can be zero, in all other cases
        // it will either mark the block number at which the value was computed or some other
        // unique non-zero identifier
        bytes32 startProposal = generateHash(rateId_, 0, 0);
        proposals[startProposal] = ProposalState.Active;
    }

    /// @notice Un-registers a rate from the Optimistic Oracle
    /// @param rateId_ Rate id that needs to be removed from the Oracle
    /// @dev Reverts if the rate is not found
    /// @dev Guarded call, check the Guarded contract for more information about the permission system
    function unregisterRate(bytes32 rateId_) external checkCaller {
        if (rates[rateId_].validator == 0) {
            revert OptimisticOracle__unregisterRate_rateNotFound(rateId_);
        }

        delete rates[rateId_];
    }

    /// @notice Simple keccak256 hash of the provided parameters
    function generateHash(
        bytes32 rateId_,
        uint256 value_,
        bytes32 auxData_
    ) public pure returns (bytes32) {
        unchecked {
            return keccak256(abi.encode(rateId_, value_, auxData_));
        }
    }

    /// @notice The shift method pushes previously validated values to Collybus and also
    /// accepts new proposals. In order for a new proposal to be accepted the previous one
    /// needs to be validated and executed.
    /// @param rateId_ The rate id for which the update is performed
    /// @param prevProposerAddress_ The address of the previous proposer
    /// @param prevValue_ The previous proposed value
    /// @param prevAuxData_ The previous proposal value auxiliary data
    /// @param value_ The value for the new proposal
    /// @param auxData_ The auxiliary data for the new proposal
    /// @dev Reverts if the previous proposal is not found
    /// @dev Reverts if the propose and dispute window checks fail
    /// @dev The execution(Collybus price update) happens only if the previous proposal was not disputed.
    /// When disputed are resolved Collybus will also be updated
    /// @dev For the first shift the previous value and auxiliary data are set to 0
    /// @dev Guarded call, only registered proposers can call
    function shift(
        bytes32 rateId_,
        address prevProposerAddress_,
        uint256 prevValue_,
        bytes32 prevAuxData_,
        uint256 value_,
        bytes32 auxData_
    ) external activateProposer(rateId_) {
        // Retrieve the validator contract
        IValidator validator = IValidator(address(rates[rateId_].validator));

        // Compute the hash for the previous proposal
        bytes32 prevProposalId = generateHash(
            rateId_,
            prevValue_,
            prevAuxData_
        );

        // Verify that the previous proposal is in a valid state
        ProposalState state = proposals[prevProposalId];
        if (state == ProposalState.Inactive) {
            revert OptimisticOracle__shift_invalidPreviousProposal(rateId_);
        }

        // Verify that the shift can be done by checking whether the dispute and the propose window are respected
        if (!validator.canShift(prevAuxData_, auxData_)) {
            revert OptimisticOracle__shift_invalidParams(rateId_);
        }

        // If the proposal is active then we need to execute it
        // We skip this check if the prevAuxData is 0 because
        // we are in the first shift and we do not need run execute
        if (prevAuxData_ > 0) {
            if (state == ProposalState.Active) {
                _execute(rateId_, prevValue_);
            }

            // Clear the previous proposerId
            _clearProposer(prevProposerAddress_, rateId_);
        }

        // Generate the hash of the new proposal and update it's state
        bytes32 proposalId = generateHash(rateId_, value_, auxData_);
        proposals[proposalId] = ProposalState.Active;

        // Clear the previous proposal
        delete proposals[prevProposalId];
        emit Shift(rateId_, msg.sender, proposalId, value_, auxData_);
    }

    /// @notice Disputes an active proposal by validating the proposed value
    /// via the Validator contract. If the dispute is valid then the bond payed
    /// by the proposer will be sent to receiver_.
    /// @param rateId_ The rate id of the proposal that will be disputed
    /// @param proposer_ The address of the proposer
    /// @param receiver_ The address of the receiver
    /// @param value_ The previous proposed value
    /// @param auxData_ The previous proposal value auxiliary data
    /// @param blockHeaderRlpBytes_ The RLP encoded block header which we will validate against onchain block hash historical data
    /// and use for storage proof and data extraction
    /// @param proofRlpBytes_ The RLP encoded storage proof we will use to validate and extract storage data needed by the Validator
    /// @return bool, outcome of the dispute
    function dispute(
        bytes32 rateId_,
        address proposer_,
        address receiver_,
        uint256 value_,
        bytes32 auxData_,
        bytes memory blockHeaderRlpBytes_,
        bytes memory proofRlpBytes_
    ) external returns (bool) {
        // Retrieve the address of the validator contract
        address validatorAddress = address(rates[rateId_].validator);

        // Generate the previous proposalId
        bytes32 proposalId = generateHash(rateId_, value_, auxData_);

        // Check that the previous proposal is valid and can be disputed
        // _disputeCheck will revert if any condition is not met
        _disputeCheck(
            rateId_,
            IValidator(validatorAddress),
            proposalId,
            auxData_
        );

        // Validate the proposed value with the help of the Validator
        // The Validator contract will use the header and storage proof to verify and
        // extract historical data. This data is used to recompute and check the proposed value
        (bool proposalIsValid, uint256 verifiedValue) = IProofValidator(
            validatorAddress
        ).validate(
                value_,
                uint256(auxData_),
                blockHeaderRlpBytes_,
                proofRlpBytes_
            );

        // We execute the proposal by updating Collybus with the verified value
        proposals[proposalId] = ProposalState.Executed;
        _execute(rateId_, verifiedValue);

        // If the proposed value was invalid then we need to transfer the proposed bond to the
        // receiver specified by the disputed
        if (!proposalIsValid) {
            _transferBond(rateId_, proposer_, receiver_);
        } else {
            // If the dispute was not valid then we clear the flag that marks the current proposer as active.
            _clearProposer(proposer_, rateId_);
        }

        emit DisputeValue(
            msg.sender,
            rateId_,
            verifiedValue,
            value_,
            !proposalIsValid
        );

        // Return the dispute outcome
        return !proposalIsValid;
    }

    /// @notice Disputes an active proposal by validating the proposed value
    /// via the Validator contract. If the dispute is valid then the bond paid
    /// by the proposer will be sent to receiver_.
    /// @param rateId_ The rate id of the proposal that will be disputed
    /// @param proposer_ The address of the proposer
    /// @param receiver_ The address of the receiver
    /// @param value_ The previous proposed value
    /// @param auxData_ The previous proposal value auxiliary data
    /// @return bool, outcome of the dispute
    function dispute(
        bytes32 rateId_,
        address proposer_,
        address receiver_,
        uint256 value_,
        bytes32 auxData_
    ) external returns (bool) {
        // Retrieve the address of the validator contract
        address validatorAddress = address(rates[rateId_].validator);
        // Generate the previous proposalId
        bytes32 proposalId = generateHash(rateId_, value_, auxData_);

        // Check that the previous proposal is valid and can be disputed
        // _disputeCheck will revert if any condition is not met
        _disputeCheck(
            rateId_,
            IValidator(validatorAddress),
            proposalId,
            auxData_
        );

        // Validate the proposed value with the help of the Validator
        // The Chainlink validator will retrieve historical data and it to validate the proposed value
        (bool proposalIsValid, uint256 verifiedValue) = IChainlinkValidator(
            validatorAddress
        ).validate(
                value_,
                // Token Address
                address(uint160(uint256(rateId_))),
                // roundId
                uint256(auxData_)
            );

        // We execute the proposal by updating Collybus with the verified value
        proposals[proposalId] = ProposalState.Executed;
        _execute(rateId_, verifiedValue);

        // If the proposed value was invalid then we need to transfer the proposed bond to the
        // receiver specified by the disputed
        if (!proposalIsValid) {
            _transferBond(rateId_, proposer_, receiver_);
        } else {
            // If the dispute was not valid then we clear the flag that marks the current proposer as active.
            _clearProposer(proposer_, rateId_);
        }

        emit DisputeValue(
            msg.sender,
            rateId_,
            verifiedValue,
            value_,
            !proposalIsValid
        );

        // Return the dispute outcome
        return !proposalIsValid;
    }

    /// @notice Returns the validator address for a given rateId
    /// @param rateId_ The rate id for which we want to retrieve the validator address
    /// @return address of the Validator, address(0) if not found
    function getValidator(bytes32 rateId_) external view returns (address) {
        return address(rates[rateId_].validator);
    }

    /// @notice Helper function that checks and validates that a proposal is valid and can be disputed
    /// @param rateId_ The rate id of the proposal that is checked
    /// @param validator_ The address of the validator used to check the proposal
    /// @param proposalId_ The proposalId of the proposal
    /// @param auxData_ The auxiliary data of the proposal
    /// @dev The function reverts if any condition is not met
    function _disputeCheck(
        bytes32 rateId_,
        IValidator validator_,
        bytes32 proposalId_,
        bytes32 auxData_
    ) internal view {
        // Check that the validator address is valid
        if (address(validator_) == address(0)) {
            revert OptimisticOracle__disputeCheck_rateNotRegistered(rateId_);
        }

        // Check that the proposal is active and accepting disputed
        if (proposals[proposalId_] != ProposalState.Active) {
            revert OptimisticOracle__disputeCheck_invalidProposal(rateId_);
        }

        // Check that the dispute can be made which in most cases means that
        // we are still in the dispute window
        if (!validator_.canDispute(auxData_)) {
            revert OptimisticOracle__disputeCheck_invalidDispute(rateId_);
        }
    }

    /// @notice Helper function that executes a proposal by updating Collybus
    /// @param rateId_ The rate id that we want to update
    /// @param value_ The value that will be sent to Collybus
    /// @dev The function reverts if the rateType linked to this rateId is not handled
    function _execute(bytes32 rateId_, uint256 value_) internal {
        // Retrieve the rateType which can be Discount or Spot.
        uint256 rateType = rates[rateId_].rateType;
        if (rateType == uint256(RateType.Discount)) {
            // Update the discount rate
            ICollybus(collybus).updateDiscountRate(uint256(rateId_), value_);
        } else if (rateType == uint256(RateType.Spot)) {
            // Update the spot price
            ICollybus(collybus).updateSpot(
                address(uint160(uint256(rateId_))),
                value_
            );
        } else {
            revert OptimisticOracle__updateCollybus_invalidRelayerType(
                rateType
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
    function canShift(bytes32 prevAuxData_, bytes32 auxData_)
        external
        view
        returns (bool);

    function canPropose(bytes32 auxData_) external view returns (bool);

    function canDispute(bytes32 auxData_) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {IValidator} from "./IValidator.sol";

interface IChainlinkValidator {
    function value(address tokenAddress_)
        external
        view
        returns (uint256, uint256);

    function validate(
        uint256 value_,
        address tokenAddress_,
        uint256 roundId
    ) external returns (bool, uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {IValidator} from "./IValidator.sol";

interface IProofValidator {
    function value() external returns (uint256, uint256);

    function validate(
        uint256 value_,
        uint256 blockNumber_,
        bytes memory blockHeaderRlpBytes_,
        bytes memory proofRlpBytes_
    ) external returns (bool, uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BondManager {
    using SafeERC20 for IERC20;
    /// ======== Errors ======== ///
    error BondManager__activateProposer_invalidProposer(
        address proposer_,
        bytes32 rateId_
    );
    error BondManager__clearProposer_invalidProposer(
        address proposer_,
        bytes32 rateId_
    );
    error BondManager__transferBond_invalidProposerId(bytes32 proposerId_);
    error BondManager__registerProposer_alreadyRegisteredForRate(
        bytes32 rateId_,
        bytes32 proposerId_
    );
    error BondManager__unregisterProposer_isActive(bytes32 rateId_);
    error BondManager__unregisterProposer_invalidProposerId(bytes32 rateId_);

    /// ======== Events ======== ///
    event ProposerAdded(address proposer_, bytes32[] proposerIds_);
    event ProposerRemoved(address, bytes32[], address);
    event BondTransferred(address, bytes32);

    /// ======== Enums ======== ///
    enum ProposerState {
        Unregistered,
        Registered,
        // When a proposal is made and can be disputed
        Active
    }
    /// ======== Storage ======== ///
    // ERC20 token that is used as stake
    IERC20 public immutable token;
    // Value of a bond in tokens
    uint256 public immutable bondValue;

    // Mapping with active proposer ids
    ///@dev The proposerId is as hash of the proposer address and the rateId for which the proposer can submit data
    mapping(bytes32 => ProposerState) public proposerIds;

    /// ======== Modifiers ======== ///
    modifier activateProposer(bytes32 rateId_) {
        // Compute the proposerId hash based on the proposer address and the rateId
        bytes32 proposerId = keccak256(abi.encode(msg.sender, rateId_));

        // Check if the proposerId is registered
        if (proposerIds[proposerId] == ProposerState.Unregistered) {
            revert BondManager__activateProposer_invalidProposer(
                msg.sender,
                rateId_
            );
        }

        // Allow execution
        _;

        // Mark the proposer as active
        proposerIds[proposerId] = ProposerState.Active;
    }

    /// ======== Code ======== ///
    /// @param token_ ERC20 stake token that is used by the system
    /// @param bondValue_ Bond value in tokens
    constructor(IERC20 token_, uint256 bondValue_) {
        token = token_;
        bondValue = bondValue_;
    }

    /// @notice Registers a proposer in order to submit data to multiple rateIds.
    /// The total payment needed is computed and transferred from the caller.
    /// @param proposer_ The address of the proposer.
    /// @param rateIds_ The list of valid rateIds
    /// @return createdIds_ The list of proposerIds generated for each rateId that can be used
    /// by the proposer to submit values.
    /// @dev Reverts if the tokens can not be transferred.
    /// @dev Reverts is the proposer already has a proposerId generated for a rate.
    /// @dev The caller needs to set an allowance for the BondManager covering the total bond value
    function registerProposer(address proposer_, bytes32[] memory rateIds_)
        public
        returns (bytes32[] memory createdIds_)
    {
        // Compute the total payment value
        uint256 len = rateIds_.length;
        uint256 paymentAmount = len * bondValue;

        // Attempt to retrieve the tokens from the caller
        token.safeTransferFrom(msg.sender, address(this), paymentAmount);

        // Create and store a proposerId for each rateId
        createdIds_ = new bytes32[](len);
        for (uint256 idx = 0; idx < len; ++idx) {
            // Generate the proposerId hash
            bytes32 proposerId = keccak256(
                abi.encode(proposer_, rateIds_[idx])
            );

            // Revert if we`re already registered
            if (proposerIds[proposerId] != ProposerState.Unregistered) {
                revert BondManager__registerProposer_alreadyRegisteredForRate(
                    rateIds_[idx],
                    proposerId
                );
            }

            // Store the proposerId
            proposerIds[proposerId] = ProposerState.Registered;
            createdIds_[idx] = proposerId;
        }

        emit ProposerAdded(proposer_, createdIds_);
    }

    /// @notice Un-registers the caller for multiple rateIds and sends the total bond value to
    /// the receiver_
    /// @param rateIds_ The list of valid rateIds
    /// @param receiver_ The address of the bonds receiver
    /// @dev Reverts if the proposerId was activated via activateProposer and it's still in use
    /// @dev Reverts if the caller is not a proposer for a rateId
    /// @dev Reverts if the total bond value transfer fails.
    function unregisterProposer(bytes32[] memory rateIds_, address receiver_)
        public
    {
        uint256 len = rateIds_.length;
        for (uint256 idx = 0; idx < len; ++idx) {
            bytes32 proposerId = keccak256(
                abi.encode(msg.sender, rateIds_[idx])
            );

            if (proposerIds[proposerId] == ProposerState.Active) {
                revert BondManager__unregisterProposer_isActive(rateIds_[idx]);
            }

            if (proposerIds[proposerId] == ProposerState.Unregistered) {
                revert BondManager__unregisterProposer_invalidProposerId(
                    proposerId
                );
            }

            delete proposerIds[proposerId];
        }

        // Compute the full transfer value and send it to the receiver
        uint256 totalBondValue = len * bondValue;
        token.safeTransfer(receiver_, totalBondValue);
        emit ProposerRemoved(msg.sender, rateIds_, receiver_);
    }

    /// @notice Returns whether a user is a proposer for a rateId
    /// @param rateId_ The rateId
    /// @param user_ Address of the user that will be verified
    function isProposer(bytes32 rateId_, address user_)
        public
        view
        returns (bool)
    {
        bytes32 proposerId = keccak256(abi.encode(user_, rateId_));

        return proposerIds[proposerId] != ProposerState.Unregistered;
    }

    /// @notice Returns the proposerState of a user for a rateId
    /// @param user_ The address of the user
    /// @param rateId_ The rateId that will be checked
    function proposerState(address user_, bytes32 rateId_)
        public
        view
        returns (ProposerState)
    {
        bytes32 proposerId = keccak256(abi.encode(user_, rateId_));
        return proposerIds[proposerId];
    }

    /// @notice Clears the active state flag of a proposer on a rateId
    /// @param proposer_ The address of the proposer
    /// @param rateId_ The rateId that will be used to check and update the proposer state
    /// @dev Reverts if the proposer state is not Active.
    function _clearProposer(address proposer_, bytes32 rateId_) internal {
        // Compute the proposerId hash based on the proposer address and the rateId
        bytes32 proposerId = keccak256(abi.encode(proposer_, rateId_));

        // Check if the proposerId is registered
        if (proposerIds[proposerId] == ProposerState.Active) {
            proposerIds[proposerId] = ProposerState.Registered;
        } else {
            revert BondManager__clearProposer_invalidProposer(
                proposer_,
                rateId_
            );
        }
    }

    /// @notice Deletes a valid proposerId and sends the bond value to a recipient
    /// @param proposerId_ The Id of the proposer
    /// @param receiver_ The address that will receive the bond value.
    /// @dev Reverts if the proposerId is not found
    /// @dev Reverts if the transfer is not successful
    function _transferBond(bytes32 proposerId_, address receiver_) internal {
        if (proposerIds[proposerId_] == ProposerState.Unregistered) {
            revert BondManager__transferBond_invalidProposerId(proposerId_);
        }

        delete proposerIds[proposerId_];

        token.safeTransfer(receiver_, bondValue);
        emit BondTransferred(receiver_, proposerId_);
    }

    /// @notice Deletes a valid proposerId and sends the bond value to a recipient
    /// @param rateId_ The rate id
    /// @param proposer_ The address of the proposer
    /// @param receiver_ The address that will receive the bond value.
    /// @dev Reverts if the proposerId is not found
    /// @dev Reverts if the transfer is not successful

    function _transferBond(
        bytes32 rateId_,
        address proposer_,
        address receiver_
    ) internal {
        // Generate the proposerId based on the rate and the address of the proposer
        bytes32 proposerId = keccak256(abi.encode(proposer_, rateId_));
        _transferBond(proposerId, receiver_);
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