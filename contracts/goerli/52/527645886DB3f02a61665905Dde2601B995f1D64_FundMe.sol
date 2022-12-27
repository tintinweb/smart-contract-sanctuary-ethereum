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

// 1. Pragma
pragma solidity ^0.8.17;

// 2. Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// 3. Errors
error FundMe__MinimumUSD();
error FundMe__NotFunded();
error FundMe__NotOwner();
error FundMe__WithdrawFail();

// 4. Interfaces, Libraries, Contracts

/// @title A sample Funding Contract
/// @author Andrew Hearse
/// @notice This contract is for creating a sample funding contract
/// @dev This implements price feeds as our library
contract FundMe {
    // Type declarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    address private immutable owner;
    address[] private funders;
    mapping(address => uint256) private funderAmount;
    AggregatorV3Interface private priceFeed;

    // Events (we have none!)

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != owner) {
            revert FundMe__NotOwner();
        }
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

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    /// @notice Funds our contract based on the ETH/USD price
    function fund() public payable {
        if (msg.value.getConversionRate(priceFeed) < MINIMUM_USD) {
            revert FundMe__MinimumUSD();
        }

        if (funderAmount[msg.sender] == 0) {
            funders.push(msg.sender);
        }
        funderAmount[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        if (funders.length == 0) {
            revert FundMe__NotFunded();
        }

        address[] memory _funders = funders;
        // mappings can't be in memory, sorry!
        for (uint256 index = 0; index < _funders.length; index++) {
            address funder = _funders[index];
            funderAmount[funder] = 0;
        }
        funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) {
            revert FundMe__WithdrawFail();
        }
    }

    /// @notice Gets the amount that an address has funded
    /// @param funder the address of the funder
    /// @return the amount funded
    function getFunderAmount(address funder) public view returns (uint256) {
        return funderAmount[funder];
    }

    // function getVersion() public view returns (uint256) {
    //     return priceFeed.version();
    // }

    function getFunder(uint256 index) public view returns (address) {
        return funders[index];
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    // call it get fiatConversionRate, since it assumes something about decimals
    // It wouldn't work for every aggregator
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}