//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    address public owner;
    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    mapping(address => uint256) public addressToAmountFunded;

    function fundme() public payable {
        uint256 minUsd = 10 * 10**18;
        require(getCovertedValue(msg.value) >= minUsd, "Not enough ether!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getCovertedValue(uint256 _payableAmount)
        public
        view
        returns (uint256)
    {
        uint256 price = getPrice();
        uint256 getAmountUSD = (price * _payableAmount) / 10000000;
        return getAmountUSD;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only Megaboss can withdraw");
        _;
    }

    function withdrawUSD() public payable onlyOwner {
        //require(owner == msg.sender, "Only Megaboss can withdraw");
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 FunderIndex = 0;
            FunderIndex < funders.length;
            FunderIndex++
        ) {
            address funder = funders[FunderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
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