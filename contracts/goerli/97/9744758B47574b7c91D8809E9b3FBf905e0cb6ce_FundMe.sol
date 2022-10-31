//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NotOwner(); // deal error ： https://blog.soliditylang.org/2021/04/21/custom-errors/

contract FundMe {
    using PriceConverter for uint256;

    address[] public funders;

    mapping(address => uint256) public addressToAmountFunded;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    //address from deploy-fund-me.js
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
            "didn't send enough!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() internal view returns (uint256) {
        return priceFeed.version();
    }

    function getDecimals() internal view returns (uint256) {
        return priceFeed.decimals();
    }

    function withdraw() public onlyOwnerModifier {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        uint256 allBalance = address(this).balance;

        (bool callSuccess, ) = payable(msg.sender).call{value: allBalance}("");
        require(callSuccess, "call failed");
        revert();
    }

    modifier onlyOwnerModifier() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    //            is msg.data empty?
    //                 /       \
    //               yes       no
    //            /       \      \
    //        receive()?          fallback()
    //        /       \
    //      yes       no
    //      /           \
    // receive()       fallback()

    // Receive is a variant of fallback that is triggered when msg.data is empty
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //ABI
        //address
        (
            ,
            /*uint80 roundID*/
            int256 price, //price 8位小数  ， 用getDecimals 获取位数 /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
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