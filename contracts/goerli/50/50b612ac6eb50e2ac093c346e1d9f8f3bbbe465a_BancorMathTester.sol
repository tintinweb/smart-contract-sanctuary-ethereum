/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

pragma solidity ^0.6.6;

contract BancorMathTester {
  uint256 constant PPM_RESOLUTION = 1000000;

  function _crossReserveTargetAmount(
    uint256 sourceReserveBalance,
    uint256 targetReserveBalance,
    uint256 sourceAmount
  ) private pure returns (uint256) {
    return (targetReserveBalance * sourceAmount) / (sourceReserveBalance + sourceAmount);
  }

  function _calculateFee(uint256 targetAmount, uint256 conversionFee) private pure returns (uint256) {
    return (targetAmount * conversionFee) / PPM_RESOLUTION;
  }

  function swapOutput(
      uint256 sourceBalance,
      uint256 targetBalance,
      uint256 sourceAmount,
      uint256 conversionFee

  ) public pure returns (uint256, uint256) {
      uint256 targetAmount = _crossReserveTargetAmount(sourceBalance, targetBalance, sourceAmount);

      uint256 fee = _calculateFee(targetAmount, conversionFee);

      return (targetAmount - fee, fee);
  }
}