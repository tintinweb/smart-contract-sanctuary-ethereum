// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPriceFeed {
  function latestAnswer() external view returns (int256);
}

/**
 * @title Converts the price of the feed ENS-USD to an ENS-ETH, Chainlink format
 **/
contract EnsUsdToEnsEth is IPriceFeed {
  IPriceFeed public constant ENS_USD = IPriceFeed(0x5C00128d4d1c2F4f652C267d7bcdD7aC99C16E16);
  IPriceFeed public constant ETH_USD = IPriceFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

  constructor() public {}

  function latestAnswer() external view override returns (int256) {
    return (ENS_USD.latestAnswer() * 1 ether) / ETH_USD.latestAnswer();
  }
}