// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IndexedStrategy, Proposal, ProposalStatus } from "../types.sol";
import { IExecutionStrategyErrors } from "./execution-strategies/IExecutionStrategyErrors.sol";

interface IExecutionStrategy is IExecutionStrategyErrors {
    function execute(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory payload
    ) external;

    function getProposalStatus(
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain
    ) external view returns (ProposalStatus);

    function getStrategyType() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IProposalValidationStrategy {
    function validate(address author, bytes calldata params, bytes calldata userParams) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ISpaceState } from "./space/ISpaceState.sol";
import { ISpaceActions } from "./space/ISpaceActions.sol";
import { ISpaceOwnerActions } from "./space/ISpaceOwnerActions.sol";
import { ISpaceEvents } from "./space/ISpaceEvents.sol";
import { ISpaceErrors } from "./space/ISpaceErrors.sol";

// solhint-disable-next-line no-empty-blocks
interface ISpace is ISpaceState, ISpaceActions, ISpaceOwnerActions, ISpaceEvents, ISpaceErrors {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/// @title The interface for voting strategies
interface IVotingStrategy {
    /// @notice Get the voting power of an address at a given timestamp
    /// @param timestamp The snapshot timestamp to get the voting power at
    /// If a particular voting strategy requires a  block number instead of a timestamp,
    /// the strategy should resolve the timestamp to a block number.
    /// @param voterAddress The address to get the voting power of
    /// @param params The global parameters that can configure the voting strategy for a particular space
    /// @param userParams The user parameters that can be used in the voting strategy computation
    /// @return votingPower The voting power of the address at the given timestamp
    /// If there is no voting power, return 0.
    function getVotingPower(
        uint32 timestamp,
        address voterAddress,
        bytes calldata params,
        bytes calldata userParams
    ) external returns (uint256 votingPower);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ProposalStatus } from "../../types.sol";

interface IExecutionStrategyErrors {
    /// @notice Thrown when the current status of a proposal does not allow the desired action.
    /// @param status The current status of the proposal.
    error InvalidProposalStatus(ProposalStatus status);

    /// @notice Thrown when the execution of a proposal fails.
    error ExecutionFailed();

    /// @notice Thrown when the execution payload supplied to the execution strategy is not equal
    /// to the payload supplied when the proposal was created.
    error InvalidPayload();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Choice, IndexedStrategy, Strategy } from "src/types.sol";

interface ISpaceActions {
    function propose(
        address author,
        string calldata metadataURI,
        Strategy calldata executionStrategy,
        bytes calldata userParams
    ) external;

    function vote(
        address voterAddress,
        uint256 proposalId,
        Choice choice,
        IndexedStrategy[] calldata userVotingStrategies,
        string calldata metadataUri
    ) external;

    function execute(uint256 proposalId, bytes calldata payload) external;

    function updateProposal(
        address author,
        uint256 proposalId,
        Strategy calldata executionStrategy,
        string calldata metadataURI
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ISpaceErrors {
    // Min duration should be smaller than or equal to max duration
    error InvalidDuration(uint32 minVotingDuration, uint32 maxVotingDuration);
    // Array is empty
    error EmptyArray();

    error InvalidCaller();
    // All strategy addresses must be != address(0).
    error InvalidStrategyAddress();
    error InvalidProposal();
    error AuthenticatorNotWhitelisted(address auth);
    error InvalidExecutionStrategyIndex(uint256 index);
    error ExecutionStrategyNotWhitelisted();
    error ProposalAlreadyFinalized();
    error MinVotingDurationHasNotElapsed();
    error QuorumNotReachedYet();
    error UserHasAlreadyVoted();
    error UserHasNoVotingPower();
    error VotingPeriodHasEnded();
    error VotingPeriodHasNotStarted();
    error ProposalFinalized();
    error VotingDelayHasPassed();
    error FailedToPassProposalValidation();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IndexedStrategy, Proposal, Strategy, Choice } from "src/types.sol";

interface ISpaceEvents {
    event SpaceCreated(
        address space,
        address owner,
        uint32 votingDelay,
        uint32 minVotingDuration,
        uint32 maxVotingDuration,
        Strategy proposalValidationStrategy,
        string metadataURI,
        Strategy[] votingStrategies,
        string[] votingStrategyMetadataURIs,
        address[] authenticators
    );
    event ProposalCreated(uint256 nextProposalId, address author, Proposal proposal, string metadataUri, bytes payload);
    event VoteCast(uint256 proposalId, address voterAddress, Choice choice, uint256 votingPower);
    event VoteCastWithMetadata(
        uint256 proposalId,
        address voterAddress,
        Choice choice,
        uint256 votingPower,
        string metadataUri
    );
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event VotingStrategiesAdded(Strategy[] newVotingStrategies, string[] newVotingStrategyMetadataURIs);
    event VotingStrategiesRemoved(uint8[] votingStrategyIndices);
    event ExecutionStrategiesAdded(Strategy[] newExecutionStrategies, string[] newExecutionStrategyMetadataURIs);
    event ExecutionStrategiesRemoved(uint8[] executionStrategyIndices);
    event AuthenticatorsAdded(address[] newAuthenticators);
    event AuthenticatorsRemoved(address[] authenticators);
    event MaxVotingDurationUpdated(uint32 newMaxVotingDuration);
    event MinVotingDurationUpdated(uint32 newMinVotingDuration);
    event MetadataURIUpdated(string newMetadataURI);
    event ProposalValidationStrategyUpdated(Strategy newProposalValidationStrategy);
    event QuorumUpdated(uint256 newQuorum);
    event VotingDelayUpdated(uint256 newVotingDelay);
    event ProposalUpdated(uint256 proposalId, Strategy newExecutionStrategy, string newMetadataURI);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Strategy } from "../../types.sol";

interface ISpaceOwnerActions {
    function cancel(uint256 proposalId) external;

    function setVotingDelay(uint32 delay) external;

    function setMinVotingDuration(uint32 duration) external;

    function setMaxVotingDuration(uint32 duration) external;

    function setProposalValidationStrategy(Strategy calldata proposalValidationStrategy) external;

    function setMetadataURI(string calldata metadataURI) external;

    function addVotingStrategies(
        Strategy[] calldata votingStrategies,
        string[] calldata votingStrategyMetadataURIs
    ) external;

    function removeVotingStrategies(uint8[] calldata indicesToRemove) external;

    function addAuthenticators(address[] calldata _authenticators) external;

    function removeAuthenticators(address[] calldata _authenticators) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Proposal, ProposalStatus } from "src/types.sol";

interface ISpaceState {
    function maxVotingDuration() external view returns (uint32);

    function minVotingDuration() external view returns (uint32);

    function nextProposalId() external view returns (uint256);

    function proposalThreshold() external view returns (uint256);

    function votingDelay() external view returns (uint32);

    function getProposal(uint256 proposalId) external view returns (Proposal memory);

    function getProposalStatus(uint256 proposalId) external view returns (ProposalStatus);

    function hasVoted(uint256 proposalId, address voter) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";
import { IndexedStrategy, Strategy } from "../types.sol";
import { ISpace } from "../interfaces/ISpace.sol";
import { GetCumulativePower } from "../utils/GetCumulativePower.sol";

contract VotingPowerProposalValidationStrategy is IProposalValidationStrategy {
    using GetCumulativePower for address;

    /**
     * @notice  Validates a proposal using the voting strategies to compute the proposal power.
     * @param   author  Author of the proposal
     * @param   userParams  User provided parameters for the voting strategies
     * @param   params  Bytes that should decode to proposalThreshold and allowedStrategies
     * @return  bool  Whether the proposal should be validated or not
     */
    function validate(
        address author,
        bytes calldata params,
        bytes calldata userParams
    ) external override returns (bool) {
        (uint256 proposalThreshold, Strategy[] memory allowedStrategies) = abi.decode(params, (uint256, Strategy[]));
        IndexedStrategy[] memory userStrategies = abi.decode(userParams, (IndexedStrategy[]));

        uint256 votingPower = author.getCumulativePower(uint32(block.timestamp), userStrategies, allowedStrategies);

        return (votingPower >= proposalThreshold);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import { IExecutionStrategy } from "src/interfaces/IExecutionStrategy.sol";

struct Proposal {
    // notice: `uint32::max` corresponds to year ~2106.
    uint32 snapshotTimestamp;
    // * The same logic applies for why we store the 3 timestamps below (which could otherwise
    // be inferred from the votingDelay, minVotingDuration, and maxVotingDuration state variables)
    uint32 startTimestamp;
    uint32 minEndTimestamp;
    uint32 maxEndTimestamp;
    // The hash of the execution payload. We do not store the payload itself to save gas.
    bytes32 executionPayloadHash;
    // Struct containing the execution strategy address and parameters required for the strategy.
    IExecutionStrategy executionStrategy;
    address author;
    // An enum that stores whether a proposal is pending, executed, or cancelled.
    FinalizationStatus finalizationStatus;
    // Array of structs containing the voting strategy addresses and parameters required for each.
    Strategy[] votingStrategies;
}

struct Strategy {
    address addy;
    bytes params;
}

struct IndexedStrategy {
    uint8 index;
    bytes params;
}

enum FinalizationStatus {
    Pending,
    Executed,
    Cancelled
}

// The status of a proposal as defined by the `getProposalStatus` function of the
// proposal's execution strategy.
enum ProposalStatus {
    VotingDelay,
    VotingPeriod,
    VotingPeriodAccepted,
    Accepted,
    Executed,
    Rejected,
    Cancelled
}

enum Choice {
    Against,
    For,
    Abstain
}

struct MetaTransaction {
    address to;
    uint256 value;
    bytes data;
    Enum.Operation operation;
    // We require a salt so that the struct can always be unique and we can use its hash as a unique identifier.
    uint256 salt;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IndexedStrategy, Strategy } from "../types.sol";
import { IVotingStrategy } from "src/interfaces/IVotingStrategy.sol";

error DuplicateFound(uint8 index);
error InvalidStrategyIndex(uint256 index);

/**
 * @notice  Internal function to ensure there are no duplicates in an array of `UserVotingStrategy`.
 * @dev     We create a bitmap of those indices by using a `u256`. We try to set the bit at index `i`, stopping it
 * @dev     it has already been set. Time complexity is O(n).
 * @param   strats  Array to check for duplicates.
 */
function _assertNoDuplicateIndices(IndexedStrategy[] memory strats) pure {
    if (strats.length < 2) {
        return;
    }

    uint256 bitMap;
    for (uint256 i = 0; i < strats.length; ++i) {
        // Check that bit at index `strats[i].index` is not set
        uint256 s = 1 << strats[i].index;
        if (bitMap & s != 0) revert DuplicateFound(strats[i].index);
        // Update aforementioned bit.
        bitMap |= s;
    }
}

library GetCumulativePower {
    /**
     * @notice  Loop over the strategies and return the cumulative power.
     * @dev
     * @param   timestamp  Timestamp of the snapshot.
     * @param   userAddress  Address for which to compute the voting power.
     * @param   userStrategies The desired voting strategies to check.
     * @param   allowedStrategies The array of strategies that are used for this proposal.
     * @return  uint256  The total voting power of a user (over those specified voting strategies).
     */
    function getCumulativePower(
        address userAddress,
        uint32 timestamp,
        IndexedStrategy[] memory userStrategies,
        Strategy[] memory allowedStrategies
    ) internal returns (uint256) {
        // Ensure there are no duplicates to avoid an attack where people double count a strategy
        _assertNoDuplicateIndices(userStrategies);

        uint256 totalVotingPower;
        for (uint256 i = 0; i < userStrategies.length; ++i) {
            uint256 strategyIndex = userStrategies[i].index;
            if (strategyIndex >= allowedStrategies.length) revert InvalidStrategyIndex(strategyIndex);
            Strategy memory strategy = allowedStrategies[strategyIndex];
            // A strategy address set to 0 indicates that this address has already been removed and is
            // no longer a valid voting strategy. See `_removeVotingStrategies`.
            if (strategy.addy == address(0)) revert InvalidStrategyIndex(strategyIndex);

            totalVotingPower += IVotingStrategy(strategy.addy).getVotingPower(
                timestamp,
                userAddress,
                strategy.params,
                userStrategies[i].params
            );
        }
        return totalVotingPower;
    }
}