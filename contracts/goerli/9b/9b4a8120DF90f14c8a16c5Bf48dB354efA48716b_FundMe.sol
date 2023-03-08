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
//1. Pragma statements
pragma solidity ^0.8.0;

//2. Import statements
import "./PriceConverter.sol";

//3. Error codes
error FundMe__NotOwner();

//4. Interfaces, 5. Libraries, 6. Contracts

/**
 * @title A contract for crowd funding
 * @author ahdrahees
 * @notice This contract is to demo a sample funding contract
 * @dev This implement price feeds as our library
 */
contract FundMe {
    //a. Type declarations
    using PriceConverter for uint256; // attaching library into uint256

    //b. State variables
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10**18
    // 21,393 gas- constant = 21393 * 12 == 0.31062636 usd
    //23,493 gas =  23493 * 12000000000= 0.000281916 eth= 0.34111836 usd - without constant var

    address[] private s_funders; // s_ indicate this will be storage variable ( convection or style, practices)
    mapping(address => uint256) private s_addressToAmountedFunded;

    address private immutable i_owner;

    //23644 gas-
    // 21508 gas- immutable

    AggregatorV3Interface private s_priceFeed;

    //c. Events, d. Errors, e. Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");       // to check the owner of the contract
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // continue rest of the code in the withdraw() if the require is true
    }

    //f. Functions
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    /**
     * @notice This function fund this contarct
     * @dev This implement price feeds as our library
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough ETH!"
        );
        s_funders.push(msg.sender);
        s_addressToAmountedFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountedFunded[funder] = 0;
        }
        s_funders = new address[](0); // reset the array funders

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call withdraw failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders; // memory will be cheaper to read
        // mapping's can't be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountedFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // (bool callSuccess, ) = payable(msg.sender).call{
        //     value: address(this).balance
        // }("");
        // require(callSuccess, "Call withdraw failed");

        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountedFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountedFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
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