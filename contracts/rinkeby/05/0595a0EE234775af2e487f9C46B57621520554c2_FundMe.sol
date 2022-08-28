// spdx-license-identifier:mit;

pragma solidity ^0.8.0;

import './PriceConverter.sol';


contract FundMe{
    using PriceConverter for uint;
    uint public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address =>uint) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner=msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable{
        require(msg.value.conversionRate(priceFeed) >= MINIMUM_USD, 'did not have enough ether');
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender]=(msg.value);
    }
    function withdraw() payable onlyOwner public {
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner{
        require(msg.sender==i_owner, 'sender is not owner');
        _;
    }

    receive() external payable{
        fund();
    }

    fallback() external payable{
        fund();
    }
}

// spdx-license-identifier:mit;

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library PriceConverter{
    function getPrice(AggregatorV3Interface priceFeed)internal view returns(uint){
//        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int price,,,)=priceFeed.latestRoundData();
        return uint(price * 1e10);
    }

    function conversionRate(uint ethAmount, AggregatorV3Interface priceFeed)internal view returns(uint){
        uint ethPrice = getPrice(priceFeed);
        uint ethAmountInUsd = (ethPrice*ethAmount) / 1e10;
        return ethAmountInUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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