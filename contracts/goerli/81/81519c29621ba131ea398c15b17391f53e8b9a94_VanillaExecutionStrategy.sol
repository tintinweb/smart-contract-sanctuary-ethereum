// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../interfaces/IExecutionStrategy.sol";

contract VanillaExecutionStrategy is IExecutionStrategy {
    uint256 numExecuted;

    // solhint-disable no-unused-vars
    function execute(ProposalOutcome proposalOutcome, bytes memory executionParams) external override {
        numExecuted++;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../types.sol";

interface IExecutionStrategy {
    function execute(ProposalOutcome proposalOutcome, bytes memory executionParams) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

struct Proposal {
    // We store the quroum for each proposal so that if the quorum is changed mid proposal,
    // the proposal will still use the previous quorum *
    uint256 quorum;
    // notice: `uint32::max` corresponds to year ~2106.
    uint32 snapshotTimestamp;
    // * The same logic applies for why we store the 3 timestamps below (which could otherwise
    // be inferred from the votingDelay, minVotingDuration, and maxVotingDuration state variables)
    uint32 startTimestamp;
    uint32 minEndTimestamp;
    uint32 maxEndTimestamp;
    bytes32 executionHash;
    address executionStrategy;
    FinalizationStatus finalizationStatus;
}

// A struct that represents any kind of strategy (i.e a pair of `address` and `bytes`)
struct Strategy {
    address addy;
    bytes params;
}

// Similar to `Strategy` except it's an `index` (uint8) and not an `address`
struct IndexedStrategy {
    uint8 index;
    bytes params;
}

// Outcome of a proposal after being voted on.
enum ProposalOutcome {
    Accepted,
    Rejected,
    Cancelled
}

// Similar to `ProposalOutcome` except is starts with `NotExecuted`.
// notice: it is important it starts with `NotExecuted` because it correponds to
// `0` which is the default value in Solidity.
enum FinalizationStatus {
    NotExecuted,
    FinalizedAndAccepted,
    FinalizedAndRejected,
    FinalizedAndCancelled
}

// Status of a proposal. If executed, it will be its outcome; else it will be some
// information regarding its current status.
enum ProposalStatus {
    Accepted,
    Rejected,
    Cancelled,
    WaitingForVotingPeriodToStart,
    VotingPeriod,
    VotingPeriodFinalizable,
    Finalizable
}

enum Choice {
    For,
    Against,
    Abstain
}

struct Vote {
    Choice choice;
    uint256 votingPower;
}