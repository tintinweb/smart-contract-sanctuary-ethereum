// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPriceFeed {
  function latestAnswer() external view returns (int256);
}

contract OracleAdapterWBTC is IPriceFeed {
  IPriceFeed public constant WBTC_BTC = IPriceFeed(0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23); // 8 decimals
  IPriceFeed public constant BTC_ETH = IPriceFeed(0xdeb288F737066589598e9214E782fa5A8eD689e8); // 18 decimals

  /**
   * @notice Returns the price of WBTC, based on WBTC/BTC and BTC/ETH CL price feeds
   * @return The price of a unit of WBTC (expressed with 18 decimals)
   */
  function latestAnswer() external view returns (int256) {
    return (WBTC_BTC.latestAnswer() * BTC_ETH.latestAnswer()) / 10**8;
  }
}