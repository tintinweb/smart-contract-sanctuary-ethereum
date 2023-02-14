// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    mapping(address => uint256) public ammountFunded;
    mapping(address => uint256) public ammountinPot;
    address[] public funders;
    address[] public currentFunders;
    AggregatorV3Interface internal priceFeed =
        AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    uint256 public msgValue;

    function fund() public payable {
        //min $50
        uint256 minUSD = 50 * 10**18;
        require((msg.value) * (getLatestPrice()) >= minUSD, "Need more eth");
        ammountFunded[msg.sender] += msg.value;
        ammountinPot[msg.sender] += msg.value;
        funders.push(msg.sender);
        currentFunders.push(msg.sender);
        msgValue = msg.value;
    }

    function getVersion() public view returns (uint256) {
        //Aggregator version
        return priceFeed.version();
    }

    function getLatestPrice() public view returns (uint256) {
        //USD price
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price / 10**8);
    }

    function withdraw() public payable onlyOwner {
        //withdraw funds
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 x = 0; x < funders.length; x++) {
            ammountinPot[funders[x]] = 0;
        }
        funders = new address[](0);
    }
}

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