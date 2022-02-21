// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

interface SequencerLike {
    struct WorkableJob {
        address job;
        bool canWork;
        bytes args;
    }

    function getNextJobs(bytes32 network)
        external
        returns (WorkableJob[] memory);
}

interface JobLike {
    function work(bytes32 network, bytes calldata args) external;
}

contract DssCronKeeper is KeeperCompatibleInterface {
    SequencerLike private sequencer;
    bytes32 private network;

    constructor(address _sequencer, bytes32 _network) {
        sequencer = SequencerLike(_sequencer);
        network = _network;
    }

    function _getPendingJob()
        internal
        returns (SequencerLike.WorkableJob memory)
    {
        SequencerLike.WorkableJob[] memory jobs = sequencer.getNextJobs(
            network
        );
        for (uint256 i = 0; i < jobs.length; i++) {
            SequencerLike.WorkableJob memory job = jobs[i];
            if (job.canWork) {
                return job;
            }
        }
    }

    function checkUpkeep(bytes calldata)
        external
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded = _getPendingJob().job != address(0);
    }

    function performUpkeep(bytes calldata) external override {
        SequencerLike.WorkableJob memory wjob = _getPendingJob();
        if (wjob.job != address(0)) {
            JobLike job = JobLike(wjob.job);
            job.work(network, wjob.args);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}