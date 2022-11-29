/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);
}

contract MockAggregator {
  IChainlinkAggregator public immutable EthUsdOracle;

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);

  constructor(address _ethUsdOracle) {
    EthUsdOracle = IChainlinkAggregator(_ethUsdOracle);
  }

  function latestAnswer() external view returns (int256) {
    int256 ethPrice = EthUsdOracle.latestAnswer();
    int256 usdPrice = ethPrice != 0 ? (10**26) / ethPrice : int256(0);
    return usdPrice;
  }

  function getTokenType() external pure returns (uint256) {
    return 1;
  }

  // function getSubTokens() external view returns (address[] memory) {
  // TODO: implement mock for when multiple subtokens. Maybe we need to create diff mock contract
  // to call it from the migration for this case??
  // }
}