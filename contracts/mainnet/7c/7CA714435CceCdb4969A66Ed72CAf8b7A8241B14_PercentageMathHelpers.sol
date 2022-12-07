// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @dev PercentageMath contract is recommended to use only in Shortcuts passed to EnsoWallet
 *
 * Forked from Aave PercentageMath library:
 * - protocol-v2/contracts/protocol/libraries/math/PercentageMath.sol (https://github.com/aave/protocol-v2/blob/ice/mainnet-deployment-03-12-2020/contracts/protocol/libraries/math/PercentageMath.sol)
 */

contract PercentageMathHelpers {
  uint256 public constant VERSION = 1;
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/

  function percentMul(uint256 value, uint256 percentage) external pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(
      value <= (type(uint256).max - HALF_PERCENT) / percentage, "multiplication overflow"
    );

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) external pure returns (uint256) {
    require(percentage != 0, "Division by 0");
    uint256 halfPercentage = percentage / 2;

    require(
      value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR, "multiplication overflow"
    );

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}