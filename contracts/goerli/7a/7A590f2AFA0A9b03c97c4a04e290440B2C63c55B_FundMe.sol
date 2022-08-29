// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract FundMe {
    // state variable
    // uint256 private constant MINIMUM_AMOUNT_ETH = 0.01 * 10**18; // wei

    using PriceConverter for uint256;

    event convertedPrice(uint256 indexed convertedPrice);

    uint256 private constant MINIMUM_AMOUNT_USD = 50 * 10**18;
    address immutable i_owner;
    address s_aggregatorAddress;
    address[] private s_funders;
    mapping(address => uint256) private addressToAmount;
    AggregatorV3Interface private s_priceFeed;

    // constructor
    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    // fund, withdraw, showBalance function
    function fund() public payable {
        emit convertedPrice(msg.value.getEthPriceInUsd(s_priceFeed));
        require(
            msg.value.getEthPriceInUsd(s_priceFeed) >= MINIMUM_AMOUNT_USD,
            "You need to fund more ETH"
        );
        s_funders.push(msg.sender);
        addressToAmount[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        address[] memory funders = s_funders;

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmount[funder] = 0;
        }
        s_funders = new address[](0);

        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // get function

    function getMinimumUSD() public view returns (uint256) {
        return MINIMUM_AMOUNT_USD / 10**18;
    }

    // modifier
    modifier onlyOwner() {
        require(i_owner == msg.sender);
        _;
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
    function getRatio(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getEthPriceInUsd(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ratio = getRatio(priceFeed);
        uint256 ethPriceInUsd = (ethAmount * ratio) / 10**18;
        return ethPriceInUsd;
    }
}