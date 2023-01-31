// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

abstract contract Authenticator {
    bytes4 internal constant PROPOSE_SELECTOR =
        bytes4(keccak256("propose(address,string,(address,bytes),(uint8,bytes)[])"));
    bytes4 constant VOTE_SELECTOR = bytes4(keccak256("vote(address,uint256,uint8,(uint8,bytes)[])"));

    function _call(address target, bytes4 functionSelector, bytes memory data) internal {
        (bool success, ) = target.call(abi.encodePacked(functionSelector, data));
        if (!success) {
            // If the call failed, we revert with the propogated error message.
            assembly {
                let returnDataSize := returndatasize()
                returndatacopy(0, 0, returnDataSize)
                revert(0, returnDataSize)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Authenticator.sol";
import "../types.sol";

/**
 * @author  SnapshotLabs
 * @title   EthTxAuthenticator
 * @notice  Authenticates a vote / a proposal by ensuring `msg.sender`
 *          corresponds to the voter / proposal author.
 */

contract EthTxAuthenticator is Authenticator {
    error InvalidFunctionSelector();
    error InvalidMessageSender();

    /**
     * @notice  Internal function to verify that the msg sender is indeed the proposal author
     * @param   data  The data to verify
     */
    function _verifyPropose(bytes calldata data) internal view {
        (address author, , , ) = abi.decode(data, (address, string, Strategy, IndexedStrategy[]));
        if (author != msg.sender) revert InvalidMessageSender();
    }

    /**
     * @notice  Internal function to verify that the msg sender is indeed the voter
     * @param   data  The data to verify
     */
    function _verifyVote(bytes calldata data) internal view {
        (address voter, , , ) = abi.decode(data, (address, uint256, Choice, IndexedStrategy[]));
        if (voter != msg.sender) revert InvalidMessageSender();
    }

    function authenticate(address target, bytes4 functionSelector, bytes calldata data) external {
        if (functionSelector == PROPOSE_SELECTOR) {
            _verifyPropose(data);
        } else if (functionSelector == VOTE_SELECTOR) {
            _verifyVote(data);
        } else {
            revert InvalidFunctionSelector();
        }
        _call(target, functionSelector, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

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
    Against,
    For,
    Abstain
}

struct Vote {
    Choice choice;
    uint256 votingPower;
}

struct MetaTransaction {
    address to;
    uint256 value;
    bytes data;
    Enum.Operation operation;
}