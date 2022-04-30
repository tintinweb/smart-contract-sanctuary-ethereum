//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DashMeMoney {
    address public receiver;
    uint256 private miniumumDepositUSD = 50;
    AggregatorV3Interface internal priceFeed;
    mapping(address => uint256) private addressAmountMap;
    address public owner;
    address[] private funders;

    constructor() {
        owner = msg.sender;
    }

    function sendMoney() public payable returns (bool) {
        require(
            (msg.value / (10**18)) * (getETH2USD() / 10**8) >=
                miniumumDepositUSD,
            "Omo shey you dey craze,"
        );
        addToMap();
        return true;
    }

    function getETH2USD() public returns (uint256) {
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Lol, nice try");
        _;
    }

    function withdrawfunds() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        resetMap();
    }

    function addToMap() private {
        addressAmountMap[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function resetMap() private {
        for (uint256 index = 0; index < funders.length; index++) {
            addressAmountMap[funders[index]] = 0;
        }
        funders = new address[](0);
    }

    function totalDonors() public view returns (uint256) {
        return funders.length;
    }

    function amountDonated(address donorAddress) public view returns (uint256) {
        return addressAmountMap[donorAddress];
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