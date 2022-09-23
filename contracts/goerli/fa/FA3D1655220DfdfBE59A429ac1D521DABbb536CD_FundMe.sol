// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 10 * 1e18;

    address[] public funders; // creating an array for all the funders in our contract
    mapping(address => uint256) public addressToAmountFunded; // mapping addresses to the variable

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed; // creating a variable for the AggregatorV3Interface here called priceFeed

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // payable is the keyword that allows our contract fundable,(red button)
    function fund() public payable {
        // We want to be able to fund our contract
        // We want to set a minimum fund amount in USD

        // to set the minimum fund amount in eth to be 1eth
        // require(msg.value >= minimumUSD, "Didn't send enough USD!!"); // 1e18...1 wei to ether
        // require( getConversionRate(msg.value) >= minimumUSD,"Didn't send enough USD!!"); // 1e18...1 wei to ether
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough USD!"
        );

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value; // addressToAmountFunded of the funders is equal to the value of USD sent
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Sender is not owner!"); //linking the constructor owner with the withdrawal function
        // we want to reset our funders array and addressToAmountFunded since we will be withdrawing all the funds.
        // for loop      /* starting index, ending index, step amount */

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++ // ending index;  funderIndex < funders.length shows that the ending
        ) {
            address funder = funders[funderIndex]; // returns an address of a funder according to its index
            addressToAmountFunded[funder] = 0; // after withdrawing the funds, this resets it to zero
        }
        // resetting the array
        funders = new address[](0);
        // To actually withdraw the funds
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // // we paste the commented owner only withdrawal function under this modifier
        // require(msg.sender == i_owner, "Sender is not owner!");
        // _; // meaning to check for the owner first then run the witdrawal function
        // // if _; was above, it will run the withdrawal function first then check for the owner
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // What happens if when someone sends money to this contract without using the fund function

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // here we make all the functions internal

    // we are going to create a function to get the price of the USD here with the blockchain we are working with
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // to interact with a contract outside our contract, we are going to need the ABI and Address
        // ETHUSD contract address price feed for goerli testnet  0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        // calling the priceFeed of the function latestRoundData from our interface and the price of ETH in USD only
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // price of ETH in USD
        // but then it returns the price in 8 decimal places
        // To return the price to the standard wei value of 1e18
        // return price * 1e10; // 1e10 times the previous 1e8 is equal to the standard value of 1e18
        // converting the above to uint, we do
        return uint256(price * 1e10);
    }

    // we are also going to create a function that gets the conversion rate of the USD
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // calling the the getPrice function with uint256 ethPrice
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18; // here we divide the 36 dp gotten from multiplying the both to give us the standard wei converion
        return ethAmountInUSD;
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