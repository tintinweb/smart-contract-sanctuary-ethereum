/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



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

// File: FundMe.sol

contract FundMe {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    address[] public funders;
    mapping(address => uint256) public addressToAmountFundded;

    function fund() public payable {
        uint256 minimumUsd = 50 * 10**18;
        require(
            getConvertionRate(msg.value) >= minimumUsd,
            "You need to spend more ETH"
        );
        addressToAmountFundded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getversion() public view returns (uint256) {
        return
            AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)
                .version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ).latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConvertionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFundded[funder] = 0;
        }
        funders = new address[](0);
    }
}