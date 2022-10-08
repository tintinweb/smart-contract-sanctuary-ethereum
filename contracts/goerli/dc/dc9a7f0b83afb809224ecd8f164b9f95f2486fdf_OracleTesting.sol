/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/oracles.sol



pragma solidity 0.8.17;

// it's giving an error during verification maybe because it's on testnet?
// function callbacks from within remix working fine.


contract OracleTesting {
    AggregatorV3Interface internal priceOfETHinUSD;

    constructor() {
        // address for the goerli testnet.
        priceOfETHinUSD = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }

    function getLatestPrice() public view returns (int) {
        (
            // the commented out stuff we dont really care about but nevertheless it is returned ...
            // ... so we have to have something before the comma for the syntax.
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceOfETHinUSD.latestRoundData();
        return price;
    }
}