// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PriceConverter.sol";

contract FundMe {
    // using PriceConverter for msg.value
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 50 * 1e18;
    address private immutable owner;
    address[] public funders;
    mapping(address => uint256) public addressToAmtFunded;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Not enough Funds"
        );
        funders.push(msg.sender);
        addressToAmtFunded[msg.sender] = msg.value;
    }

    function withdraw() public isOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmtFunded[funder] = 0;
        }
        funders = new address[](0);

        // Withdraw funds
        // msg.sender => address
        // payable(msg.sender) => payable address

        // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    modifier isOwner() {
        require(owner == msg.sender, "Not Owner");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmt, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmtInUSD = (ethPrice * ethAmt) / 1e18;
        return ethAmtInUSD;
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