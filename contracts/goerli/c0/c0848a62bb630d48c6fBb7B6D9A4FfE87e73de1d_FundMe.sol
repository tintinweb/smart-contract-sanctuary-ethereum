// Get Funds _ Send Funds _ Set Min fund Value

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PriceConverter.sol";

// 	693911 gas
// 	684290 gas
//  660783 gas
//  627655 gas

error notOwner();

contract FundMe {
    // use PriceConverter as a library
    using PriceConverter for uint256;
    address[] public funders;
    mapping(address => uint256) public addressToAmount;

    address public immutable i_owner;

    uint256 public constant minimumUsd = 50;

    string public country = "India";

    AggregatorV3Interface public priceFeed;

    // constructor gets already called when the contract is deployed
    // priceFeed address will be different according to the network
    constructor(address priceFeedAddress) {
        // msg.sender will be one who calls constructor or in other terms who deploys the contract
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //this also needs to get added 18 extra zeroes to equalise with Wei unit
        // contracts like wallets can hold funds and have their unique addresses on the chain
        // 1ETH = 1*10^18 Wei ___ Inside of contract we need to handle funds in terms of Wei Unit not Ether.

        require(
            msg.value.getConversionRate(priceFeed) >= minimumUsd,
            "ETH is less than worth of 50 dollars USD"
        );
        // adding addrees of funders to the funders array
        funders.push(msg.sender);
        addressToAmount[msg.sender] = msg.value;
        // set amount funded by funder in hashmap

        // revert - Undos any action done any sends the remaining gas back(but the gas get used on those things which
        // were changed before revert happend)
    }

    function withdraw() public onlyOwner {
        // only owner can call this
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex = funderIndex + 1
        ) {
            address funder = funders[funderIndex];
            addressToAmount[funder] = 0;
        }
        // reset the array coz all funds are withdrawn above
        funders = new address[](0);
        // actually withdraw the funds
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        // msg.sender is one who is calling the withdraw function which will be only the owner here
        require(
            callSuccess,
            "Withdraw Ops Failed cause of error in callSuccess"
        );
    }

    modifier onlyOwner() {
        // _; position means when the onlyOwner will be executed
        // require(msg.sender == i_owner, "You are not the Owner of this Contract");
        if (msg.sender != i_owner) {
            revert notOwner();
        }
        _;
    }

    // if someone sends eth without fund function route them to fund function
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        public
        view
        returns (uint256)
    {
        /*
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        */
        (
            ,
            /*uint80 roundID*/
            int price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint(price);
        // 131340000000
        //  8

        //$1,313.40000000 <- current 1ETH price in USD
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // here the entered amount is in wei not in eth
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e26;
        // divide by 26 zeros to get amount in exact usd
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