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

// Get funds from users, withdraw funds, set a minimium funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error notOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // consant ~ variable declaration on a single line and never changed again, 2000 gas saving

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner; // saves ~2000 gas, immutable for separate variable declaration to value assignement

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // payable is added to
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Minimum value is 50 USD"
        ); // 1e18 = 1*10^18 wei - 18 decimals because 18 zeroes for wei
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
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
        // reset the array
        funders = new address[](0);
        // actually withdraw the funds

        // transfer
        // msg.sender -> address, payable(msg.sender) -> typecasts msg.sender to a payable address
        // payable(msg.sender).transfer(address(this).balance)

        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert notOwner();
        } // custom errors instead of require will save gas
        _;
    }

    // What happens if someone sends this contract ETH without calling fund(); ?

    receive() external payable {
        fund();
    }

    // fallback();
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ABI import

        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000 (decimals function) -> we want to turn it to 18 decimals
        return uint(price * 1e10); // 1**10 = 10 exp 10
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 3000_18 zeroes = ETH / USD price
        // 1 _ 18 zeroes ETH
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        // 3_21 zeroes <-> 3000.0000... USD
        return ethAmountInUsd;
    }
}