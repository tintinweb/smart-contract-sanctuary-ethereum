/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

interface IFeedRegistry {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(
    address base,
    address quote
  )
    external
    view
    returns (
      uint8
    );

  function description(
    address base,
    address quote
  )
    external
    view
    returns (
      string memory
    );

  function version(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256
    );

  function latestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(
    address base,
    address quote
  )
    external
    view
    returns (
      int256 answer
    );

  function latestTimestamp(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 timestamp
    );

  function latestRound(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 roundId
    );

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      int256 answer
    );

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      uint256 timestamp
    );


  function isFeedEnabled(
    address aggregator
  )
    external
    view
    returns (
      bool
    );

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      Phase memory phase
    );

  // Round helpers


  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    );

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 previousRoundId
    );

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 nextRoundId
    );

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(
    address base,
    address quote
  )
    external
    view
    returns (
      uint16 currentPhaseId
    );
}
contract MockChainlinkFeedRegistry {

    IFeedRegistry public constant feedRegistry = IFeedRegistry(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf);

    struct PriceData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    mapping (address => mapping (address => mapping (uint80 => PriceData))) prices;

    mapping (address => uint80) latestRoundId;
    mapping (address => uint80) firstRoundId;

    function latestRoundData(
        address base,
        address quote
    )
        public
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ) {
            if (latestRoundId[base] == 0) {
                return feedRegistry.latestRoundData(base, quote);
            } else {
                PriceData memory p = prices[base][quote][latestRoundId[base]];
                return (p.roundId, p.answer, p.startedAt, p.updatedAt, p.answeredInRound);
            }
        }

    function setRoundData(address _base, address _quote, int256 _answer) public {
        (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ) = latestRoundData(_base, _quote);
        PriceData memory latestRound = PriceData(roundId, answer, startedAt, updatedAt, answeredInRound);

        uint80 newRoundId = latestRound.roundId + 1;

        prices[_base][_quote][newRoundId] = PriceData({
            roundId: newRoundId,
            answer: _answer,
            startedAt: block.timestamp,
            updatedAt: block.timestamp,
            answeredInRound: newRoundId
        });

        latestRoundId[_base] = newRoundId;
        if (firstRoundId[_base] == 0) {
            firstRoundId[_base] = newRoundId;
        }
        // set first round here
    }

    function getRoundData(
        address base,
        address quote,
        uint80 _roundId
    )
        external
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ) {
            PriceData memory p = prices[base][quote][_roundId];
            // this means we doesn't have a block
            if (p.roundId == 0) {
                return feedRegistry.getRoundData(base, quote, _roundId);
            }

            return (p.roundId, p.answer, p.startedAt, p.updatedAt, p.answeredInRound);
        }

    function getNextRoundId(
        address base,
        address quote,
        uint80 roundId
    ) external
        view
        returns (
        uint80 nextRoundId
        ) {
            PriceData memory p = prices[base][quote][roundId];
            // we don't have the block asked for
            if (p.roundId == 0) {
                // try to fetch from feedRegistry
                uint80 nextRound = feedRegistry.getNextRoundId(base, quote, roundId);
                // if nextRound is 0 it can be the latest round on their feed
                if (nextRound == 0) {
                    // if we have it return our first round
                    if (latestRoundId[base] > 0) {
                        return firstRoundId[base];
                    } else {
                        return nextRound;
                    }
                }
            }


            if (p.roundId + 1 > latestRoundId[base]) return 0;

            return p.roundId + 1;
        }
}