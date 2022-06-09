// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import './PriceConvertor.sol';

contract FundMe {
    using PriceConvertor for uint256;

    address[] public funders;
    mapping(address => uint256) public getAmountByAddress;

    uint256 constant MIN_USD = 10 * 1e18;
    address public immutable iOwner;

    constructor() {
        iOwner =  msg.sender;
    }

    modifier OnlyOwner {
        require(msg.sender == iOwner, "Only owner can withdraw");
        _;
    }

    function fund() public payable {
        require(msg.value.getConversioRate() >= MIN_USD, "Insufficient amount");
        funders.push(msg.sender);
        getAmountByAddress[msg.sender] += msg.value;
    }

    function withdraw() public OnlyOwner {
        for(uint256 i; i < funders.length; i++){
            getAmountByAddress[funders[i]] = 0;
        }

        funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getETHPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (, int256 price, , ,) = priceFeed.latestRoundData();
        return uint256(price) * 1e10;
    }

    function getConversioRate(uint256 _ammount) internal view returns (uint256){
        uint256 ethPrice = getETHPrice();
        uint256 ethAmountInUsd = (ethPrice * _ammount) / 1e18;
        return ethAmountInUsd;
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