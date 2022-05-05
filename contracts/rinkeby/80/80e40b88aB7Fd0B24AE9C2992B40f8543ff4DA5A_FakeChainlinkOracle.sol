pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

contract FakeChainlinkOracle {
  constructor() {}

  uint8 public constant decimals = 8;

  string public constant description = "ETH / USD";

  function latestRoundData() public pure returns(
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  ) {
    return (
      92233720368547777283,
      294240000000,
      1644641759,
      1644641759,
      92233720368547777283
    );
  }
}