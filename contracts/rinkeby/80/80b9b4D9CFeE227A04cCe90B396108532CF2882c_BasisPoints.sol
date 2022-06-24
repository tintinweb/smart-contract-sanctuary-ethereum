// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title BasisPoints
/// @notice Provides a function for multiplying in basis points
library BasisPoints {

  uint128 public constant BASE = 10000;

  /**  @notice Calculate _input * _basisPoints / _base rounding down
    *  @dev from Mikhail Vladimirov's response here: https://ethereum.stackexchange.com/questions/55701/how-to-do-solidity-percentage-calculation/55702
    */
  function mulByBp(uint256 _input, uint256 _basisPoints) public pure returns (uint256) {
    uint256 a = _input / BASE;
    uint256 b = _input % BASE;
    uint256 c = _basisPoints / BASE;
    uint256 d = _basisPoints % BASE;

    return a * c * BASE + a * d + b * c + b * d / BASE;
  }

}