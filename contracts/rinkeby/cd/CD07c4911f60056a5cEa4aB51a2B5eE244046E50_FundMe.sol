// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./PriceConvertor.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error notOwnerError();

contract FundMe {
    using PriceConvertor for uint256;

    uint256 public constant MIN_USD = 1 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToFunds;
    address public immutable owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier isOwner() {
        // require(msg.sender == owner, "only owner can call this function");
        if (msg.sender != owner) {
            revert notOwnerError();
        }
        _;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) > MIN_USD,
            "minimum of 10USD needed"
        );
        funders.push(msg.sender);
        addressToFunds[msg.sender] += msg.value;
    }

    function withdraw() public isOwner {
        address[] memory memoryFounders = funders;

        for (uint i = 0; i < memoryFounders.length; i++) {
            address founderAddress = memoryFounders[i];
            addressToFunds[founderAddress] = 0;
        }
        funders = new address[](0);
        //  to transfer - 3 methods - send,transfer, call
        // payable(msg.sender).transfer(address(this).balance);

        // payable(msg.sender).send(address(this).balance);

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "withdraw failed");
    }

    function getFundsFromAdrress(address funder) public view returns (uint256) {
        return addressToFunds[funder];
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 priceInUSD = (ethPrice * ethAmount) / 1e18;
        return priceInUSD;
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