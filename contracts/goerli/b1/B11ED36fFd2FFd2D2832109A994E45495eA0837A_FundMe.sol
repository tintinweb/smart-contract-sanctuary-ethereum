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

// Get funds from users
// withdraw funds
// set a minimum funding value in USD

// SPDX-License-Identifier: MIT
//pragma
pragma solidity ^0.8.8;
//imports
import "./PriceConverter.sol";
// Error codes
error FundMe__NotOwner();

// Interfaces, Libraries, Contract

/**
 * @title A contract for crowd funding
 * @author Shaiza Tahir
 * @notice This contract is to demo a sample funding contract
 * @dev This contract implements price feeds as our library
 */
contract FundMe {
    // Type declarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1*10**18
    // 21,415-gas constant
    // 23,515-gas non-constant
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;
    // 21,508-gas immutable
    // 23,644-gas non-immutable

    AggregatorV3Interface public s_priceFeed;
    // Events, modifiers
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        } // revert saves alot of gas
        _;
    }

    // Funtions Order:
    // constructor
    // receive
    // fallback
    // external
    // public
    // internal
    // private
    // view / pure

    // we can change chains
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // if data is empty
    receive() external payable {
        fund();
    }

    // if data is sent with a transaction, and no function specified
    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds the contract
     * @dev This implements price feeds as our library
     */
    function fund() public payable {
        // want to be able to sent a minimum amount in USD
        // 1. How do we sent ETH to this contract
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't sent enough"
        ); // 1e18 == 1 * 10 *18 == 1000000000000000000
        // 18 decimals
        // What is reverting?
        // undo any actions before, and send remaining gas back
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    // view / pure

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }
    function getAddressToAmountFunded(address funder) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

// 5 steps to solve any coding problem
// 1. Tinker and experiment
// 2. check the docs
// 3. do web search
// 4. ask question on forum & Q&A sites
// 5. Join and strengthen the comunity and tool

//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Libraries are similar to contracts, but you can't declare any state variable and you can't send ether.
// A library is embedded into the contract if all library functions are internal.

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ABI
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10); // 1 * 10 == 10000000000
    }


    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 3000_000000000000000000 ETH / USD price
        // 1_000000000000000000
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // without division it will have 36 zeros at the end
        return ethAmountInUsd;
    }
}