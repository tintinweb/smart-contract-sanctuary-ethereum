// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IChainlinkAggregator} from '../interfaces/IChainlinkAggregator.sol';
import {ICLSynchronicityPriceAdapter} from '../interfaces/ICLSynchronicityPriceAdapter.sol';
import {IrETH} from '../interfaces/IrETH.sol';

/**
 * @title CLrETHSynchronicityPriceAdapter
 * @author BGD Labs
 * @notice Price adapter to calculate price of (rETH / USD) pair by using
 * @notice Chainlink Data Feed for (ETH / USD) pair and (rETH / ETH) ratio.
 */
contract CLrETHSynchronicityPriceAdapter is ICLSynchronicityPriceAdapter {
  /**
   * @notice Price feed for (ETH / USD) pair
   */
  IChainlinkAggregator public immutable ETH_TO_USD;

  /**
   * @notice rETH token contract
   */
  IrETH public immutable RETH;

  /**
   * @notice Number of decimals for the rETH / ETH ratio
   */
  uint8 public constant RATIO_DECIMALS = 18;

  string private _name;

  /**
   * @param ethToUSDAggregatorAddress the address of ETH / USD feed
   * @param rETHAddress the address of rETH token
   * @param pairName name identifier
   */
  constructor(address ethToUSDAggregatorAddress, address rETHAddress, string memory pairName) {
    ETH_TO_USD = IChainlinkAggregator(ethToUSDAggregatorAddress);
    RETH = IrETH(rETHAddress);

    _name = pairName;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function name() external view returns (string memory) {
    return _name;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function latestAnswer() public view virtual override returns (int256) {
    int256 ethToUsdPrice = ETH_TO_USD.latestAnswer();
    int256 ethToREthRatio = int256(RETH.getExchangeRate());

    if (ethToUsdPrice <= 0) {
      return 0;
    }

    return ((ethToUsdPrice * ethToREthRatio) / int256(10 ** RATIO_DECIMALS));
  }
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
   * @notice Returns the name identifier of the feed
   * @return string name
   */
  function name() external view returns (string memory);

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

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice A simple version of the rETH interface allowing to get exchange rate with ETH
interface IrETH {
  /**
   * @notice Get the current ETH : rETH exchange rate
   * @return the amount of ETH backing 1 rETH
   */
  function getExchangeRate() external view returns (uint256);
}