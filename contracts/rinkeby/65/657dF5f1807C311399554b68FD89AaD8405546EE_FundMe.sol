// SPDX-License-Identifier: MIT
//Pragma statement
pragma solidity ^0.8.0;

// Imports
import "./PriceConverter.sol";

// Error codes
error FundMe__NotOwner();

// Nat spec
/** @title A contract for crowdfunfing
 *   @author Marc Garside
 *   @notice This contract is to demo a sample funding contract
 *   @dev This implements price feeds as our library
 */
contract FundMe {
    // Type declarations
    using PriceConverter for uint256;

    // State variables
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
    AggregatorV3Interface public immutable s_priceFeed;

    // Events

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    // Functions
    //// constructor
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //// receive
    receive() external payable {
        fund();
    }

    //// fallback
    fallback() external payable {
        fund();
    }

    //// external

    //// public

    /**
     *   @notice This function funds this contract
     *   @dev This implements price feeds as our library
     */
    function fund() public payable {
        require(
            msg.value.getConvertionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        );

        // add funders to address array
        s_funders.push(msg.sender);

        // record who sent what amount
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // reset funders amounts
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];

            s_addressToAmountFunded[funder] = 0;
        }

        // reset address array
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
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

        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    //// internal
    //// private

    //// view/pure
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunders(uint256 index) public view returns (address) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // because we are not modifying anything we can make this a view.
    // as this returns a uint256, we need to specify that too.
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // price of eth in terms of USD
        // this function returns many values, we must leave the commas for those values we don't want
        // (uint80 roundId, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
        (, int256 price, , , ) = priceFeed.latestRoundData();

        // because ETH has 18 decimals, and the price above is returned with 8 decimals, we must do some maths.
        // Also, msg.sender and price are not the same type (uint vs int), so we can type cast to make them both the same.
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    function getConvertionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);

        // imagine eth is $2k, the math would look something like this:
        // 2000_000000000000000000 = ETH/USD price
        // 1_000000000000000000 = 1 ETH
        // the below cal takes those numbers and does the following maths:
        // 2000_000000000000000000 * 1_000000000000000000 / 1_000000000000000000
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