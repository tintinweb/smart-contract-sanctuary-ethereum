// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConvertor.sol";

error FundMe__InsufficentFunds();
error FundMe__CallFailed();
error FundMe__OnlyOwner();

contract FundMe {
    using PriceConvertor for uint256;

    address[] private s_funders;
    mapping(address => uint256) public getAmountByAddress;
    AggregatorV3Interface private priceFeed;

    uint256 private constant MIN_USD = 10 * 1e18;
    address immutable iOwner;

    constructor(address priceFeedAddress) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        iOwner = msg.sender;
    }

    modifier OnlyOwner {
        if(msg.sender != iOwner) revert FundMe__OnlyOwner();
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        if(msg.value.getConverionRate(priceFeed) < MIN_USD) revert FundMe__InsufficentFunds();
        s_funders.push(msg.sender);
        getAmountByAddress[msg.sender] += msg.value;
    }

    function withdraw() public payable OnlyOwner {
        address[] memory funders = s_funders;
        for(uint i = 0; i < funders.length; i++){
            getAmountByAddress[funders[i]] = 0;
        }
        s_funders = new address[](0);
        uint256 amount = address(this).balance;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success) revert FundMe__CallFailed();
    }

    function getFunder(uint256 index) public view returns(address) {
        return s_funders[index];
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getEthPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 price, , ,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConverionRate(uint256 _amount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getEthPrice(priceFeed);
        uint256 ethAmount = (ethPrice * _amount) / 1e18;
        return ethAmount;
    }
}