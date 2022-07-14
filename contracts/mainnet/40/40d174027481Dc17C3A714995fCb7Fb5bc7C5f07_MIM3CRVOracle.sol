// SPDX-License-Identifier: AGPL-3.0-only
// Using the same Copyleft License as in the original Repository
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import './interfaces/IOracle.sol';
import '../interfaces/IChainlinkAggregator.sol';
import '../interfaces/ICurvePool.sol';
import {Math} from '../dependencies/openzeppelin/contracts/Math.sol';

/**
 * @dev Oracle contract for MIM3CRV LP Token
 */
contract MIM3CRVOracle is IOracle {
  ICurvePool private constant MIM3CRV = ICurvePool(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);
  ICurvePool private constant CRV3 = ICurvePool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

  IChainlinkAggregator private constant DAI =
    IChainlinkAggregator(0x773616E4d11A78F511299002da57A0a94577F1f4);
  IChainlinkAggregator private constant USDC =
    IChainlinkAggregator(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
  IChainlinkAggregator private constant USDT =
    IChainlinkAggregator(0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46);
  IChainlinkAggregator private constant MIM =
    IChainlinkAggregator(0x7A364e8770418566e3eb2001A96116E6138Eb32F);
  IChainlinkAggregator private constant ETH =
    IChainlinkAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

  /**
   * @dev Get price for 3Pool LP Token
   */
  function _get3CRVPrice() internal view returns (uint256) {
    (, int256 daiPrice, , , ) = DAI.latestRoundData();
    (, int256 usdcPrice, , , ) = USDC.latestRoundData();
    (, int256 usdtPrice, , , ) = USDT.latestRoundData();
    uint256 minStable = Math.min(
      uint256(daiPrice),
      Math.min(uint256(usdcPrice), uint256(usdtPrice))
    );
    return (CRV3.get_virtual_price() * minStable) / 1e18;
  }

  /**
   * @dev Get LP Token Price
   */
  function _get() internal view returns (uint256) {
    uint256 lp3crvPrice = _get3CRVPrice();
    (, int256 mimPrice, , , ) = MIM.latestRoundData();
    (, int256 ethPrice, , , ) = ETH.latestRoundData();

    // convert mimPrice from usd unit to eth unit and get min value
    uint256 minValue = Math.min((uint256(mimPrice) * 1e18) / uint256(ethPrice), lp3crvPrice);

    return (MIM3CRV.get_virtual_price() * minValue) / 1e18;
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