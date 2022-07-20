//SPDX-License-Identifier: MIT

//adding in some gas optimizations from v1

pragma solidity ^0.8.0;

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//declaring a standard error message instead of typing out the string in require statements
error NotOwner();

contract FundMe {
    //using as a library for our uint256 types
    using PriceConverter for uint256;

    // declaring it as a constant makes it immutable and saves gas
    // constants generally in all caps w/ underscores
    uint256 public constant MIN_USD = 50 * 1e18;

    AggregatorV3Interface public priceFeed;

    //declaring as an array of addresses
    address[] public funders;
    mapping(address => uint256) public funderTable;

    // declaring as immutable also saves gas
    // not sure diff btwn constant & immutable, can find in solidity docs
    address public immutable owner;

    //so we're paramaterizing the priceFeedAddress such that it will pull from
    //the v3Interface the correct address for the price feed address based
    //on the chainId we're specifying in our deployment script
    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "sender is not owner");
        if (msg.sender != owner) revert NotOwner();
        _;
        //underscore tells the EVM to go on executing code if the require returns true
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Didn't send enough!"
        );
        funders.push(msg.sender);
        funderTable[tx.origin] = msg.value;
    }

    function withdraw() public onlyOwner {
        //require(msg.sender == i_owner, "sender is not owner");

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            funderTable[funder] = 0;
        }
        funders = new address[](0);

        payable(msg.sender).transfer(address(this).balance);

        // alt: bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // alt: require(sendSuccess, "Send Failed");

        // , as placeholder where return data would be if applicable
        // "" represents that our call isn't calling any functions at the target adddress
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //commas needed bc this call actually returns a bunch of variables, but we just need the one
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //gives it same # of digits as the eth received (18), typecast as uint256
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //dividing to remove all the extra digits and account for lack of decimals
        uint256 ethAmountInUSD = (getPrice(priceFeed) * ethAmount) / 1e18;
        return ethAmountInUSD;
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