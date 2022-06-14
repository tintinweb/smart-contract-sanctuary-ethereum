// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Chainlink Price Feed Aggregator V3 Mock
 *
 * @notice Supports the Illuvitars Price Oracle with the ILV/ETH price feed
 *
 * @dev Enables testing of the feed, playing with current timestamp
 *
 * @author Basil Gorin
 */
contract ChainlinkAggregatorV3Mock is AggregatorV3Interface {
    // values returned by `latestRoundData()`
    uint80 public roundIdMocked = 1;
    int256 public answerMocked = -1;
    uint256 public startedAtMocked = type(uint256).max;
    uint256 public updatedAtMocked = type(uint256).max;
    uint80 public answeredInRoundMocked = 1;
    // answer (conversion rate) is derived from the ILV/ETH ratio
    // initial conversion rate is 1 ETH = 4 ILV
    uint256 public ethOut = 1;
    uint256 public ilvIn = 4;

    /// @dev overridden value to use as now32()
    uint256 private _now256;

    /// @dev overrides now256()
    function setNow256(uint256 value) public {
        _now256 = value;
    }

    /**
     * @dev Testing time-dependent functionality may be difficult;
     *      we override time in the helper test smart contract (mock)
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
     */
    function now256() public view returns (uint256) {
        return _now256 > 0 ? _now256 : block.timestamp;
    }

    /**
     * @dev Overrides roundId, answer, startedAt, updatedAt, answeredInRound
     */
    function setMockedValues(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) public {
        roundIdMocked = roundId;
        answerMocked = answer;
        startedAtMocked = startedAt;
        updatedAtMocked = updatedAt;
        answeredInRoundMocked = answeredInRound;
    }

    // updates the conversion rate
    function setRate(uint256 _ethOut, uint256 _ilvIn) public {
        ethOut = _ethOut;
        ilvIn = _ilvIn;
    }

    /**
     * @inheritdoc AggregatorV3Interface
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @inheritdoc AggregatorV3Interface
     */
    function description() public pure override returns (string memory) {
        return "ILV / ETH (Mock!)";
    }

    /**
     * @inheritdoc AggregatorV3Interface
     */
    function version() public pure override returns (uint256) {
        return 0;
    }

    /**
     * @inheritdoc AggregatorV3Interface
     */
    function getRoundData(uint80 _roundId)
        public
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        require(_roundId == roundIdMocked, "roundId differs from the roundId mocked value");
        return latestRoundData();
    }

    /**
     * @inheritdoc AggregatorV3Interface
     */
    function latestRoundData()
        public
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            roundIdMocked,
            answerMocked >= 0 ? answerMocked : int256((10**decimals() * ethOut) / ilvIn),
            startedAtMocked < type(uint256).max ? startedAtMocked : now256(),
            updatedAtMocked < type(uint256).max ? updatedAtMocked : now256(),
            answeredInRoundMocked
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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