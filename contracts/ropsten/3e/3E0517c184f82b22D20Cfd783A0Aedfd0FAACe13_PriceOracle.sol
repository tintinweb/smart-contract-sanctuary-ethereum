// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IPriceOracle} from './interfaces/IPriceOracle.sol';

contract PriceOracle is IPriceOracle {
  uint256 internal irdtPriceUsd;

  event IrdtPriceUpdated(uint256 price, uint256 timestamp);

  function getIrdtUsdPrice() external view returns (uint256) {
    return irdtPriceUsd;
  }

  function setIrdtUsdPrice(uint256 price) external {
    irdtPriceUsd = price;
    emit IrdtPriceUpdated(price, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title IPriceOracle
 * @author author
 * @notice Defines the basic interface for a Price oracle.
 **/
interface IPriceOracle {
  /**
   * @notice Returns the IRDT price in the base currency of USD
   * @return The price of the IRDT
   **/
  function getIrdtUsdPrice() external view returns (uint256);

  /**
   * @notice Set the price of the IRDT in the base currency of USD
   * @param price The price of the IRDT
   **/
  function setIrdtUsdPrice(uint256 price) external;
}