// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./PriceConsumerV3.sol";

error FundMe__NotOwner();

/** @title A contract for crowd funding
 * @author Apoorva Shukla
 * @notice This contract is to demo a sample funding contract
 * @dev This implements chainlink price feed as our library
 */
contract FundMe {
    // State variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    PriceConsumerV3 private s_priceConsumer;
    address private immutable i_owner;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == getOwner(), "Sender is not the owner!");
        if (msg.sender != getOwner()) {
            revert FundMe__NotOwner();
        }
        _;
    }

    // Functions Order
    /**
     * constructor
     * receive
     * fallback
     * external
     * public
     * internal
     * private
     * view/pure
     */
    constructor(address _priceFeedAddress) {
        s_priceConsumer = new PriceConsumerV3(_priceFeedAddress);
        i_owner = msg.sender;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This function is to transfer the contract balance to the owner
     * @dev This function uses call to transfer contract balance
     */
    function withdraw() external onlyOwner {
        // set the amount to zero of s_addressToAmountFunded addresses
        for (uint256 i = 0; i < s_funders.length; i += 1) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }

        // Reset the s_funders array
        s_funders = new address[](0);

        // Transfer the balance to message sender
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() external onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory
        for (uint256 i = 0; i < funders.length; i += 1) {
            address funder = funders[i];
            s_addressToAmountFunded[funder] = 0;
        }

        // Reset the s_funders array
        s_funders = new address[](0);

        // Transfer the balance to owner
        (bool callSuccess, ) = payable(i_owner).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

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
        return s_priceConsumer.getPriceFeed();
    }

    function fund() public payable {
        require(
            s_priceConsumer.getConversionRate(msg.value) >= MINIMUM_USD,
            "Didn't send enough money"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract PriceConsumerV3 {
    // Type declarations
    using PriceConverter for AggregatorV3Interface;

    AggregatorV3Interface private s_priceFeed;

    constructor(address _priceFeedAddress) {
        s_priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getLatestPrice() public view returns (uint256) {
        return getPriceFeed().getLatestPrice();
    }

    function getVersion() public view returns (uint256) {
        return getPriceFeed().getVersion();
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        return getPriceFeed().getConversionRate(ethAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getDecimals(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        return priceFeed.decimals();
    }

    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 decimalsLeft = uint256(18) - getDecimals(priceFeed);
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price) * 10 ** decimalsLeft;
    }

    function getVersion(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        return priceFeed.version();
    }

    function getConversionRate(AggregatorV3Interface priceFeed, uint256 ethAmount) internal view returns (uint256) {
        uint256 ethPriceInUSD = getLatestPrice(priceFeed);
        uint256 ethAmountInUSD = (ethAmount * ethPriceInUSD) / 1e18;
        return ethAmountInUSD;
    }
}