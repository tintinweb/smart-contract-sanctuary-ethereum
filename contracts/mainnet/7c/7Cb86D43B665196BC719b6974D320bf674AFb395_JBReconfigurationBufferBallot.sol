// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './interfaces/IJBReconfigurationBufferBallot.sol';
import './structs/JBFundingCycle.sol';

/** 
  @notice 
  Manages approving funding cycle reconfigurations automatically after a buffer period.

  @dev
  Adheres to:
  IJBReconfigurationBufferBallot: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
contract JBReconfigurationBufferBallot is IJBReconfigurationBufferBallot {
  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /**
    @notice 
    The number of seconds that must pass for a funding cycle reconfiguration to become either `Approved` or `Failed`.
  */
  uint256 public immutable override duration;

  /**
    @notice
    The contract storing all funding cycle configurations.
  */
  IJBFundingCycleStore public immutable override fundingCycleStore;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
    @notice 
    The finalized state.

    @dev
    If `Active`, the ballot for the provided configuration can still be finalized whenever its state settles.

    _projectId The ID of the project to check the final ballot state of.
    _configuration The configuration of the funding cycle to check the final ballot state of.
  */
  mapping(uint256 => mapping(uint256 => JBBallotState)) public override finalState;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice 
    The approval state of a particular funding cycle.

    @param _projectId The ID of the project to which the funding cycle being checked belongs.
    @param _configured The configuration of the funding cycle to check the state of.
    @param _start The start timestamp of the funding cycle to check the state of.

    @return The state of the provided ballot.
  */
  function stateOf(
    uint256 _projectId,
    uint256 _configured,
    uint256 _start
  ) public view override returns (JBBallotState) {
    // If there is a finalized state, return it.
    if (finalState[_projectId][_configured] != JBBallotState.Active)
      return finalState[_projectId][_configured];

    // If the delay hasn't yet passed, the ballot is either failed or active.
    if (block.timestamp < _configured + duration)
      // If the current timestamp is past the start, the ballot is failed.
      return (block.timestamp >= _start) ? JBBallotState.Failed : JBBallotState.Active;

    // The ballot is otherwise approved.
    return JBBallotState.Approved;
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _duration The number of seconds to wait until a reconfiguration can be either `Approved` or `Failed`.
    @param _fundingCycleStore A contract storing all funding cycle configurations.
  */
  constructor(uint256 _duration, IJBFundingCycleStore _fundingCycleStore) {
    duration = _duration;
    fundingCycleStore = _fundingCycleStore;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice 
    Finalizes a configuration state if the current state has settled.

    @param _projectId The ID of the project to which the funding cycle being checked belongs.
    @param _configured The configuration of the funding cycle to check the state of.

    @return ballotState The state of the finalized ballot. If `Active`, the ballot can still later be finalized when it's state resolves.
  */
  function finalize(uint256 _projectId, uint256 _configured)
    external
    override
    returns (JBBallotState ballotState)
  {
    // Get the funding cycle for the configuration in question.
    JBFundingCycle memory _fundingCycle = fundingCycleStore.get(_projectId, _configured);

    // Get the current ballot state.
    ballotState = finalState[_projectId][_configured];

    // If the final ballot state is still `Active`.
    if (ballotState == JBBallotState.Active) {
      ballotState = stateOf(_projectId, _configured, _fundingCycle.start);
      // If the ballot is active after the cycle has started, it should be finalized as failed.
      if (ballotState != JBBallotState.Active) {
        // Store the updated value.
        finalState[_projectId][_configured] = ballotState;

        emit Finalize(_projectId, _configured, ballotState, msg.sender);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

enum JBBallotState {
  Active,
  Approved,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleStore.sol';
import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleBallot.sol';
import './../enums/JBBallotState.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed configuration,
    uint256 indexed projectId,
    JBFundingCycleData data,
    uint256 metadata,
    uint256 mustStartAtOrAfter,
    address caller
  );

  event Init(uint256 indexed configuration, uint256 indexed projectId, uint256 indexed basedOn);

  function latestConfigurationOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleBallot.sol';

interface IJBReconfigurationBufferBallot is IJBFundingCycleBallot {
  event Finalize(
    uint256 indexed projectId,
    uint256 indexed configuration,
    JBBallotState indexed ballotState,
    address caller
  );

  function finalState(uint256 _projectId, uint256 _configuration) external returns (JBBallotState);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function finalize(uint256 _projectId, uint256 _configured) external returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

struct JBFundingCycle {
  // The funding cycle number for each project.
  // Each funding cycle has a number that is an increment of the cycle that directly preceded it.
  // Each project's first funding cycle has a number of 1.
  uint256 number;
  // The timestamp when the parameters for this funding cycle were configured.
  // This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  uint256 configuration;
  // The `configuration` of the funding cycle that was active when this cycle was created.
  uint256 basedOn;
  // The timestamp marking the moment from which the funding cycle is considered active.
  // It is a unix timestamp measured in seconds.
  uint256 start;
  // The number of seconds the funding cycle lasts for, after which a new funding cycle will start.
  // A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties.
  // If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle.
  // If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  uint256 duration;
  // A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on.
  // For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  uint256 weight;
  // A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`.
  // If it's 0, each funding cycle will have equal weight.
  // If the number is 90%, the next funding cycle will have a 10% smaller weight.
  // This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  uint256 discountRate;
  // An address of a contract that says whether a proposed reconfiguration should be accepted or rejected.
  // It can be used to create rules around how a project owner can change funding cycle parameters over time.
  IJBFundingCycleBallot ballot;
  // Extra data that can be associated with a funding cycle.
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

struct JBFundingCycleData {
  // The number of seconds the funding cycle lasts for, after which a new funding cycle will start.
  // A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties.
  // If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle.
  // If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  uint256 duration;
  // A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on.
  // For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  uint256 weight;
  // A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`.
  // If it's 0, each funding cycle will have equal weight.
  // If the number is 90%, the next funding cycle will have a 10% smaller weight.
  // This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  uint256 discountRate;
  // An address of a contract that says whether a proposed reconfiguration should be accepted or rejected.
  // It can be used to create rules around how a project owner can change funding cycle parameters over time.
  IJBFundingCycleBallot ballot;
}