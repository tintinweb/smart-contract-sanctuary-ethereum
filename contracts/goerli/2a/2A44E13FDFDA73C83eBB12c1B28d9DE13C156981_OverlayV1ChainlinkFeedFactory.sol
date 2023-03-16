// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "OverlayV1FeedFactory.sol";
import "OverlayV1ChainlinkFeed.sol";
import "IOverlayV1ChainlinkFeedFactory.sol";

contract OverlayV1ChainlinkFeedFactory is IOverlayV1ChainlinkFeedFactory, OverlayV1FeedFactory {
    // registry of feeds; for a given aggregator pair, returns associated feed
    mapping(address => address) public getFeed;

    constructor(uint256 _microWindow, uint256 _macroWindow)
        OverlayV1FeedFactory(_microWindow, _macroWindow)
    {}

    /// @dev deploys a new feed contract
    /// @param _aggregator chainlink price feed
    /// @return _feed address of the new feed
    function deployFeed(address _aggregator) external returns (address _feed) {
        // check feed doesn't already exist
        require(getFeed[_aggregator] == address(0), "OVLV1: feed already exists");

        // Create a new Feed contract
        _feed = address(new OverlayV1ChainlinkFeed(_aggregator, microWindow, macroWindow));

        // store feed registry record for _aggregator and record address as deployed feed
        getFeed[_aggregator] = _feed;
        isFeed[_feed] = true;

        emit FeedDeployed(msg.sender, _feed);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "IOverlayV1FeedFactory.sol";
import "Oracle.sol";

abstract contract OverlayV1FeedFactory is IOverlayV1FeedFactory {
    uint256 public immutable microWindow;
    uint256 public immutable macroWindow;

    // registry of deployed feeds by factory
    mapping(address => bool) public isFeed;

    event FeedDeployed(address indexed user, address feed);

    constructor(uint256 _microWindow, uint256 _macroWindow) {
        // sanity checks on micro and macroWindow
        require(_microWindow > 0, "OVLV1: microWindow == 0");
        require(_macroWindow >= _microWindow, "OVLV1: macroWindow < microWindow");
        require(_macroWindow <= 86400, "OVLV1: macroWindow > 1 day");

        microWindow = _microWindow;
        macroWindow = _macroWindow;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "Oracle.sol";

interface IOverlayV1FeedFactory {
    // immutables
    function microWindow() external view returns (uint256);

    function macroWindow() external view returns (uint256);

    // registry of deployed feeds by factory
    function isFeed(address) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

library Oracle {
    struct Data {
        uint256 timestamp;
        uint256 microWindow;
        uint256 macroWindow;
        uint256 priceOverMicroWindow; // p(now) averaged over micro
        uint256 priceOverMacroWindow; // p(now) averaged over macro
        uint256 priceOneMacroWindowAgo; // p(now - macro) avg over macro
        uint256 reserveOverMicroWindow; // r(now) in ovl averaged over micro
        bool hasReserve; // whether oracle has manipulable reserve pool
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "OverlayV1Feed.sol";
import "AggregatorV3Interface.sol";

contract OverlayV1ChainlinkFeed is OverlayV1Feed {
    AggregatorV3Interface public immutable aggregator;
    string public description;
    uint8 public decimals;

    constructor(
        address _aggregator,
        uint256 _microWindow,
        uint256 _macroWindow
    ) OverlayV1Feed(_microWindow, _macroWindow) {
        require(_aggregator != address(0), "Invalid feed");

        aggregator = AggregatorV3Interface(_aggregator);
        decimals = aggregator.decimals();
        description = aggregator.description();
    }

    function _fetch() internal view virtual override returns (Oracle.Data memory) {
        (uint80 roundId, , , , ) = aggregator.latestRoundData();

        (
            uint256 priceOverMicroWindow,
            uint256 priceOverMacroWindow,
            uint256 priceOneMacroWindowAgo
        ) = _getAveragePrice(roundId);

        return
            Oracle.Data({
                timestamp: block.timestamp,
                microWindow: microWindow,
                macroWindow: macroWindow,
                priceOverMicroWindow: priceOverMicroWindow,
                priceOverMacroWindow: priceOverMacroWindow,
                priceOneMacroWindowAgo: priceOneMacroWindowAgo,
                reserveOverMicroWindow: 0,
                hasReserve: false
            });
    }

    function _getAveragePrice(uint80 roundId)
        internal
        view
        returns (
            uint256 priceOverMicroWindow,
            uint256 priceOverMacroWindow,
            uint256 priceOneMacroWindowAgo
        )
    {
        // nextTimestamp will be next time stamp recorded from current round id
        uint256 nextTimestamp = block.timestamp;
        // these values will keep decreasing till zero,
        // until all data is used up in respective window
        uint256 _microWindow = microWindow;
        uint256 _macroWindow = macroWindow;

        // timestamp till which value need to be considered for macrowindow ago
        uint256 macroAgoTargetTimestamp = nextTimestamp - 2 * macroWindow;

        uint256 sumOfPriceMicroWindow;
        uint256 sumOfPriceMacroWindow;
        uint256 sumOfPriceMacroWindowAgo;

        while (true) {
            (, int256 answer, , uint256 updatedAt, ) = aggregator.getRoundData(roundId);

            if (_microWindow > 0) {
                uint256 dt = nextTimestamp - updatedAt < _microWindow
                    ? nextTimestamp - updatedAt
                    : _microWindow;
                sumOfPriceMicroWindow += dt * uint256(answer);
                _microWindow -= dt;
            }

            if (_macroWindow > 0) {
                uint256 dt = nextTimestamp - updatedAt < _macroWindow
                    ? nextTimestamp - updatedAt
                    : _macroWindow;
                sumOfPriceMacroWindow += dt * uint256(answer);
                _macroWindow -= dt;
            }

            if (updatedAt <= block.timestamp - macroWindow) {
                uint256 startTime = nextTimestamp > block.timestamp - macroWindow
                    ? block.timestamp - macroWindow
                    : nextTimestamp;
                if (updatedAt >= macroAgoTargetTimestamp) {
                    sumOfPriceMacroWindowAgo += (startTime - updatedAt) * uint256(answer);
                } else {
                    sumOfPriceMacroWindowAgo +=
                        (startTime - macroAgoTargetTimestamp) *
                        uint256(answer);
                    break;
                }
            }

            nextTimestamp = updatedAt;
            roundId--;
        }

        priceOverMicroWindow =
            (sumOfPriceMicroWindow * (10**18)) /
            (microWindow * 10**aggregator.decimals());
        priceOverMacroWindow =
            (sumOfPriceMacroWindow * (10**18)) /
            (macroWindow * 10**aggregator.decimals());
        priceOneMacroWindowAgo =
            (sumOfPriceMacroWindowAgo * (10**18)) /
            (macroWindow * 10**aggregator.decimals());
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "IOverlayV1Feed.sol";
import "Oracle.sol";

abstract contract OverlayV1Feed is IOverlayV1Feed {
    using Oracle for Oracle.Data;

    address public immutable feedFactory;
    uint256 public immutable microWindow;
    uint256 public immutable macroWindow;

    constructor(uint256 _microWindow, uint256 _macroWindow) {
        // set the immutables
        microWindow = _microWindow;
        macroWindow = _macroWindow;
        feedFactory = msg.sender;
    }

    /// @dev returns freshest possible data from oracle
    function latest() external view returns (Oracle.Data memory) {
        return _fetch();
    }

    /// @dev fetches data from oracle. should be implemented differently
    /// @dev for each feed type
    function _fetch() internal view virtual returns (Oracle.Data memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "Oracle.sol";

interface IOverlayV1Feed {
    // immutables
    function feedFactory() external view returns (address);

    function microWindow() external view returns (uint256);

    function macroWindow() external view returns (uint256);

    // returns freshest possible data from oracle
    function latest() external view returns (Oracle.Data memory);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "IOverlayV1FeedFactory.sol";

interface IOverlayV1ChainlinkFeedFactory is IOverlayV1FeedFactory {
    // registry of feeds; for a given aggregator, returns associated feed
    function getFeed(address _aggregator) external view returns (address _feed);

    /// @dev deploys a new feed contract
    /// @return _feed address of the new feed
    function deployFeed(address _aggregator) external returns (address _feed);
}