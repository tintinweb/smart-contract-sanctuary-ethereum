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

//SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.0;

library Conversion2UsdLibrary {
    uint256 internal constant PriceDecimals = 8; //we can't divide price by weis in eth because we need precision so we instead need to multiply USD amount we compare with
    uint256 internal constant PriceDecimalsMultiplier = 10 ** (PriceDecimals);
    uint256 internal constant OneEthInWeis = 1e18;

    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (int) {
        (, int price, , , ) = priceFeed.latestRoundData();

        return price;
    }

    function getConversionCostInUSDWeisWithDecimals(
        uint256 eth,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return uint256(getPrice(priceFeed)) * eth;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./Conversion2UsdLibrary.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error notOwner();

contract FundMe {
    AggregatorV3Interface public immutable priceFeedAggregator;

    address public immutable imOwner;

    uint256 public constant MinimumUSD = 10; //store also 8 decimals
    uint256 public constant MinimumUSDWithDecimals =
        MinimumUSD * Conversion2UsdLibrary.PriceDecimalsMultiplier;

    //we can't divide price by weis in eth because we need precision so we instead need to multiply USD amount we compare with
    uint256 public constant MinimumUSDForCompareWithPrice =
        MinimumUSDWithDecimals * Conversion2UsdLibrary.OneEthInWeis;

    address[] public funders;
    mapping(address => uint256) public fundersToGivings;

    using Conversion2UsdLibrary for uint256;

    constructor(address priceFeedAggregatorAddress) {
        imOwner = msg.sender;
        priceFeedAggregator = AggregatorV3Interface(priceFeedAggregatorAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionCostInUSDWeisWithDecimals(
                priceFeedAggregator
            ) > MinimumUSDForCompareWithPrice,
            "NotEnoughUsd"
        );
        funders.push(msg.sender);
        fundersToGivings[msg.sender] = msg.value;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function withdraw() public modOnlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            fundersToGivings[funders[funderIndex]] = 0;
        }
        funders = new address[](0);
        //payable(msg.sender).transfer(address(this).balance);
        //bool succ1 = payable(msg.sender).send(address(this).balance);
        //require(succ1, "Can't SEND funds");
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier modOnlyOwner() {
        //require(msg.sender == imOwner, "Sender is not owner");
        if (msg.sender != imOwner) revert notOwner();
        _;
    }
}