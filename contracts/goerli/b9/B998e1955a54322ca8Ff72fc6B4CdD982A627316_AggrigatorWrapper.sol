// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Interfaces/AggregatorV3Interface.sol";

contract AggrigatorWrapper {
  function getPricePerRound(
    AggregatorV3Interface aggregatorContract,
    uint80 roundId
  ) internal view returns (int256) {
    (, int256 price, , uint256 timeStamp, ) = AggregatorV3Interface(
      aggregatorContract
    ).getRoundData(roundId);
    require(timeStamp > 0, "Round not completed");
    return price;
  }

  function getLastPrice(
    AggregatorV3Interface priceFeed
  ) public view returns (int256, uint80) {
    (uint80 roundID, int256 price, , , ) = priceFeed.latestRoundData();
    return (price, roundID);
  }

  function getPriceByTime(
    AggregatorV3Interface aggregatorContract,
    uint256 time
  ) public view returns (int256, uint80) {
    uint80 offset = aggregatorContract.phaseId() * 2 ** 64;
    uint80 end = uint80(aggregatorContract.latestRound()) % offset;

    uint80 roundID = getBlockByPhase(
      aggregatorContract,
      time,
      offset,
      1,
      (end + 1) / 2,
      end
    );
    int256 price = getPricePerRound(aggregatorContract, roundID);
    return (price, roundID);
  }

  function getBlockByPhase(
    AggregatorV3Interface aggregatorContract,
    uint256 time,
    uint80 offset,
    uint80 start,
    uint80 mid,
    uint80 end
  ) public view returns (uint80) {
    require(end >= mid + 1, "Block not found");
    require(end > start, "Block not found");
    (, , , uint256 midTime, ) = aggregatorContract.getRoundData(mid + offset);
    (, , , uint256 endTime, ) = aggregatorContract.getRoundData(end + offset);
    if (midTime == 0)
      return
        getBlockByPhase(aggregatorContract, time, offset, start, mid + 1, end);
    else if (endTime == 0)
      return
        getBlockByPhase(aggregatorContract, time, offset, start, mid, end - 1);

    if (end == mid + 1) {
      if ((endTime >= time) && (midTime < time)) {
        return offset + end;
      }
    }

    require(endTime >= time, "Block not found");

    if (midTime >= time)
      return
        getBlockByPhase(
          aggregatorContract,
          time,
          offset,
          start,
          (start + mid) / 2,
          mid
        );
    else
      return
        getBlockByPhase(
          aggregatorContract,
          time,
          offset,
          mid,
          (mid + end) / 2,
          end
        );
  }

  function getLastPriceX1e6(
    AggregatorV3Interface aggregatorContract
  ) public view returns (int256, uint80) {
    (int256 price, uint80 roundID) = getLastPrice(aggregatorContract);
    return (price / 1e2, roundID);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

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

    function phaseId() external view returns (uint16);

    function latestRound() external view returns (uint256);

    function latestAnswer() external view returns (uint256);

    function latestTimestamp() external view returns (uint256);
}