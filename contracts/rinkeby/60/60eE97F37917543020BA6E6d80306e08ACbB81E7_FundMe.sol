// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

contract FundMe {
    address[] public funders;
    mapping(address=>uint256) public addressToAmount;
    mapping(address=>uint256) public addressToAmountAllTime;
    address payable public owner;
    uint256 minAmount = 50;
    AggregatorV3Interface public priceFeed;

    constructor(address _feedAddress) payable public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_feedAddress);
    }

    function getPrice() public view returns(uint256){
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price * 10**18 - priceFeed.decimals());
    }

    function convert(uint256 _ethAmount) public view returns(uint256){
        return _ethAmount*(10**18)/(getPrice());
    }

    function fund() public payable {
        require(convert(msg.value) >= minAmount, 'Insufficient amount to fund this contract!');
        funders.push(msg.sender);
        addressToAmount[msg.sender] = msg.value;
        addressToAmountAllTime[msg.sender] += msg.value;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public {
        require(address(this).balance > 0);
        msg.sender.call{value:address(this).balance}('');

        for (uint256 index=0; index < funders.length; index++){
            address funder = funders[index];
            addressToAmount[funder] = 0;
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