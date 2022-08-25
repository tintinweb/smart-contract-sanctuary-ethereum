// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./PriceConvertor.sol";
error FundMe_NotOwner();

contract FundMe {
    using PriceConvertor for uint256;

    mapping(address => uint256) private s_addresToAmounts;
    address[] private s_funders;
    address private i_owner;

    uint256 public MINIMUM_USD = 50 * 1e18;
    AggregatorV3Interface private s_priceFeed;

    modifier OnlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner == msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function Fund() public payable {
        require(
            msg.value.getConversionPrice(s_priceFeed) >= MINIMUM_USD,
            "Not enoug funds"
        );

        s_funders.push(msg.sender);
        s_addresToAmounts[msg.sender] += msg.value;
    }

    function withdraw() public OnlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addresToAmounts[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "not Owner");
    }

    function getfunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAMountFunder(address funder)
        public
        view
        returns (uint256)
    {
        return s_addresToAmounts[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//data feed address ---- 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419

library PriceConvertor {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    //

    function getConversionPrice(
        uint256 EthAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 EthPrice = getPrice(priceFeed);
        uint256 EthPriceinUsd = (EthAmount * EthPrice) / 1e18;
        return EthPriceinUsd;
    }
}