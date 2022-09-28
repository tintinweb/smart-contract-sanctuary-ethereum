// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PriceConverter.sol";

    error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 10 * 1e8;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert NotOwner();

        _;
    }

    function fund() public payable {
        _fund();
    }

    function withdraw() public onlyOwner {

        // reset state
        for (uint i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        // withdraw funds
        (bool ok,) = payable(msg.sender).call{value : address(this).balance}("");
        require(ok, "Call failed");
    }

    receive() external payable {
        _fund();
    }

    fallback() external payable {
        _fund();
    }

    function _fund() internal {
        require(msg.value.weiToUsd(priceFeed) >= MINIMUM_USD, "Minimum contribution is 50 USD");

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function weiToUsd(uint256 weiAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 price = getPrice(priceFeed);
        uint256 weiAmountInUsd = (weiAmount * price) / 1e18;
        return weiAmountInUsd;
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