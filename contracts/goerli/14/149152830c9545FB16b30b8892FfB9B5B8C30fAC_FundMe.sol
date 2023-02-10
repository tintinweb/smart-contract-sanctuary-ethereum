// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// this error code will help the contract revert in a structural way (v8 only)
// error FundMe__NotOwner();
// in modifier: if (msg.sender == owner) revert FundMe__NotOwner();

/* WE CAN USE console.log in sol by:
    - import "hardhat/console.sol"
    - call: console.log()
*/
contract FundMe {
    using PriceConverter for uint256;

    address public owner;
    uint256 public minimumFundingAmount;
    AggregatorV3Interface public priceFeed;
    address[] public funders;
    mapping(address => uint256) public addressToFundedAmount;

    modifier minimumFundingAmountMod() {
        require(
            // contract will only receive WEI, so convert it to ETH
            msg.value.toUSDAmount(priceFeed) >= minimumFundingAmount * 10 ** 18,
            "You need at least 50 USD"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "FundMe__NotOwner");
        _;
    }

    constructor(address priceFeedAddress) public {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        owner = msg.sender;

        // 50 USD
        minimumFundingAmount = 50;
    }

    function fund() public payable minimumFundingAmountMod {
        funders.push(msg.sender);
        addressToFundedAmount[msg.sender] = msg.value;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 i = 0; i < uint256(funders.length); i++) {
            delete addressToFundedAmount[funders[i]];
        }

        funders = new address[](0);
    }

    function cheaperWithdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        address[] memory cheapFunders = funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = cheapFunders[funderIndex];
            addressToFundedAmount[funder] = 0;
        }
        funders = new address[](0);
    }

    function getCurrentPrice() public view returns (int256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return answer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        // the result is the actual USD value with 10^8 decimal
        // the chainlink must return decimal without ','
        // because solidity doesn't use decimal number
        return uint256(answer);
    }

    function toUSDAmount(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return (ethAmount * getPrice(priceFeed)) / 10 ** 8;
    }
}