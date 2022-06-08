//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NotOwner();

contract FundMe {
    //chainlink contract address for EVM ETH/USD : 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable i_owner;

    AggregatorV3Interface priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function fund() public payable {
        //Checks the minimum amount in USD
        //using msg.value to check the amount sent
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            //emptying the mapping using the addresses in the array
            addressToAmountFunded[funders[i]] = 0;
        }
        //address array with 0 elements
        funders = new address[](0);

        //withdraw funds
        (bool sendSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(sendSuccess, "Call failed");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        // require(msg.sender == i_owner, "Sender is not owner");
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    /*
     *@dev Taks the amount of eth and converts the amount in USD
     */
    function getConversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);

        //dividing by 1e18 because ethPrice * _ethAmount both have 1e18 decimals and results in 1e36 after multiplication
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    /*
     *@dev returns the price of 1 ETH in USD with 10^18 decimals
     */
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //price = ETH price in USD
        (, int256 price, , , ) = priceFeed.latestRoundData();

        //price has decimals only upto 8 places, but ehter has 18
        //also, our msg.value has uint256 type and price here has int256 type
        //price * 1*10^10, so it will now have 10+8 decimals.
        return uint256(price * 1e10);
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