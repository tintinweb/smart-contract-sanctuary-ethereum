// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

// constant, imutable.
// used to help optimize gas prices
// constants are capitilized
// immutable is flagged by "i_"

// use constants where the var is set on the same line it is declared
// use immutable where it is not

// 837,285
// 817,755
// 817,743
// 794,260

error NotOwner();

contract FundMe {
    // to use library you must import it at the top and declare it's use inside the contract
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
    // 23,515
    // 21,415

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;
    AggregatorV3Interface public immutable i_priceFeed;

    // 23,644
    // 21,508

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // set minimum fund amount
        // require(msg.value > 1e18, "Didn't send enough"); // 1e18 == 1 * 10 ** 18 == 1000000000000000000

        // require(getConvertionRate(msg.value) >= MINIMUM_USD, "Didn't send enough");

        require(
            msg.value.getConvertionRate(i_priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        );

        // add funders to address array
        funders.push(msg.sender);

        // record who sent what amount
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // reset funders amounts
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];

            addressToAmountFunded[funder] = 0;
        }

        // reset address array
        funders = new address[](0);

        // withdraw funds
        // there are three ways to send funds from a contract:

        // transfer - must also cast msg.sender from address typer to payable address type
        // if it fails it returns an error and reverts the tx
        // payable(msg.sender).transfer(address(this).balance);
        // will fail if gas exceeds 2300

        // send - send returns a bool, so will not revert if tx fails, so we must add a require
        // to catch failures and be able to revert the tx
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // will "fail" if gas exceeds 2300

        // call - lower level function and can call any function in solidity
        // returns two values: bool and bytes. If you don't require the data (bytes) you must
        // still include the comma
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
        // no cap on gas
    }

    modifier onlyOwner() {
        // when a modifier is added to a function it will execute it
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        // the underscore is what tells the function to continue with teh rest of the function code
        // beyond the modifier code - i.e. do what the modifier says first, then run the function
        _;
    }

    // what happens if someone sends this contract ETH without the send contract?

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // because we are not modifying anything we can make this a view.
    // as this returns a uint256, we need to specify that too.
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // price of eth in terms of USD
        // this function returns many values, we must leave the commas for those values we don't want
        // (uint80 roundId, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
        (, int256 price, , , ) = priceFeed.latestRoundData();

        // because ETH has 18 decimals, and the price above is returned with 8 decimals, we must do some maths.
        // Also, msg.sender and price are not the same type (uint vs int), so we can type cast to make them both the same.
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    function getConvertionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);

        // imagine eth is $2k, the math would look something like this:
        // 2000_000000000000000000 = ETH/USD price
        // 1_000000000000000000 = 1 ETH
        // the below cal takes those numbers and does the following maths:
        // 2000_000000000000000000 * 1_000000000000000000 / 1_000000000000000000
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