// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConvertor.sol";

contract FundMe {
    using PriceConvertor for uint256;

    uint256 private constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmount;
    address private immutable i_owner;

    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert();
        _;
    }

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        i_owner = msg.sender;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        require(msg.value.priceConvertionRate(priceFeed) >= MINIMUM_USD);
        funders.push(msg.sender);
        addressToAmount[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 i; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmount[funder] = 0;
        }
        funders = new address[](0);

        (bool success, ) = payable(i_owner).call{value: address(this).balance}(
            ""
        );
        require(success);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getPrice(
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        (, int price, , , ) = _priceFeed.latestRoundData();
        return uint256(price * 1e18);
    }

    function priceConvertionRate(
        uint256 _ethAmount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256 ethAmountInUSD) {
        uint256 ethPrice = getPrice(_priceFeed);
        ethAmountInUSD = (ethPrice * _ethAmount) / 1e18;
    }
}