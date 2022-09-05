// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./IFeeModel.sol";
import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";

contract KinkFeeModel is IFeeModel {
  using SafeTransferLib for address;
  using FixedPointMathLib for uint256;

  uint256 public multiplierRate;
  uint256 public baseRate;
  uint256 public jumpRate;
  uint256 public kink;

  event NewInterestParams(uint256 baseRate, uint256 multiplierRate, uint256 jumpRate, uint256 kink);

  constructor(
    uint256 _baseRate,
    uint256 _multiplierRate,
    uint256 _jumpRate,
    uint256 _kink
  ) {
    _updateJumpRateModelInternal(_baseRate, _multiplierRate, _jumpRate, _kink);
  }

  function _updateJumpRateModelInternal(
    uint256 _baseRate,
    uint256 _multiplierRate,
    uint256 _jumpRate,
    uint256 _kink
  ) private {
    baseRate = _baseRate;
    multiplierRate = _multiplierRate.divWadDown(_kink);
    jumpRate = _jumpRate;
    kink = _kink;

    emit NewInterestParams(baseRate, multiplierRate, jumpRate, kink);
  }

  function _utilizationRate(
    uint256 _startBlock,
    uint256 _currentBlock,
    uint256 _endBlock
  ) private pure returns (uint256) {
    if (_startBlock == 0 || _currentBlock < _startBlock || _currentBlock > _endBlock) {
      return 0;
    }

    uint256 passedBlock = _currentBlock - _startBlock;

    return passedBlock.divWadDown(_endBlock - _startBlock);
  }

  function getFeeRate(
    uint256 _startBlock,
    uint256 _currentBlock,
    uint256 _endBlock
  ) external view returns (uint256) {
    uint256 ur = _utilizationRate(_startBlock, _currentBlock, _endBlock);

    if (ur < kink) {
      return ur.mulWadDown(multiplierRate) + baseRate;
    }

    uint256 normalRate = kink.mulWadDown(multiplierRate) + baseRate;
    uint256 excessUtil = ur - kink;

    return excessUtil.mulWadDown(jumpRate) + normalRate;
  }
}