// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "AggregatorV3Interface.sol";

contract FundMe {
    AggregatorV3Interface internal priceFeed;

    address public Owner;

    mapping(address => uint256) PeopleMap;
    address[] PeopleArr;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function fund() public payable {
        uint256 amount = msg.value + PeopleMap[msg.sender];
        PeopleMap[msg.sender] = amount;
        PeopleArr.push(msg.sender);
    }

    function howMuchFunded() public view returns (int256) {
        // in wei
        uint256 amount = 0;

        for (uint8 i = 0; i < PeopleArr.length; i += 1) {
            amount += PeopleMap[PeopleArr[i]];
        }

        int256 price = getLatestPrice();
        // usd price
        int256 fundedAmount = int256(amount / 10**18) * price;

        return fundedAmount;
    }

    modifier isOwner() {
        require(msg.sender == Owner, "Only owner can do that");
        _;
    }

    function withdraw() public payable isOwner {
        // fulfill owner
        address contractAddress = address(this);
        payable(msg.sender).transfer(contractAddress.balance);

        // clean up
        for (uint8 i = 0; i < PeopleArr.length; i += 1) {
            PeopleMap[PeopleArr[i]] = 0;
        }

        PeopleArr = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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