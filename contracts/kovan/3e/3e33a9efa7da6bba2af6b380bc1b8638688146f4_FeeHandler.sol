// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "./IFeeHandler.sol";
contract FeeHandler is IFeeHandler {
    /*
        Marketplace tax,
        Hunting tax,
        Damage for legions,
        Summon fee,
        14 Days Hunting Supplies Discounted Fee,
        28 Days Hunting Supplies Discounted Fee
    */
    uint[6] fees = [1500,250,100,20,12,16];
    address legion;
    AggregatorV3Interface public priceFeed;
    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }
    constructor() {
        legion = msg.sender;
        priceFeed = AggregatorV3Interface(0x2ca5A90D34cA333661083F89D831f757A9A50148);
    }
    function getFee(uint8 _index) external view override returns (uint) {
        return fees[_index];
    }
    function setFee(uint _fee, uint8 _index) external override onlyLegion {
        require(_index>=0 && _index<6, "Unknown fee type");
        fees[_index] = _fee;
    }
    function getLatestPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IFeeHandler {
    function getFee(uint8 _index) external view returns(uint);
    function setFee(uint _fee, uint8 _index) external;
}