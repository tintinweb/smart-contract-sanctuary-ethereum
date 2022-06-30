// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

// This can be more gas efficient than using 'require' in a modifier
error NotOwner(); // newer feature for solidity.  Expect to see 'require' in most old code examples

contract FundMe {
    using PriceConverter for uint256;

    event Funded(address indexed from, uint256 amount);

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    // if variable is only set once, but in a different line than it was instantiated, we can use 'immutable' to save on gas
    address public owner;
    // If we assign a variable in a contract only once, at compile time, we can make it a 'constant' to save on gas
    // txn cost with constant 21415 -> without constant 23515
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        // immediately set owner to be the address the contract was deployed by/from
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        ); // if this fails, it will revert.  We can provide custom error msg as second arg
        funders.push(msg.sender); // msg.sender is the address sending the ether;
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // prevent anyone other than the owner from withdrawing
        // require(msg.sender == owner, "Sender is not owner!");

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the array
        funders = new address[](0); // (0) says init array with no length/objects in it
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // modifier is a keyword that can be added to a function declaration to modify that function's functionality
    // functions that get the modifier do whatever is in the modifier first, then function body, then whetever is next in modifier
    modifier onlyOwner() {
        // require(msg.sender == owner, "Sender isnot owner!");
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    // What happens if someone sends this contract ETH w/o calling the fund function?
    // receive and fallback will make sure the function gets called anyways.

    receive() external payable {
        // just call the fund function
        fund();
    }

    fallback() external payable {
        // same here, just call fund
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// yarn add --dev @chainlink/contracts
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // NEED TO HAVE...
        // ABI -
        // ADDRESS - 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );

        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD

        // cast int256 to uint256, to match msg.value
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // dividing by 1e18 ensures the result has 18 decimal places.  Make sure division happens last.
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;

        return ethAmountInUsd;

        // EX. 3000_000000000000000000 = ETH / USD price
        // We send 1_000000000000000000 ETH to this contract, which equals $3000 (above)
        // To get price, multiply them together, and divide by 1e18 to get the 18 decimal places
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