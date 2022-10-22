// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./PriceConvertor.sol";

error MinimumFundAmount();
error OwnerError();

contract FundMe {
    using PriceConvertor for uint256;
    uint256 public constant minimumUSD = 10;
    address immutable ownerWallet;

    address[] funders;
    mapping(address => uint256) fundersHistory;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        ownerWallet = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        if (msg.value.getConversionRate(priceFeed) < (minimumUSD * 1e18))
            revert MinimumFundAmount();
        funders.push(msg.sender);
        fundersHistory[msg.sender] = msg.value;
    }

    function withdraw() public isOwner {
        for (uint i = 0; i < funders.length; i++) {
            address funder = funders[i];
            fundersHistory[funder] = 0;
        }
        funders = new address[](0);
        // send funds
        (bool callRes, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callRes, "call operation didn't work");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    modifier isOwner() {
        if (msg.sender != ownerWallet) revert OwnerError();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function lastETHUSDPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 lastprice, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(lastprice * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = lastETHUSDPrice(priceFeed);
        uint256 amountOnUSD = (ethAmount * ethPrice) / 1e18;
        return amountOnUSD;
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