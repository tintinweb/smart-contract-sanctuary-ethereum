// IF YOU GOING THROUGH THIS CODE, SORRY FOR THE MANY COMMENTS.
// THEY ARE THERE FOR LEARNING/REFERENCE PURPOSES.
// READABILITY WAS NOT A PRIORITY IN THIS CASE.

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//Get Funds From Users
//Withdraw Funds
//Set a minimum funding value in USD

// SPDX-License-Identifier: GPL-3.0
// 1. Pragma
pragma solidity ^0.8.7;
// 2. Imports
import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// 3. Interfaces, Libraries, Contracts
error FundMe__NotOwner();

/** @title A contract for crowd funding
 * @author Kihiu Frank
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    // Events (we have none!)

    // Modifiers
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //What happens if someone sends this contract ETH without calling fund()?
    //receive()
    //fallback()

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds this contract
     * @dev This implements price feeds as our library
     */
    function fund() public payable {
        //Want to be able to set minimum fund amount in USD
        // 1. How do we send ETH to this contract

        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough!" //error message if require fails
        ); // 1e18 = 1*10 ** 18 == 1000000000000000000
        // this has 18 decimals

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        /* starting Index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset the array
        s_funders = new address[](0);

        /*        // withdrawing the funds (#WAYS)
        // 1. Transfer (capped at 2300 gas, throws error)
        //msg.sender = address     // payable(msg.sender) = payable address
        payable(msg.sender).transfer(address(this).balance);
        // 2. Send (capped at 2300 gas, returns bool)
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send Failed!");
*/

        // 3. Call (forward all gas or set gas, returns bool)
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed!");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;

        //mappings can't be in memory

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        //reset the array
        s_funders = new address[](0);

        // 3. Call (forward all gas or set gas, returns bool)
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess, "Call Failed!");
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//library Lesson

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //(uint80 roundId, int256 price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();

        // SAME AS ABOVE. We skipped them (but left commas) since we only need the price.
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 1500.00000000

        return uint256(price * 1e10); // 1**10 == 10000000000
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