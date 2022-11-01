// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Uncomment this line to use console.log

import "AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable owner;
    address[] public funders;
    uint256 public constant MIN_USD = 50 * 1e18;
    AggregatorV3Interface internal priceFeed;

    constructor(address priceFeedAddress) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        owner = msg.sender;
    }

    function fund() public payable {
        require(
            eth2usd(msg.value) >= MIN_USD,
            "your value is lower than minimum entrance fee"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function eth2usd(uint256 eth) public view returns (uint256) {
        return uint256((eth * getLatestPrice()) / 1e18);
    }

    function getLatestPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 ethPrice = getLatestPrice();
        return uint256((MIN_USD * 1e18) / ethPrice);
    }

    modifier onlyOwner() {
        // require(msg.sender == owner, "you are not access to this action.");
        if (msg.sender != owner) revert FundMe__NotOwner();
        _;
    }

    function withdraw() public payable onlyOwner {
        // payable(msg.sender).transfer(address(this).balance);
        address[] memory funders_list = funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders_list.length;
            funderIndex++
        ) {
            address funder = funders_list[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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