// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title ChainlinkComputedFeed
 *
 * @author Xocolatl.eth
 *
 * @notice Contract that combines two chainlink price feeds into
 * one resulting feed denominated in another currency asset.
 *
 * @dev For example: [wsteth/eth]-feed and [eth/usd]-feed to return a [wsteth/usd]-feed.
 * Note: Ensure units work, this contract multiplies the feeds.
 */

import {IAggregatorV3} from "../interfaces/chainlink/IAggregatorV3.sol";

interface IWstETH {
  function stEthPerToken() external view returns (uint256);
}

contract ChainlinkComputedFeedLido {
  struct ChainlinkResponse {
    uint80 roundId;
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
  }

  ///@dev custom errors
  error ChainlinkComputedFeed_invalidInput();
  error ChainlinkComputedFeed_fetchFeedAssetFailed();
  error ChainlinkComputedFeed_fetchFeedInterFailed();
  error ChainlinkComputedFeed_lessThanOrZeroAnswer();
  error ChainlinkComputedFeed_noRoundId();
  error ChainlinkComputedFeed_noValidUpdateAt();
  error ChainlinkComputedFeed_staleFeed();

  string private _description;

  uint8 private immutable _decimals;
  uint8 private immutable _feedAssetDecimals;
  uint8 private immutable _feedInterAssetDecimals;

  IWstETH public immutable feedAsset;
  IAggregatorV3 public immutable feedInterAsset;

  uint256 public immutable allowedTimeout;

  constructor(
    string memory description_,
    uint8 decimals_,
    address feedAsset_,
    address feedInterAsset_,
    uint256 allowedTimeout_
  ) {
    _description = description_;
    _decimals = decimals_;

    if (feedAsset_ == address(0) || feedInterAsset_ == address(0) || allowedTimeout_ == 0) {
      revert ChainlinkComputedFeed_invalidInput();
    }

    feedAsset = IWstETH(feedAsset_);
    feedInterAsset = IAggregatorV3(feedInterAsset_);

    _feedAssetDecimals = IAggregatorV3(feedAsset_).decimals();
    _feedInterAssetDecimals = IAggregatorV3(feedInterAsset_).decimals();

    allowedTimeout = allowedTimeout_;
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function description() external view returns (string memory) {
    return _description;
  }

  function latestAnswer() external view returns (int256) {
    ChainlinkResponse memory clComputed = _computeLatestRoundData();
    return clComputed.answer;
  }

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    ChainlinkResponse memory clComputed = _computeLatestRoundData();
    roundId = clComputed.roundId;
    answer = clComputed.answer;
    startedAt = clComputed.startedAt;
    updatedAt = clComputed.updatedAt;
    answeredInRound = roundId;
  }

  function _computeLatestRoundData() private view returns (ChainlinkResponse memory clComputed) {
    (int256 feedAnswer, ChainlinkResponse memory clInter) = _callandCheckFeeds();

    clComputed.answer = _computeAnswer(feedAnswer, clInter.answer);
    clComputed.roundId = clInter.roundId;
    clComputed.startedAt = clInter.startedAt;
    clComputed.updatedAt = clInter.updatedAt;
    clComputed.answeredInRound = clComputed.roundId;
  }

  function _computeAnswer(
    int256 assetAnswer,
    int256 interAssetAnswer
  )
    private
    view
    returns (int256)
  {
    uint256 price = (uint256(assetAnswer) * uint256(interAssetAnswer) * 10 ** (uint256(_decimals)))
      / 10 ** (uint256(_feedAssetDecimals + _feedInterAssetDecimals));
    return int256(price);
  }

  function _callandCheckFeeds()
    private
    view
    returns (int256 feedAnswer, ChainlinkResponse memory clInter)
  {
    feedAnswer = int256(feedAsset.stEthPerToken());

    (clInter.roundId, clInter.answer, clInter.startedAt, clInter.updatedAt, clInter.answeredInRound)
    = feedInterAsset.latestRoundData();

    // Perform checks to the returned chainlink responses
    if (clInter.answer <= 0) {
      revert ChainlinkComputedFeed_lessThanOrZeroAnswer();
    } else if (clInter.roundId == 0) {
      revert ChainlinkComputedFeed_noRoundId();
    } else if (clInter.updatedAt > block.timestamp || clInter.updatedAt == 0) {
      revert ChainlinkComputedFeed_noValidUpdateAt();
    } else if (block.timestamp - clInter.updatedAt > allowedTimeout) {
      revert ChainlinkComputedFeed_staleFeed();
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IAggregatorV3 {
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