// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    address public owner;
    address [] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minUSD = 50 * (10 ** 18);
        require(getConversionRate(msg.value) >= minUSD, "spend more ETH");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns(uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price * (10 ** 10)); // wei
    }


    function getConversionRate(uint256 ETH_amount) public view returns(uint256) {
        uint256 ETH_price = getPrice();
        uint256 ETHinUSD = (ETH_amount * ETH_price) / (10 ** 18);
        // 1 * 2800 * 10^8 / 10^18
        return ETHinUSD;
    }

    function getEntranceFee() public view returns(uint256) {
        uint256 minimumUSD = 50 * 10 ** 18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return ((minimumUSD * precision) / price) + 1;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public{
        payable(msg.sender).transfer(address(this).balance);
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
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