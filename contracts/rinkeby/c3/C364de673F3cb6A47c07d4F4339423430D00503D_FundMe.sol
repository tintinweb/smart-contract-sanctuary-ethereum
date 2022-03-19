/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



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
    mapping(address => uint256) public addressToAmountFounded;
    address[] public funders;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getSender() public view returns (address) {
        return msg.sender;
    }

    function fund() public payable {
        uint256 minUsd = 50 * (10**18);
        require(
            _getConversionRate(msg.value) >= minUsd,
            "You need to spend more ETH (more than 50 USD)"
        );
        addressToAmountFounded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function _getPrice() private view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10**10);
    }

    function _getConversionRate(uint256 ethAmount)
        private
        view
        returns (uint256)
    {
        uint256 ethPrice = _getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 10**10;
        return ethAmountInUsd;
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        return _getConversionRate(ethAmount) / 10**18;
    }

    function getPrice() public view returns (uint256) {
        return _getPrice() / 10**18;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFounded[funder] = 0;
        }
        funders = new address[](0); //new blank array
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}