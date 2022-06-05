// A contract that can receive ETH and withdraw it (no sending it to other though)
// 1. get funds from users
// 2. withdraw funds
// 3. set minimum funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

contract FundMe {
    // this allows using functions in PriceConverter like methods for
    // uint256 vars (e.g. msg.value.getConversionRate)
    using PriceConverter for uint256;

    // post on github discussions why do we need to multiply it by 1e18
    // "constant" prevents the var from being changed -> costs less gas
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    // keeping track of all funders by making an array of their addresses
    // strictly addresses since that is the data type we specified
    address[] public funders;

    // connecting address with the amount funded so we could track
    // which address sent how much
    mapping(address => uint256) public addressToAmountFunded;

    // "immutable" makes the var read-only (like "constant")
    // but assignable in the constructor -> costs less gass
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    // constructor gets automatically run each time a contract is deployed
    // and called?
    constructor(address priceFeedAddress) {
        // setting the owner to be the contract creator
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // "payable" implies that value will be sent in this function
    function fund() public payable {
        // "msg.value" is a number of wei sent in the transaction
        // here in "getConversionRate" we're not passing an argument even though
        // we've specified a parameter in the original func
        // that is because anything that "getConversionRate" is being used as a
        // method on is considered the first argument of the function
        require(
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
            "Didn't send enough!"
        );
        addressToAmountFunded[msg.sender] = msg.value;
        // "msg.sender" is a globally available variable for sender's wallet address
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        // resetting the amount sent by each funder
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // resetting the funders array by creating a new array with 0 items
        funders = new address[](0);

        // actually withdrawing the funds. there are 3 methds:
        // // 1. Transfer
        // // changing the data type from address to payable address
        // // we can only make transactions with payable address data types
        // payable(msg.sender).transfer(address(this).balance);

        // // 2. Send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // // we have to add the "require" because "send" doesn't throw errors if
        // // unsuccessful. instead if returns a boolean
        // // if sendSuccess = false, throw error "Send failed!";
        // require(sendSuccess, "Send failed!");

        // 3. Call
        // with "call", we can both value AND calldata "("")"
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed!");
    }

    // reusing code in different functions
    modifier onlyOwner() {
        require(msg.sender == i_owner, "Sender is not owner!");
        // specifying that we want to run the function code only after
        // checking the require condition
        _;
    }

    // What happens if someone sends this contract ETH
    // without calling the fund func?

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// importing code from github (as a NPM package at chainlink/contracts)
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Libraries are similar to contracts, but you can’t declare any state
// variable (i.e. spend gas) and you can’t send ether.
library PriceConverter {
    // getting ETH price in USD -> interacting with outside data -> oracles
    // Rinkeby testnet
    // ETH/USD address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    // ABI: AggregatorV3Interface
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // type: AggregatorV3Interface, var name: priceFeed
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        // "latestRoundData" returns 5 outputs but we only want 1
        // that's why we put commas for outputs we don't need
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // it returns price with 8 decimals (e.g. 2,000.00000000)
        // that's why we have to add 10 decimals to have 18 total (convention)
        // converting price from int256 to uint256 type
        return uint256(price * 1e10); // 10**10
    }

    // converting specified # of ETH to USD
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // getting the eth price in usd
        uint256 ethPrice = getPrice(priceFeed);

        // ethPrice -> 18 decimals, ethAmount -> 18 decimals
        // that's why we have to divide by 18 decimals
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;

        // still 18 decimals left. why can't we just divide by 1e36 up there?
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