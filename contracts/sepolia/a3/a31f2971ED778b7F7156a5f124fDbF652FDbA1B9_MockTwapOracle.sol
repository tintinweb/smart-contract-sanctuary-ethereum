// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import { ITwapOracle } from "../price-oracle/interfaces/ITwapOracle.sol";

contract MockTwapOracle is ITwapOracle {
  uint256 public price;

  function setPrice(uint256 _price) external {
    price = _price;
  }

  function getTwap(uint256) external view override returns (uint256) {
    return price;
  }

  function getLatest() external view override returns (uint256) {
    return price;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ITwapOracle {
  /// @notice Return TWAP with 18 decimal places in the epoch ending at the specified timestamp.
  ///         Zero is returned if TWAP in the epoch is not available.
  /// @param timestamp End Timestamp in seconds of the epoch
  /// @return TWAP (18 decimal places) in the epoch, or zero if not available
  function getTwap(uint256 timestamp) external view returns (uint256);

  /// @notice Return the latest price with 18 decimal places.
  function getLatest() external view returns (uint256);
}