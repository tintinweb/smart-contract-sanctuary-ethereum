// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IChainlinkAggregator} from '../interfaces/IChainlinkAggregator.sol';
import {ICLSynchronicityPriceAdapter} from '../interfaces/ICLSynchronicityPriceAdapter.sol';

/**
 * @title CLSynchronicityPriceAdapter
 * @author BGD Labs
 * @notice Price adapter to calculate price of (Asset / Base) pair by using
 * @notice Chainlink Data Feeds for (Asset / Peg) and (Peg / Base) pairs.
 * @notice For example it can be used to calculate stETH / USD
 * @notice based on stETH / ETH and ETH / USD feeds.
 */
contract CLSynchronicityPriceAdapterPegToBase is ICLSynchronicityPriceAdapter {
  /**
   * @notice Price feed for (Base / Peg) pair
   */
  IChainlinkAggregator public immutable PEG_TO_BASE;

  /**
   * @notice Price feed for (Asset / Peg) pair
   */
  IChainlinkAggregator public immutable ASSET_TO_PEG;

  /**
   * @notice Number of decimals in the output of this price adapter
   */
  uint8 public immutable DECIMALS;

  /**
   * @notice This is a parameter to bring the resulting answer with the proper precision.
   * @notice will be equal to 10 to the power of the sum decimals of feeds
   */
  int256 public immutable DENOMINATOR;

  /**
   * @notice Maximum number of resulting and feed decimals
   */
  uint8 public constant MAX_DECIMALS = 18;

  /**
   * @param pegToBaseAggregatorAddress the address of PEG / BASE feed
   * @param assetToPegAggregatorAddress the address of the ASSET / PEG feed
   * @param decimals precision of the answer
   */
  constructor(
    address pegToBaseAggregatorAddress,
    address assetToPegAggregatorAddress,
    uint8 decimals
  ) {
    PEG_TO_BASE = IChainlinkAggregator(pegToBaseAggregatorAddress);
    ASSET_TO_PEG = IChainlinkAggregator(assetToPegAggregatorAddress);

    if (decimals > MAX_DECIMALS) revert DecimalsAboveLimit();
    if (PEG_TO_BASE.decimals() > MAX_DECIMALS) revert DecimalsAboveLimit();
    if (ASSET_TO_PEG.decimals() > MAX_DECIMALS) revert DecimalsAboveLimit();

    DECIMALS = decimals;

    // equal to 10 to the power of the sum decimals of feeds
    unchecked {
      DENOMINATOR = int256(
        10 ** (PEG_TO_BASE.decimals() + ASSET_TO_PEG.decimals())
      );
    }
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function latestAnswer() public view virtual override returns (int256) {
    int256 assetToPegPrice = ASSET_TO_PEG.latestAnswer();
    int256 pegToBasePrice = PEG_TO_BASE.latestAnswer();

    if (assetToPegPrice <= 0 || pegToBasePrice <= 0) {
      return 0;
    }

    return
      (assetToPegPrice * pegToBasePrice * int256(10 ** DECIMALS)) /
      (DENOMINATOR);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IChainlinkAggregator} from '../interfaces/IChainlinkAggregator.sol';
import {ICLSynchronicityPriceAdapter} from '../interfaces/ICLSynchronicityPriceAdapter.sol';
import {IStETH} from '../interfaces/IStETH.sol';
import {CLSynchronicityPriceAdapterPegToBase} from './CLSynchronicityPriceAdapterPegToBase.sol';

/**
 * @title CLwstETHSynchronicityPriceAdapter
 * @author BGD Labs
 * @notice Price adapter to calculate price of (wstETH / USD) pair by using
 * @notice Chainlink Data Feeds for (stETH / ETH) and (ETH / USd) pairs and (wstETH / stETH) ratio.
 */
contract CLwstETHSynchronicityPriceAdapter is
  CLSynchronicityPriceAdapterPegToBase
{
  /**
   * @notice stETH token contract
   */
  IStETH public immutable STETH;

  /**
   * @notice Number of decimals for wstETH / ETH ratio
   */
  uint8 public constant RATIO_DECIMALS = 18;

  constructor(
    address pegToBaseAggregatorAddress,
    address assetToPegAggregatorAddress,
    uint8 decimals,
    address stETHAddress
  )
    CLSynchronicityPriceAdapterPegToBase(
      pegToBaseAggregatorAddress,
      assetToPegAggregatorAddress,
      decimals
    )
  {
    STETH = IStETH(stETHAddress);
  }

  /// @inheritdoc CLSynchronicityPriceAdapterPegToBase
  function latestAnswer() public view override returns (int256) {
    int256 stethToUsdPrice = super.latestAnswer();

    int256 ratio = int256(STETH.getPooledEthByShares(10 ** RATIO_DECIMALS));

    return (stethToUsdPrice * int256(ratio)) / int256(10 ** RATIO_DECIMALS);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICLSynchronicityPriceAdapter {
  /**
   * @notice Calculates the current answer based on the aggregators.
   */
  function latestAnswer() external view returns (int256);

  error DecimalsAboveLimit();
  error DecimalsNotEqual();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlinkAggregator {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 timestamp
  );
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStETH {
  function getPooledEthByShares(uint256 shares) external view returns (uint256);
}