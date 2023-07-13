// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

contract FundMe {
    /* custom errors */
    error FundMe__NotOwner();
    error FundMe__NotEnoughAmount();
    error FundMe__TransferFailed();

    /*use price converter library functions for all uint256 variables */
    using PriceConverter for uint256;

    /* state variables */
    uint256 constant MINIMUM_USD = 5e18;
    address private immutable i_owner;

    uint256 private s_totalAmountFunded;
    uint256 private s_maximumAmountFunded;
    uint256 private s_latestFundedAmount;
    address[] private s_funders;
    mapping (address funder => uint256 amountFunded) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;


    event Funded(address indexed funder, uint256 indexed amount);

    /* checks if msg sender is owner */
    modifier onlyOwner {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }
    

    constructor(address priceFeed) {
        // set the contract deployer as the owner
        i_owner = msg.sender;
        // set the priceFeed contract
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    /* Handle funds sent directly without using the fund function */
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /* fund the contract */
    function fund() public payable {
        // revert if funded amount is less than 5 USD
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__NotEnoughAmount();
        }

        // add funder to funders array if not already present
        if (s_addressToAmountFunded[msg.sender] == 0) {
            s_funders.push(msg.sender);
        } 
        // update the mapping of address to amounts
        s_addressToAmountFunded[msg.sender] += msg.value;

        // update the total funds and amount to withdraw
        s_totalAmountFunded += msg.value;

        // check for maximum fund
        if (msg.value > s_maximumAmountFunded) {
            s_maximumAmountFunded = msg.value;
        }

        // set the latest fund value
        s_latestFundedAmount = msg.value;
        
        //emit the funded event 
        emit Funded(msg.sender, msg.value);
    }

    /* send the contract balance to the owner */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) {
            revert FundMe__TransferFailed();
        }
    }

    /* reset the amounts funded by all addresses to zero */
    function resetAddressToAmountFunded() private onlyOwner {
        uint256 totalFunders = s_funders.length;
        address[] memory funders = s_funders;
        for (uint256 i=0; i<totalFunders; i++) {
            address funder = funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
    }

    /* reset the funders array */
    function resetFundersArray() private onlyOwner {
        s_funders = new address[](0);
    }

    /* resets everything */
    function resetAllData() external onlyOwner {
        resetAddressToAmountFunded();
        resetFundersArray();
        s_totalAmountFunded = 0;
    }

    /* getter functions */
    function getAddressToAmountFunded(address funder) external view returns(uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getTotalAmountFunded() external view returns(uint256) {
        return s_totalAmountFunded;
    }

    function getLatestAmountFunded() external view returns(uint256) {
        return s_latestFundedAmount;
    }
    
    function getMaximumAmountFunded() external view returns (uint256) {
        return s_maximumAmountFunded;
    }

    function getFunder(uint256 index) external view returns(address) {
        return s_funders[index];
    }

    function getNumberOfFunders() external view returns(uint256) {
        return s_funders.length;
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }

    function getMinimumUSD() external pure returns(uint256) {
        return MINIMUM_USD;
    }

    function getVersion() external view returns(uint256){
        return s_priceFeed.version();
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        // Interact with the chainlink price feed smart contract
        // ABI
        (,int256 price, , ,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice*ethAmount) / 1e18;
        return ethAmountInUsd;
    }

}