// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IFujiOracle} from "../interfaces/IFujiOracle.sol";

contract MockOracle is IFujiOracle {
  mapping(address => uint256) public prices;

  function getPriceOf(
    address currencyAsset,
    address commodityAsset,
    uint8 decimals
  )
    external
    view
    returns (uint256 price)
  {
    price = 10 ** uint256(decimals);

    if (commodityAsset != address(0)) {
      price = price * prices[commodityAsset];
    } else {
      price = price * (10 ** 8);
    }

    if (currencyAsset != address(0)) {
      price = price / prices[currencyAsset];
    } else {
      price = price / (10 ** 8);
    }
  }

  function setUSDPriceOf(address asset, uint256 price) public {
    prices[asset] = price;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IFujiOracle {
  // FujiOracle Events

  /**
   * @dev Log a change in price feed address for asset address
   */
  event AssetPriceFeedChanged(address asset, address newPriceFeedAddress);

  function getPriceOf(
    address _collateralAsset,
    address _borrowAsset,
    uint8 _decimals
  )
    external
    view
    returns (uint256);
}