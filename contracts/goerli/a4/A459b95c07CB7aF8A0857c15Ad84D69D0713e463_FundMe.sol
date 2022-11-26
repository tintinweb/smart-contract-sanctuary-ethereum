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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PriceConverter.sol";

//transaction cost	816662 gas (base)
//transaction cost	797132 gas (MINIMUM_USD as const)
//transaction cost	773529 gas (above and i_owner as immutable)
//transaction cost	748406 gas (above and NotOwner custom error)

error FundMe__NotOwner();

/** @title alsdjakd
 *  @author sdf
 *  @notice NatSpec
 *
 */
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // constant - constant:)

    address[] public funders;
    mapping(address => uint256) fundersToAmountFunded;

    address public immutable i_owner; // immutable - changed only once

    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not the owner!");   // string is stored in slot in cotract, if we revert by custom error it is more gas efficient
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // the rest of code after modifier execution
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // what happens if someone will send this contract ETH without calling fund() method
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        ); // 1e18 = 1 * 10 ** 18 = 1 eth (in wei)
        funders.push(msg.sender);
        fundersToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            fundersToAmountFunded[funder] = 0;
        }
        funders = new address[](0); // (0) means 0 elements in array
        // // transfer
        //     // msg.sender is address type
        //     // payable(msg.sender) is payable address type
        // payable(msg.sender).transfer(address(this).balance);    // if the gas fee is > 2300 it fails, throws an error and automatically reverts
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);    // if the gas fee is > 2300 it fails and returns bool
        // require(sendSuccess, "Send failed!");
        // call - recomended for sending and reciving native currency token
        //{bool callSuccess, bytes memory dataReturned}
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed!");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData(); // ETH in USD (usd with 8 decimal places)
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