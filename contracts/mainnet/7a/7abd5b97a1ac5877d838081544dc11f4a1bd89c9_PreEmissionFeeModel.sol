// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./IFeeModel.sol";

contract PreEmissionFeeModel is IFeeModel {
  function getFeeRate(
    uint256, /*_startBlock*/
    uint256, /*_currentBlock*/
    uint256 /*_endBlock*/
  ) external pure returns (uint256) {
    return 0;
  }
}