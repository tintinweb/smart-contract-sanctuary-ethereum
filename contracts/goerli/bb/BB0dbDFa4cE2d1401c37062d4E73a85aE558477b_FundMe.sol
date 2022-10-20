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

error fundme_notOwner();

import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;
    uint256 private constant MINIMUM_USD = 50;
    address[] private s_funders;
    mapping(address => uint256) private s_fundersToFund;
    address private immutable i_owner;

    AggregatorV3Interface immutable priceFeed;

    constructor(address ethUsdPriceAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(ethUsdPriceAddress);
    }

    modifier isOwner() {
        if (msg.sender != i_owner) {
            revert fundme_notOwner();
        }

        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "didn't sent enough!"
        );

        s_funders.push(msg.sender);
        s_fundersToFund[msg.sender] = msg.value;
    }

    function withdraw() public isOwner {
        address[] memory funders = s_funders;
        for (uint256 i = 0; i < funders.length; i++) {
            s_fundersToFund[funders[i]] = 0;
        }

        s_funders = new address[](0);

        (bool isSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(isSuccess, "Withdrawal failed unexpectedly!");
    }

    function getFunder(uint256 _index) public view returns (address) {
        address[] memory funders = s_funders;
        return funders[_index];
    }

    function getFundFromFunder(address _funder) public view returns (uint256) {
        return s_fundersToFund[_funder];
    }

    function getOwner() public view returns (address) {
        return i_owner;
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
        (, int256 latestPrice, , , ) = priceFeed.latestRoundData();

        return uint256(latestPrice);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 latestPrice = getPrice(priceFeed);
        uint256 convertedPrice = (latestPrice * ethAmount) / 1e26;

        return convertedPrice;
    }
}