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
pragma solidity 0.8.17;

import "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__FundAmountNotEnough();
error FundMe__CallFailed();

/**
 * @title A contract for crowd funding
 * @author Ghaieth BEN MOUSSA
 * @notice To demo a sample funding contract
 * @dev Implements price feeds as a library
 */
contract FundMe {
    using PriceConverter for uint256;

    AggregatorV3Interface private s_priceFeed;

    address private immutable i_owner;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    modifier onlyOwner() {
        if (msg.sender != i_owner) { revert FundMe__NotOwner(); }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        // We want to be able to set a minimum fund amount of 50 USD
        if(msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) { revert FundMe__FundAmountNotEnough();}

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        address[] memory memoryFunders = s_funders;

        // Reset the mapping
        for (uint256 i = 0; i < memoryFunders.length; i++) {
            address funder = memoryFunders[i];
            s_addressToAmountFunded[funder] = 0;
        }

        // Reset the array
        s_funders = new address[](0);

        // Call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        if(!callSuccess) { revert FundMe__CallFailed(); }

    }

    function getOwner() public view returns (address) {
      return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAmountFundedByAddress(address funder) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    // function withdrawNotOptimized() public onlyOwner {
    //     // Reset the mapping
    //     for (uint256 i = 0; i < s_funders.length; i++) {
    //         address funder = s_funders[i];
    //         s_addressToAmountFunded[funder] = 0;
    //     }

    //     // Reset the array
    //     s_funders = new address[](0);

    //     // Call
    //     (
    //         bool callSuccess, /*bytes memory dataReturned*/
    //     ) = payable(msg.sender).call{value: address(this).balance}("");
    //     if(!callSuccess) { revert FundMe__CallFailed(); }
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeedAddress) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        
        (, int price, , , ) = priceFeed.latestRoundData();
         
         // Price is an int with 8 decimals so we
         // convert it to a uint with 18 decimals
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeedAddress) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeedAddress);
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;

        return ethAmountInUsd;
    }
}