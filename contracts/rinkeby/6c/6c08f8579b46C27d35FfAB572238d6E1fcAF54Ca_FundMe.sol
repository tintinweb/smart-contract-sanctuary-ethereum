// SPDX-License-Identifier: MIT
//Pragma
pragma solidity ^0.8.7;
// Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";
// Error Codes
error FundMe__NotOwner();

// Interfaces, Libraries, Contracts

/** @title A contrac for crowd funding
 * @author Aleksander Morawski
 * @notice This contract is a demo of a simple funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type delarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 50 * 10**18;
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public immutable owner;
    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not the owner");
        if (msg.sender != owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /**
     * @notice This funds this contract
     * @dev This implements price feeds as our library
     */
    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Sender is not an owner!");
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in USD
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmont,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmontInUSD = (ethPrice * ethAmont) / 1e18;
        return ethAmontInUSD;
    }
}