// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// constant, immutable (saves gas)

// 1,039,853
// 1,020,318 (with constant for MINIMUM_USD)

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public MINIMUM_USD = 50 * 1e18; // 18 decimals, constant variables name convention: capitalize everything
    // 21,460 (with constant)
    // 23,560

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner; // immutable variable naming convention : i_....

    // 21,508 (with immutable)
    // 23,644

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        // called immediately once the contract is called
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // want to be able to set a min fund amount in UDS
        // 1. how to send ETH to this contract
        // require(getConversionRate(msg.value) > MINIMUM_USD, "Didn't send enough!"); // 1e18 = 1 * 10^18
        require(
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
            "Didn't send enough!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
        // 18 decimal places for msg.value

        // what is reverting?
        // undo any action before, and send remaining gas back
    }

    function getPrice() public view returns (uint256) {
        // ABI
        // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e (an aggregator contract: used for datafeeding)
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // price of ETH in terms of USD
        // 3000.00000000 (8 decimals)
        return uint256(price * 1e10); // 1**10 (typecast to match with the above)
    }

    // function getVersion() public view returns (uint256) {
    //     // AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //     //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    //     // );
    //     return priceFeed.version();
    // }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        // 3000_0000 0000 0000 0000 00 = ETH / USD price
        // 1_0000 0000 0000 0000 00 = ETH
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        // 2999e21
        return ethAmountInUsd;
    }

    /* comment */
    function withdraw() public onlyOwner {
        // make sure this is callable only by the owner of the contract
        //require(msg.sender == owner, "Sender is not owner!");

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // code
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0);
        // actually withdraw the funds

        // <methods of sending ETH>
        // 1. transfer
        // msg.sender = address
        // payable(msg.sender) = payable address
        payable(msg.sender).transfer(address(this).balance);

        // 2. send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");

        // 3. call (recommended)
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // returns 2 variables
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // like a plug-in
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            // this method saves gas
            revert NotOwner();
        }
        _; // the rest of the code
    }

    // What happens if sb sends this contract ETH w/o calling the fund function
    // receive()
    // fallback()

    receive() external payable {
        // like rerouting
        fund();
    }

    fallback() external payable {
        fund();
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

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI
        // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e (an aggregator contract: used for datafeeding)
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // price of ETH in terms of USD
        // 3000.00000000 (8 decimals)
        return uint256(price * 1e10); // 1**10 (typecast to match with the above)
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
        // 3000_0000 0000 0000 0000 00 = ETH / USD price
        // 1_0000 0000 0000 0000 00 = ETH
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        // 2999e21
        return ethAmountInUsd;
    }
}