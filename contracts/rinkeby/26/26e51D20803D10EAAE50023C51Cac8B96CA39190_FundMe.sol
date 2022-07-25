// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;
    /* As we declare this variable and define it's value in the same line, but we never
change it, to storage it in the ABI of the contract we can declare that variable
a constant. The name has to be in capitals and every word separated with _ (convention)*/
    uint256 public constant MIN_FUND = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public fundersToFund;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //require(getConvertion(msg.value) >= MIN_FUND);
        require(msg.value.getConvertion(priceFeed) >= MIN_FUND);
        funders.push(msg.sender);
        fundersToFund[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        //to delete de mapping we use a for loop
        //It goes like this (starting index, ending index, steps at a time)
        for (
            uint256 fundersIndex = 0;
            fundersIndex > funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            fundersToFund[funder] = 0;
        }
        funders = new address[](0);

        // Now three ways to withdraw funds from a contract, we're using call method
        // With the call method we can call any function. Here we're calling the value function to send funds
        // We're using call because it's more gas efficient - more on this latter -
        (bool callSucces, ) = payable(msg.sender).call{
            value: address(this).balance
        }(";");
        // If the transaction does not succed, we return the second variable
        require(callSucces, "Transaction failled");
    }

    /* A modifier is a key word that we create to be added to a function declaration
    the function will excute what is declared in the modifie before continue with the function*/
    modifier onlyOwner() {
        require(msg.sender == i_owner);
        _;
        /* Here we said, if msg.sender(who tries to execute withdraw() is not
        the i_owner, don't let it do it. the "_;" excute the rest of the code of the
        function, obviusly you have to meet the first line*/
    }

    /* Imagine that someone sends funds to our contract without using fund()*/
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//The other two ways to withdraw ETH from a contract
// payable(msg.sender).transfer(address(this).balance);
// bool sendSucced = payable(msg.sender)send(address(this).balance);
// require(sendSucced, "Your transaction failled");

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e18);
    }

    function getConvertion(uint256 ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethPriceinUSD = (ethPrice * ethAmount) / 100;
        return ethPriceinUSD;
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