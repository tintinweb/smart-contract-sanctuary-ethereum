//Get funds from users
//Withdraw funds
//Set a Minimum funding value in USD

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    //less gas with constant

    address[] public funders;
    mapping(address => uint256) public adressToAmoutFunded;

    address public immutable i_owner;

    //less gas with immutable

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender; //msg.sender = one that deploys contract, for first time
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //set minimum fund amout of USD
        // 1.How do we send ETH to this contract
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough ETH"
        ); //1e18 == 1 * 10^18
        //if condition is not met, require reverts everything done in the function!!!
        //everythong before require spends gas, but for everything after gas is returned!!!
        funders.push(msg.sender);
        adressToAmoutFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            adressToAmoutFunded[funder] = 0;
        }
        funders = new address[](0);
        //transfer
        //msg,sender = address
        //payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);
        //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner,"Only owner can withdraw money");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _; //this is where resto of the code of original function is going, it can also go before
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
    //If someone wants to send money to contract without fundMe
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//Library something like static class

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //ABI (interface)
        //Address of contract from data feeds on ChainLink, 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //ETH in terms of USD
        //price has 8 decimals and msg.value has 18 so you multiply with 10
        return uint256(price * 1e10);
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return (ethAmount * getPrice(priceFeed)) / 1e18;
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