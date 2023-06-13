// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IChainlinkAggregator} from '../interfaces/IChainlinkAggregator.sol';
import {ICLSynchronicityPriceAdapter} from '../interfaces/ICLSynchronicityPriceAdapter.sol';

/**
 * @title StETHtoETHSynchronicityPriceAdapter
 * @author BGD Labs
 * @notice Price adapter to return a constant 1:1 price of (stETH / ETH) pair.
 */
contract StETHtoETHSynchronicityPriceAdapter is ICLSynchronicityPriceAdapter {
  /**
   * @notice Number of decimals in the output of this price adapter
   */
  uint8 public constant DECIMALS = 18;

  string private _description;

  /**
   * @param pairName name identifier
   */
  constructor(string memory pairName) {
    _description = pairName;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function description() external view returns (string memory) {
    return _description;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function decimals() external pure returns (uint8) {
    return DECIMALS;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function latestAnswer() public view virtual override returns (int256) {
    return 1 ether;
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