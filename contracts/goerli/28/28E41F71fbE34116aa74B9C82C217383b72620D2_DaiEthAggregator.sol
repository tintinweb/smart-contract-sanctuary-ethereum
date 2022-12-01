// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
import "../../interfaces/IChainlinkAggregator.sol";

contract DaiEthAggregator {
  IChainlinkAggregator public immutable DaiUsdOracle;
  IChainlinkAggregator public immutable EthUsdOracle;

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);

  constructor(address _daiUsdOracle, address _ethUsdOracle) public {
    DaiUsdOracle = IChainlinkAggregator(_daiUsdOracle);
    EthUsdOracle = IChainlinkAggregator(_ethUsdOracle);
  }

  function latestAnswer() external view returns (int256) {
    int256 daiPriceInUsd = DaiUsdOracle.latestAnswer();
    int256 ethPrice = EthUsdOracle.latestAnswer();
    int256 usdPrice = ethPrice != 0 ? (10**26) / ethPrice : 0;
    int256 daiPrice = daiPriceInUsd * usdPrice / (10**8);
    return daiPrice;
  }

  function getTokenType() external pure returns (uint256) {
    return 1;
  }

  // function getSubTokens() external view returns (address[] memory) {
  // TODO: implement mock for when multiple subtokens. Maybe we need to create diff mock contract
  // to call it from the migration for this case??
  // }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IChainlinkAggregator {
  function decimals() external view returns (uint8);
  
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}