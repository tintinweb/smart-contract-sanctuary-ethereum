// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe {
    AggregatorV3Interface internal priceFeed;

    mapping(address => uint256) public funded;
    address[] participants;

    address owner;

    /**
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     *
     * Reference: https://docs.chain.link/docs/ethereum-addresses/#Rinkeby%20Testnet
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        owner = msg.sender;
    }

    function fund() public payable {
        require(isEnoughFund(msg.value), "You have to give more!");
        if (funded[msg.sender] == 0) {
            participants.push(msg.sender);
        }

        funded[msg.sender] += msg.value;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "You are not owner!");
        _;
    }

    function withdraw() public payable ownerOnly {
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 i = 0; i < participants.length; i++) {
            funded[participants[i]] = 0;
        }

        participants = new address[](0);
    }

    function isEnoughFund(uint256 _wei) internal view returns (bool) {
        uint256 minimumUsdWRTWei = 1 * (10**18);

        return getUsdWRTWei(_wei) >= minimumUsdWRTWei;
    }

    function getUsdWRTWei(uint256 _wei) internal view returns (uint256) {
        return (getCurrentRateWRTWei() * _wei) / (10**18);
    }

    /**
     * 18 decimal
     * If 1 ETH = 1224.10309161 USD
     * This function returns 1224103091610000000000
     */
    function getCurrentRateWRTWei() internal view returns (uint256) {
        return getCurrentRateWRTGwei() * (10**10);
    }

    /**
     * 8 decimal
     * If 1 ETH = 1224.10309161 USD
     * This function returns 122410309161
     */
    function getCurrentRateWRTGwei() internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
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