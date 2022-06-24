// SPDX-License-Identifier: GPL-3.0

// Pragma
pragma solidity ^0.8.4;

// Imports
import "./PriceConverter.sol";

// Error Codes
error FundMe__NotOwner();
error FundMe__Unauthorized();
error FundMe__MINIMUM_50_USD();

// Interfaces, Libraries, Contracts

// 872912
// 832603
/** @title A contract for crowd funding
 *  @author Patrik Collins
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declaration
    using PriceConverter for uint256;

    // State Variables!
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    // Immutable & Constant
    uint256 private constant MINIMUM_ETHER = 1 ether;
    uint256 private constant MINIMUM_USD = 50 * 1e18;
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__Unauthorized();
        }
        _;
    }

    // Functions Order
    // Constructor
    // Receive
    // Fallback
    // External
    // Public
    // Internal
    // Private
    // View/Pure

    constructor(address priceFeed_) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed_);
    }

    /**
     *  @notice This function funds this contract
     *  @dev This implements price feeds as our library
     */
    function fund() public payable {
        // Minimum aomunt in USD
        // require(msg.value >= MINIMUM_ETHER, "MINIMUM 1 ETHER REQUIRED");
        // msg.value is having 18 decimals
        // require(getConversionRate(msg.value) >= MINIMUM_USD, "MINIMUM 50 USD");

        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__MINIMUM_50_USD();
        }

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public payable onlyOwner {
        // Checks, effects .. interactions

        // Reset State Variables
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // reset array
        s_funders = new address[](0);

        // withdray funds

        // transfer
        // payable(msg.sender).transfer(address(this).balance); // if this line fails, revert the state and return error object. No gas is refunded

        // send
        // bool success = payable(msg.sender).transfer(address(this).balance); // if this line fails, returns the boolean. No gas is refunded
        // require(success, "send failed")

        (bool success, bytes memory data) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "CALL_FAILED");
    }

    function cheapWithdraw() public payable onlyOwner {
        // Reset State Variables
        address[] memory m_funders = s_funders;
        // Mappings can't be in a memory
        for (
            uint256 funderIndex = 0;
            funderIndex < m_funders.length;
            funderIndex++
        ) {
            address funder = m_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // reset array
        s_funders = new address[](0);

        (bool success, bytes memory data) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "CALL_FAILED");
    }

    // View/Pure
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Chainlink Data Feeds
        // ABI
        // Address 0x9326BFA02ADD2366b30bacB125260Af641031331
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x9326BFA02ADD2366b30bacB125260Af641031331
        // );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        // price is going to have 8 decimal places
        return uint256(price * 1e10); // 1**10 = 10000000000
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0x9326BFA02ADD2366b30bacB125260Af641031331
    //     );
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 3000_000000000000000000 = ETH / USD Price
        // 1_000000000000000000 = ETH

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