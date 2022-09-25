// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error notOwner();

contract Fundme {
    using PriceConverter for uint256;
    uint256 constant MINIMUM = 50; // ammount in usd

    address[] public funder;
    mapping(address => uint256) public addressToAmount;
    address public immutable owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAdress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAdress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM,
            "You need to Send more eth!"
        );
        addressToAmount[msg.sender] += msg.value;
        funder.push(msg.sender);
    }

    modifier owner_only() {
        if (owner != msg.sender) {
            revert notOwner();
        }
        _;
    }

    function withdraw() public owner_only {
        for (
            uint256 funderIndex = 0;
            funderIndex < funder.length;
            funderIndex++
        ) {
            address funders = funder[funderIndex];
            addressToAmount[funders] = 0;
        }

        funder = new address[](0);

        //transfer
        //send
        //call

        // transfer
        // payable(msg.sender) payable address
        // payable(msg.sender).transfer(address(this).balance);

        // send
        // bool sent = payable(msg.sender).send(address(this).balance);
        // require(sent, "sending failed");

        // call
        // recomended
        (bool callWithdraw, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callWithdraw, "Withdraw failed");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     address(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e)
        // );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
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