// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe_MinimumNotMet();
error FundMe_WithdrawFailed();

/**
 * @title A contract for CrowdFunding
 * @author MDUSTRIES Corp.
 * @notice This is a sample funding contract and it has not been audited
 * @dev This uses Chainlink Oracle for price feeds
 */
contract FundMe {
    // Type declarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    mapping(address => uint256) private s_amountFundedByFunderAddress;
    address[] private s_funders;
    AggregatorV3Interface private s_priceFeed;
    address private immutable i_owner;

    // Events
    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    modifier minimumRequired() {
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) revert FundMe_MinimumNotMet();
        _;
    }

    // Function order:
    // constructor, receive, fallback, external, public, internal, private, view, pure
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

    /**
     * @notice Funds the contract
     * @dev This uses Chainlink Oracle for price feeds
     */
    function fund() public payable minimumRequired {
        s_amountFundedByFunderAddress[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    /**
     * @notice Withdraws all funds frm the contract
     * @dev Only callable by the contract owner
     */
    function withdraw() public payable onlyOwner {
        address[] memory funders = s_funders; // reading from memory save gas
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_amountFundedByFunderAddress[funder] = 0;
        }

        s_funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) revert FundMe_WithdrawFailed();
    }

    /**
     * @return The address of the owner of the contract
     */
    function getOwner() public view returns (address) {
        return i_owner;
    }

    /**
     * @param index uint256 index of the funder to get
     * @return The address of the funder at the given index
     */
    function getFunderByIndex(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    /**
     * @param funder address of the funder
     * @return The amount funded by the given address
     */
    function getAmountFundedByAddress(address funder) public view returns (uint256) {
        return s_amountFundedByFunderAddress[funder];
    }

    /**
     * @return The price feed aggregator
     */
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
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

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 11e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}