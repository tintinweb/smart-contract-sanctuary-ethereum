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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error fundMe_notOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 private constant MINIMUM_USD = 50;
    address[] private s_funders;
    mapping(address => uint256) private s_fundersToFunds;
    address private immutable i_owner;
    AggregatorV3Interface private priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier isOwner() {
        if (msg.sender != i_owner) {
            revert fundMe_notOwner();
        }
        _;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "didn't sent enough!"
        );
        s_funders.push(msg.sender);
        s_fundersToFunds[msg.sender] = msg.value;
    }

    function withdraw() public isOwner {
        address[] memory funders = s_funders;
        for (uint256 i = 0; i < funders.length; i++) {
            s_fundersToFunds[funders[i]] = 0;
        }

        s_funders = new address[](0);

        (bool isSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(isSuccess, "Withdrawal Failed Unexpectedly!");
    }

    function getPriceFeedAddress() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        address[] memory funders = s_funders;
        return funders[index];
    }

    function getFundFromFunder(address funder) public view returns (uint256) {
        return s_fundersToFunds[funder];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 latestEthPrice, , , ) = priceFeed.latestRoundData();

        return uint256(latestEthPrice);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 latestEthPrice = getPrice(priceFeed);
        uint256 convertedEthPrice = (latestEthPrice * ethAmount) / 1e26;

        return convertedEthPrice;
    }
}