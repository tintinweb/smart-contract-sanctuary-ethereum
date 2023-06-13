// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IChainlinkAggregator} from '../interfaces/IChainlinkAggregator.sol';
import {ICLSynchronicityPriceAdapter} from '../interfaces/ICLSynchronicityPriceAdapter.sol';
import {IStETH} from '../interfaces/IStETH.sol';

/**
 * @title WstETHSynchronicityPriceAdapter
 * @author BGD Labs
 * @notice Price adapter to calculate price of (wstETH / USD) pair by using
 * @notice Chainlink data feed for (ETH / USD) and (wstETH / stETH) ratio.
 */
contract WstETHSynchronicityPriceAdapter is ICLSynchronicityPriceAdapter {
  /**
   * @notice Price feed for (ETH / Base) pair
   */
  IChainlinkAggregator public immutable ETH_TO_BASE;

  /**
   * @notice stETH token contract to get ratio
   */
  IStETH public immutable STETH;

  /**
   * @notice Number of decimals for wstETH / stETH ratio
   */
  uint8 public constant RATIO_DECIMALS = 18;

  /**
   * @notice Number of decimals in the output of this price adapter
   */
  uint8 public immutable DECIMALS;

  string private _description;

  /**
   * @param ethToBaseAggregatorAddress the address of ETH / BASE feed
   * @param stEthAddress the address of the stETH contract
   * @param pairName name identifier
   */
  constructor(address ethToBaseAggregatorAddress, address stEthAddress, string memory pairName) {
    ETH_TO_BASE = IChainlinkAggregator(ethToBaseAggregatorAddress);
    STETH = IStETH(stEthAddress);

    DECIMALS = ETH_TO_BASE.decimals();

    _description = pairName;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function description() external view returns (string memory) {
    return _description;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function decimals() external view returns (uint8) {
    return DECIMALS;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function latestAnswer() public view virtual override returns (int256) {
    int256 ethToBasePrice = ETH_TO_BASE.latestAnswer();
    int256 ratio = int256(STETH.getPooledEthByShares(10 ** RATIO_DECIMALS));

    if (ethToBasePrice <= 0 || ratio <= 0) {
      return 0;
    }

    return (ethToBasePrice * ratio) / int256(10 ** RATIO_DECIMALS);
  }
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

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICLSynchronicityPriceAdapter {
  /**
   * @notice Calculates the current answer based on the aggregators.
   * @return int256 latestAnswer
   */
  function latestAnswer() external view returns (int256);

  /**
   * @notice Returns the description of the feed
   * @return string desciption
   */
  function description() external view returns (string memory);

  /**
   * @notice Returns the feed decimals
   * @return uint8 decimals
   */
  function decimals() external view returns (uint8);

  error DecimalsAboveLimit();
  error DecimalsNotEqual();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStETH {
  function getPooledEthByShares(uint256 shares) external view returns (uint256);
}