// SPDX-License-Identifier: MIT
/** This contract was written obeying the solidity style guide */

// pragma
pragma solidity ^0.8.16;

//imports
import "./PriceConverter.sol";

// error codes
error FundMe__NotOwner();

//contracts
contract FundMe {
    // type declarations
    using PriceConverter for uint256;

    // state variables
    uint256 public constant MINIMUM_USD = 10 * 1e18;

    address[] private s_funders; // creating an array for all the funders in our contract...the s_ prefix is a good convention for storage variables
    mapping(address => uint256) private s_addressToAmountFunded; // mapping addresses to the variable...the s_ prefix is a good convention for storage variables

    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    // modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /**
     * @notice This function funds this contract
     * @dev This implements price feeds as our library
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough USD!"
        );

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value; // addressToAmountFunded of the funders is equal to the value of USD sent
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++ // ending index;  funderIndex < funders.length shows that the ending
        ) {
            address funder = s_funders[funderIndex]; // returns an address of a funder according to its index
            s_addressToAmountFunded[funder] = 0; // after withdrawing the funds, this resets it to zero
        }
        // resetting the array
        s_funders = new address[](0);
        // To actually withdraw the funds
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // Creating a withdrawal function that is much cheaper
    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // note: mappings can't be in memory
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

    // gets the owner address
    function getOwner() public view returns (address) {
        return i_owner;
    }

    // gets the funders from the address array
    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    // gets the addressToAmountFunded
    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    // gets the priceFeed
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
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