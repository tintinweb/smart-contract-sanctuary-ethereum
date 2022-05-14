// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IPriceOracle} from './IPriceOracle.sol';

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