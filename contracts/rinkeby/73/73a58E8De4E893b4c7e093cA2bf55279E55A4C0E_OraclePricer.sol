//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/chainlink/AggregatorV3Interface.sol";

contract OraclePricer {

  /// @notice Mapping from Moonwell mToken to its underlying token
  /// mToken => IERC20
  mapping(address => address) public mTokens;
  
  constructor() {
    
  }

  function price(address underlying) external view returns(uint, uint8) {
    return _price(underlying);
  }

  function _price(address underlying) internal view returns(uint, uint8) {

    AggregatorV3Interface feed = AggregatorV3Interface(underlying);

    (uint roundId, int256 answer, , ,) = feed.latestRoundData();

    uint8 decimals = feed.decimals();
    
    return (uint(answer), decimals);
    
    /* if(roundId == 0){ */
    /*   return (0, 0); */
    /* }else{ */
    /*   uint8 decimals = feed.decimals(); */
    /*   return (uint(answer), decimals); */
    /* } */
    
    
  }
  
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface AggregatorV3Interface {
    /**
     * Returns the decimals to offset on the getLatestPrice call
     */
    function decimals() external view returns (uint8);

    /**
     * Returns the description of the underlying price feed aggregator
     */
    function description() external view returns (string memory);

    /**
     * Returns the version number representing the type of aggregator the proxy points to
     */
    function version() external view returns (uint256);

    /**
     * Returns price data about a specific round
     */
    function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    /**
     * Returns price data from the latest round
     */
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}