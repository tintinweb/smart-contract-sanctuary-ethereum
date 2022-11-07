// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// importing our library
import "./PriceConvertor.sol";

contract FundMe {
    // this line says that apply library methods on uint256
    using PriceConvertor for uint256;
    uint256 public constant MIN_USD = 0.00000000000001 * 1e18;

    address internal immutable owner;

    // ! we create a global aggregrator interface object
    AggregatorV3Interface internal priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    address[] public funders;
    mapping(address => uint256) public addressToAmtFunded;

    function fund() public payable {
        // since msg.value is a uint256 - library method getConversionRate applies on it.
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Didn't send enough ?"
        );
        funders.push(msg.sender);
        addressToAmtFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // for loop
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmtFunded[funder] = 0;
        }

        // reset the array
        funders = new address[](0);
        // withdraw the funds - three ways - transfer, send, call

        // TRANSFER
        payable(msg.sender).transfer(address(this).balance);

        // SEND
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");

        // CALL
        (bool callSuccess, bytes memory dataReturned) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owner");
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
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// This is a library
// Library can't have any state variables and also can't be payable
library PriceConvertor {
    function getPrice(AggregatorV3Interface priceFeed)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // msg.value has 18 zeroes after decimal point, this means if x.(18 zeroes) = x,0000...(18 zeroes without decimal places)
        // price is int gwei, thus it already has 8 decimal places, we need to give it 10 more decimal places and so we multiple with 1e10;
        return uint256(price * 1e10);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getConversionRate(uint256 ethamt, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI
        // Address - 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        uint256 ethprice = getPrice(priceFeed);
        uint256 ethAmtInUsd = (ethprice * ethamt) / 1e18;
        return ethAmtInUsd;
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