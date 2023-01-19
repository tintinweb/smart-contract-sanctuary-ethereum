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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotEnoughFunds();
error CallFailed();
error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public /*immutable8*/ owner;

    AggregatorV3Interface public priceFeed;

    function fund() public payable {
        // 1e18 Wei = 1 ETH = minimum amount to send
        // require(msg.value.getConversionRate() >= MINIMUM_USD, "Didn't send enough!");
        if (msg.value.getConversionRate(priceFeed) < MINIMUM_USD) {
            revert NotEnoughFunds();
        }

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset array
        funders = new address[](0);

        /**
         *   Different ways to withdraw
         */
        // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        // require(callSuccess, "Call Failed");
        if (!callSuccess) {
            revert CallFailed();
        }
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not Owner!");
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _; // placeholder for code to be executed for this modifier
    }

    // low-level functions if fund() is not called directly
    // e.g. going directly to metamask and sending funds to the contract address
    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (
            ,
            /*uint80 roundID*/ int256 price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountinUsd = (ethPrice * ethAmount) / 1e18;

        return ethAmountinUsd;
    }
}