// SPDX-License-Identifier: BSD2

// Pragma
pragma solidity ^0.8.0;

// Imports
import "./PriceConverter.sol";

// Error Codes
error FundMe__NotOwner();
error FundMe__Insufficient_ETH();
error FundMe__Withdraw_Failed();

/**
 * @title A contract for crowd funding
 * @author Sudaraka Wijesinghe
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type declarations
    using PriceConverter for uint256;

    // State variables
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    AggregatorV3Interface private s_priceFeed;

    // Modifiers
    modifier onlyOwner {
        //require(msg.sender == i_owner, "Sender is not owner");

        if(msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // run rest of the modified function
    }

    // Functions: constructor
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /*
    // Functions: receive
    receive() external payable {
        fund();
    }

    // Functions: fallback
    fallback() external payable {
        fund();
    }
    */

    /**
     * @notice This functions funds this contract
     */
    function fund() public payable {
        // require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!"); // 10^18
        // NOTE: failing above requirement revert the functions performed so far. Gas is still spent for them.

        if(msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__Insufficient_ETH();
        }

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        //require(msg.sender == i_owner, "Sender is not i_owner");

        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex = funderIndex + 1) {
            address funder = s_funders[funderIndex];

            s_addressToAmountFunded[funder] = 0;
        }

        // reset the s_funders array
        s_funders = new address[](0);

        // actually withdraw the funds
        (bool callSuccess, ) = payable(msg.sender).call{ value: address(this).balance }("");
        // check status and manually revert.
        if(!callSuccess) {
            revert FundMe__Withdraw_Failed();
        }
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;

        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex = funderIndex + 1) {
            address funder = funders[funderIndex];

            s_addressToAmountFunded[funder] = 0;
        }

        // reset the s_funders array
        s_funders = new address[](0);

        // actually withdraw the funds
        (bool callSuccess, ) = i_owner.call{ value: address(this).balance }("");
        // check status and manually revert.
        if(!callSuccess) {
            revert FundMe__Withdraw_Failed();
        }
    }

    // View/Pure functions

    function getOwner() public view returns(address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns(address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns(uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns(AggregatorV3Interface) {
        return s_priceFeed;
    }
}

// SPDX-License-Identifier: BSD2
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        ( //uint80 roundId
        , int256 price
        , //uint startedAt
        , //uint timeStamp
        , //uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        return uint256(price * 1e10); // 10^10
   }

    function getConversionRate(uint256 _ethAmount, AggregatorV3Interface _priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18;

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