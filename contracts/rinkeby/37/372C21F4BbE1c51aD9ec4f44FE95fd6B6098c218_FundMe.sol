// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConvertor.sol";
// importing library

/* gas saving 
760,079 - deploying contract with not using constant for MINIMUM_USD variable
740,525 - deploying contract using constant for MINIMUM_USD variable
Difference = 740,525 - 760,079 = 19554 gas
19,554 * 137 gwei = 2678898 gwei = 0.002678898 eth = 4.8220164$ saving (1 eth = $1800)
*/

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    // using A for B means attaching functions available in A to type B so things
    // like B.someFunctionInA can be done

    uint256 public constant MINIMUM_USD = 100 * 1e18;
    // using constant keyword to restrict modification after compile time

    address[] public funders;
    mapping(address => uint256) public addresstoAmountFunded;

    address public immutable i_owner;
    /* constant vs immutable = The difference is that constant variables can never 
    be changed after compilation, while immutable variables can be set within the constructor.
    */

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner,"Not Owner.");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _; //This means run the rest of the code
    }

    function fund() public payable {
        // no need to give a parameter even though function definition says we
        // we need one because (*ALWAYS ALWAYS*) the first parameter passed is the object it is
        // called on.
        require(
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
            "Sending <= 1eth"
        );
        funders.push(msg.sender);
        addresstoAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // Clearing out funds using a for loop
        for (uint256 fIndex = 0; fIndex < funders.length; fIndex++) {
            address funder = funders[fIndex];
            addresstoAmountFunded[funder] = 0;
        }

        // Clearing out funds using a new object
        funders = new address[](0);

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

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
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