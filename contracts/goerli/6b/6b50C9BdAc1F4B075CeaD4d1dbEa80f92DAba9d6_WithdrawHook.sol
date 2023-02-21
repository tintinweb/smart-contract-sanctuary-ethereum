/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.18;

contract WithdrawHook {
  uint256 private _globalPeriodLength;
  uint256 private _globalWithdrawLimitPerPeriod;
  uint256 private _lastGlobalPeriodReset;
  uint256 private _globalAmountWithdrawnThisPeriod;

  function getGlobalPeriodLength() external view returns (uint256) {
    return _globalPeriodLength;
  }

  function getGlobalWithdrawLimitPerPeriod() external view returns (uint256) {
    return _globalWithdrawLimitPerPeriod;
  }

  function getLastGlobalPeriodReset() external view returns (uint256) {
    return _lastGlobalPeriodReset;
  }

  function getGlobalAmountWithdrawnThisPeriod() external view returns (uint256) {
    return _globalAmountWithdrawnThisPeriod;
  }

  function setGlobalPeriodLength(uint256 globalPeriodLength) external {
    _globalPeriodLength = globalPeriodLength;
  }

  function setGlobalWithdrawalLimitPerPeriod(uint256 globalWithdrawLimitPerPeriod) external {
    _globalWithdrawLimitPerPeriod = globalWithdrawLimitPerPeriod;
  }

  function fakeWithdraw(uint256 amount) external {
    if (_lastGlobalPeriodReset + _globalPeriodLength < block.timestamp) {
      _lastGlobalPeriodReset = block.timestamp;
      _globalAmountWithdrawnThisPeriod = amount;
    } else {
      _globalAmountWithdrawnThisPeriod += amount;
    }

    require(
      _globalAmountWithdrawnThisPeriod <= _globalWithdrawLimitPerPeriod,
      "Global withdraw limit exceeded"
    );
  }

  function fakeReset() external {
    _lastGlobalPeriodReset = block.timestamp;
    _globalAmountWithdrawnThisPeriod = 0;
  }

  function fakeAdvanceTime(uint256 amount) external {
    _lastGlobalPeriodReset -= amount;
  }
}