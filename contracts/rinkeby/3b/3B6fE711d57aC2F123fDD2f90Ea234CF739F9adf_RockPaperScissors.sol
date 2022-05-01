/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: RockPaperScissors.sol

contract RockPaperScissors {
    //using SafeMathChainLink for uint256;

    AggregatorV3Interface public priceFeed;
    mapping(address => uint256) AddressToAmountFunded;
    mapping(address => uint256) AddressToMoveMade;
    address public owner;

    // 1. ROCK
    // 2. PAPER
    // 3. SCISSORS

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function ready(uint256 _move) public payable {
        require(msg.value >= getEntranceFee(), "No sea tacano");
        require(_move <= 3 && _move >= 1);
        AddressToAmountFunded[msg.sender] += msg.value;
        AddressToMoveMade[msg.sender] = _move;
        //players.push(msg.sender);
    }

    function getConvertionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 price = getPrice();
        uint256 ethUSD = (price * ethAmount) / 1000000000000000000;
        return ethUSD;
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); //Answer es (answer + 8 decimales) * 10**10 para que quede expresado en Wei
    }

    function getEntranceFee() public view returns (uint256) {
        //minimum usd
        uint256 minUSD = 5000000000000000000;
        uint256 price = getPrice(); // 2700 00000000 00000000000
        uint256 precision = 1000000000000000000;
        return ((minUSD * precision) / price) + 1; // La respuesta estÃ¡ en Wei
    }
}