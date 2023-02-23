// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    // 1eth = 1,000,000,000gwei = 1,000,000,000,000,000,000wei
    uint256 ethToWei = 1 * 10**18;
    uint256 ethToGwei = 1 * 10**10;
    uint256 minUSD = 1;
    address owner;
    address[] funders;
    AggregatorV3Interface priceFeed;

    mapping(address => uint256) addressToAmountMap;

    constructor(address _priceFeedAddr) {
        priceFeed = AggregatorV3Interface(_priceFeedAddr);
        owner = msg.sender;
    }

    function getEthPriceIn18Digits() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // answer will provide price data with 8 decimals precision
        // extend to 18 digits version
        return (uint256(answer) * ethToGwei);
    }

    function getConversionToWei(uint256 _wei) public view returns (uint256) {
        uint256 priceIn18Digits = getEthPriceIn18Digits();
        return ((priceIn18Digits * _wei) / ethToWei);
    }

    function fund() public payable {
        require(
            getConversionToWei(msg.value) >= minUSD * ethToWei,
            "Need more spending to fund!!!"
        );
        addressToAmountMap[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "Only contract owner do withdraw");
        _;
    }

    function ownerWithdraw() public payable ownerOnly {
        payable(msg.sender).transfer(address(this).balance);
        // clear all records
        for (uint256 index = 0; index < funders.length; ++index) {
            addressToAmountMap[funders[index]] = 0;
        }
        funders = new address[](0);
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 price = getEthPriceIn18Digits();
        return ((minUSD * ethToWei * ethToWei) / price) + 1;
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