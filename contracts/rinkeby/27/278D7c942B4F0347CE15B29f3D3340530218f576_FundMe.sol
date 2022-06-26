// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

// Eth Gas price = 18 gwei
// Creation cost: 852846 gas / 15351228 gwei / $16.69
// Creation cost: 834167 gas / 15015006 gwei / $16.32 => after I added constant
// Creation cost: 810600 gas / 14590800 gwei / $15.86 => after made variable immutable
// Creation cost: 785482 gas / 14138676 gwei / $15.37 => after adding error NotOwner()

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public /* immutable */ owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // require(getConversionRate(msg.value) >= MINIMUM_USD, "Didn't send enough!");
        require(
            // Cool thing here is that msg.value is the first parameter of getConversionRate()
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function minimumInEth() public view returns (uint256) {
        return MINIMUM_USD.getConversionRate(priceFeed);
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
        // reset the array of funders:
        // initialise the variable with a new address array of 0 elements
        funders = new address[](0);

        // withdraw the funds in 3ways: transfer / send / call

        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed!");

        // call
        (bool callSuccess, ) = /* bytes memory dataReturned */
        payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed!");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
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

// https://www.npmjs.com/package/@chainlink/contracts
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        // ETH in terms of USD

        // need to match the decimals of msg.sender
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
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