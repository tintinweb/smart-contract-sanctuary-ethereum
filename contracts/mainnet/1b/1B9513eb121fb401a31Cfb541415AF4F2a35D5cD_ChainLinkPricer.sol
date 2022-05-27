// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AggregatorProxy.sol";
import "./ChainlinkRoundIdCalc.sol";

contract ChainLinkPricer {
    using ChainlinkRoundIdCalc for AggregatorProxy;

    //AggregatorProxy public ethUsd;

    // constructor() {
    //     ethUsd = AggregatorProxy(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    // }

    function next(address pricer, uint256 roundId) public view returns (uint80) {
        return AggregatorProxy(pricer).next(roundId);
    }

    function prev(address pricer, uint256 roundId) public view returns (uint80) {
        return AggregatorProxy(pricer).prev(roundId);
    }

    function addPhase(uint16 _phase, uint64 _originalId) public pure returns (uint80) {
        return ChainlinkRoundIdCalc.addPhase(_phase, _originalId);
    }

    function parseIds(uint256 roundId) public pure returns (uint16, uint64) {
        return ChainlinkRoundIdCalc.parseIds(roundId);
    }

    function getLatestPrice(address pricer) public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorProxy(pricer).latestRoundData();
        return price;
    }

    function getLatestRoundId(address pricer) public view returns (uint80) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorProxy(pricer).latestRoundData();
        return roundID;
    }

    function getHistoricalPrice(address pricer, uint80 roundId) public view returns (int256) {
        (
            uint80 id, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorProxy(pricer).getRoundData(roundId);
        require(timeStamp > 0, "Round not complete");
        return price;
    }

    function getHistoricalRoundData(address pricer, uint80 roundId) public view returns  (uint80, int, uint, uint, uint80) {
       return AggregatorProxy(pricer).getRoundData(roundId);
    }

    function getLatestRoundData(address pricer) public view returns (uint80, int, uint, uint, uint80) {
        return AggregatorProxy(pricer).latestRoundData();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}


interface AggregatorProxy is AggregatorV2V3Interface {
    function phaseId() external view returns (uint16);
    function phaseAggregators(uint16 phaseId) external view returns (AggregatorV2V3Interface);
}

pragma solidity ^0.8.7;

import "./AggregatorProxy.sol";

library ChainlinkRoundIdCalc {
    uint256 constant private PHASE_OFFSET = 64;

    /// @return the next round ID
    // @dev if roundId is the latest round, return the same roundId to indicate that we can't go forward any more
    function next(AggregatorProxy proxy, uint256 roundId) internal view returns (uint80)
    {
        (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(roundId);

        if (proxy.getAnswer(addPhase(phaseId, aggregatorRoundId+1)) != 0) {
            aggregatorRoundId++;
        }
        else if (phaseId < proxy.phaseId()) {
            phaseId++;
            aggregatorRoundId = 1;
        }
        return addPhase(phaseId, aggregatorRoundId);
    }

    /// @return the previous round ID 
    /// @dev if roundId is the first ever round, return the same roundId to indicate that we can't go back any further
    function prev(AggregatorProxy proxy, uint256 roundId) internal view returns (uint80)
    {
        (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(roundId);

        if (aggregatorRoundId > 1) {
            aggregatorRoundId--;
        }
        else if (phaseId > 1) {
            phaseId--;
            // access to latestRound() is restricted, making this library pretty much useless
            // there isn't a good work around as far as I can tell
            aggregatorRoundId = uint64(proxy.phaseAggregators(phaseId).latestRound());
        }
        return addPhase(phaseId, aggregatorRoundId);
    }
    
    /// @dev copied from chainlink aggregator contract
    function addPhase(uint16 _phase, uint64 _originalId) internal pure returns (uint80)
    {
        return uint80(uint256(_phase) << PHASE_OFFSET | _originalId);
    }

    /// @dev copied from chainlink aggregator contract
    function parseIds(uint256 _roundId) internal pure returns (uint16, uint64)
    {
        uint16 phaseId = uint16(_roundId >> PHASE_OFFSET);
        uint64 aggregatorRoundId = uint64(_roundId);

        return (phaseId, aggregatorRoundId);
    }

/* 
    not useful for most applications
    
    code is untested
    /// @notice add `i` to `roundId`. Useful for searching for a particular timestamp
    /// @dev minimum possible phaseId is 1
    /// @dev minimum possible aggregatorRoundId is 1
    /// @dev if desired move amount is gt the current max ID, return the current max ID
    /// @dev if desired move amount is lt the minimum possible ID, return the minimum possible ID
    function move(AggregatorProxy proxy, uint256 roundId, int i) public view returns (uint80, int) {
        (uint16 phaseId, uint64 aggregatorRoundId) = parseIds(roundId);
        int moved = 0;
        if (i < 0) {
            while (i < 0) {
                if (-1*i < aggregatorRoundId) {
                    moved += i;
                    aggregatorRoundId += i;
                    i -= i;
                }
                else if (phaseId <= 1) {
                    moved -= aggregatorRoundId - 1;
                    aggregatorRoundId = 1;
                    i = 0;
                }
                else {
                    phaseId -= 1;
                    moved -= aggregatorRoundId;
                    i += aggregatorRoundId;
                    aggregatorRoundId = uint64(proxy.phaseAggregators(phaseId).latestRound());
                }
            }
        }
        else if (i > 0) {
            while (i > 0) {
                uint32 latestAggregatorRoundId = proxy.phaseAggregators(phaseId).latestRound();
                if (aggregatorRoundId + i <= latestAggregatorRoundId) {
                    moved += i;
                    aggregatorRoundId += i;
                    i -= i;
                }
                else if (phaseId >= proxy.phaseId()) {
                    moved += latestAggregatorRoundId - aggregatorRoundId;
                    aggregatorRoundId = latestAggregatorRoundId;
                    i = 0;
                } else {
                    phaseId += 1;
                    moved += latestAggregatorRoundId - aggregatorRoundId + 1;
                    i -= latestAggregatorRoundId - aggregatorRoundId + 1;
                    aggregatorRoundId = 1;
                }
            }
        }
        return addPhase(phaseId, aggregatorRoundId);
    }
    */
}