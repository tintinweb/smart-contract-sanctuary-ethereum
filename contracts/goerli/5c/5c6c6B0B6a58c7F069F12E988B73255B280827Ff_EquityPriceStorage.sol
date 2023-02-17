// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract EquityPriceStorage {
    Equity[] public underlyings;
    mapping(string => uint256) public nameToPrice;

    AggregatorV3Interface private s_priceFeed;
    address public constant myAddress =
        0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;

    struct Equity {
        string name;
        uint256 price;
    }

    constructor() {
        s_priceFeed = AggregatorV3Interface(myAddress);
    }

    //view, pure
    function getPrice(string memory _name) public view returns (uint256) {
        return nameToPrice[_name];
    }

    function addEquity(string memory _name, uint256 _price) public {
        underlyings.push(Equity(_name, _price));
        nameToPrice[_name] = _price;
    }

    function getChainLinkPrice() public view returns (uint256) {
        (, int256 answer, , , ) = s_priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer);
    }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138