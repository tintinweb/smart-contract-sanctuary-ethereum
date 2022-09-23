// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {LastUpdater} from "../LastUpdater.sol";

/**
 * @dev Ampleforth oracle contract interface
 */
interface AmpleforthInterface {
  function pushReport(uint256 payload) external;

  function purgeReports() external;

  function addProvider(address) external;

  event ProviderReportPushed(address indexed provider, uint256 payload, uint256 timestamp);
}

/**
 * @title Ampleforth Keeper
 * @notice This is a Chainlink Keeper-compatible contract that records every time the feed answer changes,
 *  and pushes the answer to the Ampleforth oracle contract.
 */
contract AmpleforthKeeper is LastUpdater {
  AmpleforthInterface public immutable ampleforthOracle;

  /**
   * @param feedContractAddress Address of Chainlink feed to read from
   * @param ampleforthOracleAddress Address of Ampleforth oracle to push reports to
   */
  constructor(address feedContractAddress, address ampleforthOracleAddress) LastUpdater(feedContractAddress) {
    ampleforthOracle = AmpleforthInterface(ampleforthOracleAddress);
  }

  /**
   * @notice Push a report to the Ampleforth Oracle contract with the latest answer.
   */
  function performUpkeep(bytes calldata) external override {
    (bool hasNewAnswer, int256 latestAnswer) = super.updateAnswer();

    require(hasNewAnswer, "Feed has not changed");
    require(latestAnswer >= 0, "Invalid feed answer");
    ampleforthOracle.pushReport(uint256(latestAnswer));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./interfaces/KeeperCompatibleInterface.sol";
import "./interfaces/AggregatorV3Interface.sol";

/**
 * @title Contract to record a new answer when the roundId increments.
 */
contract LastUpdater is KeeperCompatibleInterface {
  /// @notice Struct to record round data from AggregatorV3Interface
  struct RoundData {
    uint80 roundId;
    int256 answer;
    /// @dev The block timestamp at which this round was updated by this Keeper
    uint256 timestamp;
  }

  /**
   * @notice Details of the last round returned by the feed.
   * @dev Updated whenever the target feed has a new round with data.
   */
  RoundData public s_lastRound;

  /// @notice A reference to the feed that the contract should read data from
  AggregatorV3Interface public immutable s_feed;

  event FeedAnswerUpdated(int256 _newValue, uint256 _time);

  constructor(address _feedContractAddress) {
    AggregatorV3Interface feed = AggregatorV3Interface(_feedContractAddress);
    s_feed = feed;

    // Initialise `s_lastRound` to the latest round
    (uint80 roundId, int256 answer, , , ) = feed.latestRoundData();
    s_lastRound = RoundData(roundId, answer, block.timestamp);
  }

  /**
   * @notice Determines whether or not the contract needs to perform an upkeep
   * @return upkeepNeeded as a boolean flag to tell Keepers whether or not to perform an upkeep
   */
  function checkUpkeep(bytes calldata) external view virtual override returns (bool upkeepNeeded, bytes memory) {
    (upkeepNeeded, , ) = checkForUpdate();
  }

  /**
   * @notice Performs the automated Keepers job to update the contract's timestamp if the feed was updated
   */
  function performUpkeep(bytes calldata) external virtual override {
    updateAnswer();
  }

  /**
   * @dev Check if the feed was updated, and update `s_lastRound` if it was.
   */
  function updateAnswer() internal returns (bool, int256) {
    (bool hasNewAnswer, uint80 roundId, int256 latestAnswer) = checkForUpdate();
    if (hasNewAnswer) {
      s_lastRound = RoundData(roundId, latestAnswer, block.timestamp);
      emit FeedAnswerUpdated(latestAnswer, block.timestamp);
    }
    return (hasNewAnswer, latestAnswer);
  }

  /**
   * @dev Check the latest round from the feed and indicate if it has been updated by
   *  checking if the `roundId` of the feed did increment.
   *  `roundId` can be assumed to increment when `latestRoundData` is called directly
   *  on an `AggregatorV3Interface` implementation.
   */
  function checkForUpdate()
    internal
    view
    returns (
      bool changed,
      uint80 roundId,
      int256 latestAnswer
    )
  {
    (roundId, latestAnswer, , , ) = s_feed.latestRoundData();
    if (roundId > s_lastRound.roundId) {
      changed = true;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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