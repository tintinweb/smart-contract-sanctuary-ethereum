/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IPriceFeed {
  function latestAnswer() external view returns (int256);
}

/**
 * @title Converts the price of the feed alUSD-USD to an alUSD-ETH, Chainlink format
 **/
contract AlusdUsdToAlusdEth is IPriceFeed {
  IPriceFeed public constant ALUSD_USD = IPriceFeed(0xC3a8033Dc5f2FFc8AD9bE10f39063886055E22B7);
  IPriceFeed public constant ETH_USD = IPriceFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

  function latestAnswer() external view override returns (int256) {
    return (ALUSD_USD.latestAnswer() * 1 ether) / ETH_USD.latestAnswer();
  }
}