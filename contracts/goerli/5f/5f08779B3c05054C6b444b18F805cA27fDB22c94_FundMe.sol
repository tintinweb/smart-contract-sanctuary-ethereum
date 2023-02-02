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
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 20 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    modifier onlyOwner() {
        // require(i_owner == msg.sender, "only owner can execute withdraw()");
        if (i_owner != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    AggregatorV3Interface public priceFeed;

    constructor(address PriceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(PriceFeedAddress);
    }

    function donate() public payable {
        require(
            msg.value.getTotalValue(priceFeed) >= MIN_USD,
            "fund is not enough"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // // withdarw the fund
        // payable(msg.sender).transfer(address(this).balance);

        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");

        // resetting everything
        for (uint256 index = 0; index < funders.length; index++) {
            addressToAmountFunded[funders[index]] = 0;
        }
        funders = new address[](0);
    }

    receive() external payable {
        donate();
    }

    fallback() external payable {
        donate();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint(price); // 8 decimals
    }

    function getVersion(
        AggregatorV3Interface priceFeed
    ) public view returns (uint256) {
        return priceFeed.version();
    }

    function getTotalValue(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 totalPrice = (ethPrice * ethAmount) / 1e8;
        return totalPrice;
    }
}