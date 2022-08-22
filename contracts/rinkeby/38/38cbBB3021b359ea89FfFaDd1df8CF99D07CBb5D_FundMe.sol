// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// Importing Chainlink's Interface
import "./PriceConvertor.sol";
// Importing library

/* gas saving 
760,079 - deploying contract with not using constant for MINIMUM_USD variable
740,525 - deploying contract using constant for MINIMUM_USD variable
Difference = 740,525 - 760,079 = 19554 gas
19,554 * 137 gwei = 2678898 gwei = 0.002678898 eth = 4.8220164$ saving (1 eth = $1800)
*/

error FundMe__NotOwner();

/** @title A contract for crowd funding
 *  @author Pranay Reddy
 *  @notice Demo a crowd funding contract
 *  @dev THis implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256;
    // using A for B means attaching functions available in A to type B so things
    // like B.someFunctionInA can be done

    uint256 public constant MINIMUM_USD = 100 * 1e18;
    // using constant keyword to restrict modification after compile time

    address[] private s_funders;
    mapping(address => uint256) private s_addresstoAmountFunded;

    address private immutable i_owner;
    /* constant vs immutable = The difference is that constant variables can never 
    be changed after compilation, while immutable variables can be set within the constructor.
    */

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        //require(msg.sender == i_owner,"Not Owner.");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; //This means run the rest of the code
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /*
    Which function is called, fallback() or receive()?

           send Ether
               |
         msg.data is empty?
              / \
            yes  no
            /     \
receive() exists?  fallback()
         /   \
        yes   no
        /      \
    receive()   fallback()
    */

    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    /**
     *  @notice This function allows user to deposit eth (minimum 100$ worth) into the contract
     *  @dev Use of library to get ethUsd value from Chainlink Price Feed / Mock Price Feed
     */
    function fund() public payable {
        // no need to give a parameter even though function definition says we
        // we need one because (*ALWAYS ALWAYS*) the first parameter passed is the object it is
        // called on.
        require(
            msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD,
            "Sending <= 1eth"
        );
        s_funders.push(msg.sender);
        s_addresstoAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public payable onlyOwner {
        // Clearing out funds using a for loop
        for (uint256 fIndex = 0; fIndex < s_funders.length; fIndex++) {
            address funder = s_funders[fIndex];
            s_addresstoAmountFunded[funder] = 0;
        }

        // Clearing out funds using a new object
        s_funders = new address[](0);

        // Ways to transfer tokens
        //Ref link: https://solidity-by-example.org/sending-ether

        // 1. Using transfer
        payable(msg.sender).transfer(address(this).balance);

        // 2. Using send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Withdrawal of funds using send failed.");

        // 3. Using call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Withdrawal of funds using call failed.");
    }

    function cheaperWithdraw() public payable onlyOwner {
        // Instead of reading from storage which costs a ton of gas , we'll copy it into memory and do our operations in that

        address[] memory funders = s_funders;
        // mapping's can't be in memory

        for (uint256 funderIdx = 0; funderIdx < funders.length; funderIdx++) {
            address funder = funders[funderIdx];
            s_addresstoAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

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
        return s_addresstoAmountFunded[funder];
    }

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

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//Interface object gets compiled to an ABI, an ABI matched with an address gives you a contract

library PriceConverter {
    // returns price of eth in usd
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //Address ETH/USD Chainlink Oracle : 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );

        //Extrapolating the required value into a variable
        (, int256 price, , , ) = priceFeed.latestRoundData();

        // * 1e10 to match it with default 1e18 wei (By default this price feed has 8 decimal places)
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