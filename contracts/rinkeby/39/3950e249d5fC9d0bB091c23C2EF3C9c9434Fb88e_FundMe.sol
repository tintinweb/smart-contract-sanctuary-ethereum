//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

//701,962 gas price without immutable and constant keywords
//657501  gas price with immutable and constant keywords

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    address[] public Funders;
    mapping(address => uint256) public AddressToAmountFunded;

    uint256 public constant MINIMUM_USD = 50 * 1e10;
    //23471 * 42520000000 gas price without constant
    //21415 gas price with constant

    //address public immutable i_owner;
    address public owner;

    //23622 gas price without immutable
    //21508 gas price with immutable

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enogh"
        );

        Funders.push(msg.sender);

        AddressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // for loop
        for (
            uint256 FundersIndex = 0;
            FundersIndex < Funders.length;
            FundersIndex++
        ) {
            address Funder = Funders[FundersIndex];
            AddressToAmountFunded[Funder] = 0;
        }
        //reset an Array
        Funders = new address[](0);

        //Different ways to send Ethereum

        //  transfer
        //  payable(msg.sender).transfer (address(this).balance);

        //  send
        // bool sendSuccess = payable(msg.sender).send (address(this).balance);
        // require(sendSuccess,"Send Failed");

        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner() {
        //require (msg.sender == i_owner , "Sender is not a owner");
        //657513
        if (msg.sender != owner) {
            revert NotOwner();
        }
        //632402
        _; //rest of code represent with _
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        public
        view
        returns (uint256)
    {
        //ABI
        //Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e18);
    }

    // function getVersion() public view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    //     );
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e10;
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