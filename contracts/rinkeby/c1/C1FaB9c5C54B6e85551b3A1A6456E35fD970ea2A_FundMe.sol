// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

//SPDX-License-Identifier: MIT
// Pragma
pragma solidity ^0.8.0;

// Imports
import "./PriceConverter.sol";

// gas cost 843,184 823,642

//  Error Codes
error FundMe__NotOwner();

// Interfaces, Libraries, Contracts

/** @title A contract for crowd funding
 *  @author Raymond Chidavaenzi
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    // constant & immutable are for variables that can only be declared and updated once
    // will help save gas
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1* 10 ** 18
    address[] public funders;
    address public immutable i_owner;
    mapping(address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public s_priceFeed;

    // Modifiers
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not the ownwer");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    // Functions order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view/ pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //  What happens if somebody sends this contract ETH without calling the fund. function
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // want to be able to send a minimum fund amount in USD
    // 1. How do we send ETH to this contract

    /**  @notice This funtion funds the contract
     *   @dev This implements price feeds as our library
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough money"
        ); // 1e18 == 1 * 10 ** 18 = 1 000000 000000 000000
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    /* call -- in combination with re-entrancy guard is the 
 recommended method to use after December 2019.
 Guard against re-entrancy by making all state changes before (check effects)
 calling other contracts using re-entrancy guard modifier */

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // code
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0);
        // acctually withdraw the funds
        //call - (forward all gas or set gas, returns bool)
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Libraries are similar to contracts, but you can't declare any state variable and you can't send ether.
// A library is embedded into the contract if all library functions are internal.
// Otherwise the library must be deployed and then linked before the contract is deployed.

library PriceConverter {
    // interaction with external contracts needs ABI and contract address
    // 	addy == 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    function getPrice(AggregatorV3Interface _priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = _priceFeed.latestRoundData();
        return uint256(answer * 1e10); // 1**10 == 10000000000
    }

    function getVersion() internal view returns (uint256) {
        address ethUsdFeedAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            ethUsdFeedAddress
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18; // ALWAYS multiply before you divide
        return ethAmountInUsd;
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