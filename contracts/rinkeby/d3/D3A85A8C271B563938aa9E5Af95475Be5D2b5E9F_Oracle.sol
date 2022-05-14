// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
contract Oracle {
    AggregatorV3Interface internal priceFeed;
    bool isOracle;

    uint256 private _networkId;


    constructor(uint256 networkId) public {
        _networkId = networkId;
        isOracle = false;
        if (_networkId == 1) {
            priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH mainnet
            isOracle = true;
        }
        if (_networkId == 42) {
            priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);// ETH kovan
            isOracle = true;
        }
        if (_networkId == 56) {
            priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);// BCS mainnet
            isOracle = true;
        }
        if (_networkId == 97) {
            priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);// BCS testnet
            isOracle = true;
        }
        if (_networkId == 80001) {
            priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);// Matic testnet
            isOracle = true;
        }
        if (_networkId == 137) {
            priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);// Matic mainnet
            isOracle = true;
        }
        if (_networkId == 1313161554) {
            priceFeed = AggregatorV3Interface(0x842AF8074Fa41583E3720821cF1435049cf93565);// Aurora mainnet
            isOracle = true;
        }
        if (_networkId == 1313161555) {
            priceFeed = AggregatorV3Interface(0x8BAac7F07c86895cd017C8a2c7d3C72cF9f1051F);// Aurora testnet
            isOracle = true;
        }
        if (_networkId == 43114) {
            priceFeed = AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156);// AVAX mainnet
            isOracle = true;
        }
        if (_networkId == 43113) {
            priceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);// AVAX testnet
            isOracle = true;
        }

    }

    function getIsOracle() public view returns (bool) {
        return isOracle;
    }

    function getLatestPrice() public view returns (uint256, uint8) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return (uint256(price), decimals);
    }


    function getCustomPrice(address aggregator) public view returns (uint256, uint8) {
        AggregatorV3Interface priceToken = AggregatorV3Interface(aggregator);
        (,int price,,,) = priceToken.latestRoundData();
        uint8 decimals = priceToken.decimals();
        return (uint256(price), decimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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