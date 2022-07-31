// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public whoSentWhat;
    address public owner;
    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOnwer() {
        require(owner == msg.sender);
        _;
    }

    function pay() public payable {
        uint256 minimumusdrate = 50 * 10**18;
        require(
            convert(msg.value) >= minimumusdrate,
            "You need to spend more eth"
        );
        whoSentWhat[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ).latestRoundData();
        return uint256(answer * 10000000000);
    }

    function convert(uint256 ethAmount) public view returns (uint256) {
        uint256 ethprice = getPrice() / 1000000000000000000;
        uint256 ethAmountInUsd = (ethprice * ethAmount);
        return ethAmountInUsd;
    }

    function withdraw() public payable onlyOnwer {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            whoSentWhat[funder] = 0;
        }
        funders = new address[](0);
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