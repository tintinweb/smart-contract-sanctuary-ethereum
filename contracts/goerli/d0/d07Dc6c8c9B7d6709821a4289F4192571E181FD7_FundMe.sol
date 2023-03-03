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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;
    address public immutable i_owner;

    AggregatorV3Interface public s_priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Minimum value not met!!"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public payable onlyOwner {
        for (
            uint256 s_fundersIndex = 0;
            s_fundersIndex < s_funders.length;
            s_fundersIndex++
        ) {
            address funder = s_funders[s_fundersIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed!");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    function cheapWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            ++funderIndex
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Call Failed!!");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    /* function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    } */

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}