/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract simpleFundMe {
    mapping(address => uint256) public simpleAddresstoFundAmount;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function simpleFund() public payable {
        // But this is all in ETH...
        // What is the ETH -> USD conversion rate?
        // 1. Get the ETH->USD Rate
        // 2. Convert ETH to USD using the rate
        // 3. Compare with $50 and revert, if not eligible
        // uint256 minimumFund = 50 * 10 ** 18;
        uint256 minimumFund = 50;
        require(
            getUsdAmount(msg.value) >= minimumFund,
            "You need to spend a ETH!"
        );
        simpleAddresstoFundAmount[msg.sender] += msg.value;
    }

    function getFeedVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getUsdRate() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 latestUsdPrice, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(latestUsdPrice * 10000000000);
    }

    function getUsdAmount(uint256 _pEthAmount) public view returns (uint256) {
        //get USD rate for ETH
        uint256 currentUsdRate = getUsdRate();
        //get USD total by multiplying with ETH
        uint256 valueEthInUSD = (currentUsdRate * _pEthAmount) /
            1000000000000000000;
        return valueEthInUSD;
    }
}