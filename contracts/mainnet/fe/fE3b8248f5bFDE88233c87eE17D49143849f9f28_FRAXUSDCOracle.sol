// SPDX-License-Identifier: AGPL-3.0-only
// Using the same Copyleft License as in the original Repository
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import './interfaces/IOracle.sol';
import '../interfaces/IChainlinkAggregator.sol';
import '../interfaces/ICurvePool.sol';
import {Math} from '../dependencies/openzeppelin/contracts/Math.sol';

/**
 * @dev Oracle contract for FRAXUSDC LP Token
 */
contract FRAXUSDCOracle is IOracle {
  ICurvePool private constant FRAXUSDC = ICurvePool(0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2);

  IChainlinkAggregator private constant USDC =
    IChainlinkAggregator(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
  IChainlinkAggregator private constant FRAX =
    IChainlinkAggregator(0x14d04Fff8D21bd62987a5cE9ce543d2F1edF5D3E);

  /**
   * @dev Get LP Token Price
   */
  function _get() internal view returns (uint256) {
    (, int256 usdcPrice, , , ) = USDC.latestRoundData();
    (, int256 fraxPrice, , , ) = FRAX.latestRoundData();
    uint256 minValue = Math.min(uint256(fraxPrice), uint256(usdcPrice));

    return (FRAXUSDC.get_virtual_price() * minValue) / 1e18;
  }

  // Get the latest exchange rate, if no valid (recent) rate is available, return false
  /// @inheritdoc IOracle
  function get() public view override returns (bool, uint256) {
    return (true, _get());
  }

  // Check the last exchange rate without any state changes
  /// @inheritdoc IOracle
  function peek() public view override returns (bool, int256) {
    return (true, int256(_get()));
  }

  // Check the current spot exchange rate without any state changes
  /// @inheritdoc IOracle
  function latestAnswer() external view override returns (int256 rate) {
    return int256(_get());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
  /// @notice Get the latest price.
  /// @return success if no valid (recent) rate is available, return false else true.
  /// @return rate The rate of the requested asset / pair / pool.
  function get() external returns (bool success, uint256 rate);

  /// @notice Check the last price without any state changes.
  /// @return success if no valid (recent) rate is available, return false else true.
  /// @return rate The rate of the requested asset / pair / pool.
  function peek() external view returns (bool success, int256 rate);

  /// @notice Check the current spot price without any state changes. For oracles like TWAP this will be different from peek().
  /// @return rate The rate of the requested asset / pair / pool.
  function latestAnswer() external view returns (int256 rate);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IChainlinkAggregator {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

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

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ICurvePool {
  function get_virtual_price() external view returns (uint256 price);

  function coins(uint256) external view returns (address);

  function calc_withdraw_one_coin(
    uint256 _burn_amount,
    int128 i,
    bool _previous
  ) external view returns (uint256);

  function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _burn_amount,
    int128 i,
    uint256 _min_received,
    address _receiver
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _burn_amount,
    int128 i,
    uint256 _min_received
  ) external;

  /**
   * @dev Index values can be found via the `coins` public getter method
   * @param i Index value for the coin to send
   * @param j Index valie of the coin to recieve
   * @param dx Amount of `i` being exchanged
   * @param min_dy Minimum amount of `j` to receive
   * @return Actual amount of `j` received
   **/
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);

  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}