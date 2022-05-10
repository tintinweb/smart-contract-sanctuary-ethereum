/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
    AggregatorV3Interface internal priceFeed;
    mapping(address => uint256) public addressToAmount;
    address[] public funders;
    address public owner;

    constructor() {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    function weiToUsd(uint256 weiAmount) public view returns(uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        return (uint256(price * (10 ** 10)) * weiAmount) / 10 ** 18;
    }

    function fund() public payable {
        uint256 limit = 10 * 10 ** 18;
        require(weiToUsd(msg.value) >= limit, "Transfer atleast ETH worth 10$");
        addressToAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public onlyOwner payable {
        payable(msg.sender).transfer(address(this).balance);
        for(uint256 i = 0; i < funders.length; ++i) {
            address funder = funders[i];
            addressToAmount[funder] = 0;
        }
        funders = new address[](0);
    }
}