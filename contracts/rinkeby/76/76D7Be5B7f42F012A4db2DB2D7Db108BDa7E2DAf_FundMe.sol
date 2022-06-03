//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";


error FundMe_NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address private immutable owner_;
    address[] private funders_;

    mapping(address => uint256) private addressToAmountFunded_;
    AggregatorV3Interface public  priceFeed_;

    constructor(address priceFeedAddress) {
        owner_ = msg.sender;
        priceFeed_ = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        if (msg.sender != owner_) revert FundMe_NotOwner();
        _;
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed_) >= MINIMUM_USD, "You need to add more ETH!");
        addressToAmountFunded_[msg.sender] += msg.value;
        funders_.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        for (uint256 i = 0; i < funders_.length; i++) {
            address funder = funders_[i];
            addressToAmountFunded_[funder] = 0;
        }
        funders_ = new address[](0);
        
        (bool success, ) = owner_.call{value: address(this).balance}("");
        require(success);
    }

    function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
        return addressToAmountFunded_[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return priceFeed_.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return funders_[index];
    }

    function getOwner() public view returns (address) {
        return owner_;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed_;
    }

    receive() external payable {
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
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer, ,,) = priceFeed.latestRoundData();
        return uint256 (answer * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}