// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {

    // Maps each address to the amount funded by that address
    mapping(address=>uint256) public addressToAmountFunded;

    // Stores the addresses of all funders
    address[] public funders;

    // Stores the address of the contract owner
    address public owner;

    // Constructor function that runs once when the contract is deployed
    constructor() {
        // Sets the owner of the contract as the address that deployed the contract
        owner = msg.sender;
    }

    // Function to receive funds and track the amount funded by each address
    function fund() public payable{

        // Sets the minimum amount in USD required to fund (equivalent to $50)
        uint256 minimumUSD = 50 * 10 ** 18;

        // Requires that the conversion rate from ETH to USD is greater than or equal to the minimumUSD
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");

        // Adds the amount funded by the sender's address to the mapping
        addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value;

        // Adds the sender's address to the funders array
        funders.push(msg.sender);

    }

    // Function to get the version of the Chainlink price feed being used
    function getVersion() public view returns(uint256){

        // Creates an instance of the AggregatorV3Interface using the specified address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        // Returns the version of the price feed
        return priceFeed.version();
    }

    // Function to get the latest price from the Chainlink price feed
    function getPrice() public view returns(uint256){

        // Creates an instance of the AggregatorV3Interface using the specified address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        // Retrieves the latest round data from the price feed
        (,int256 answer,,,) =  priceFeed.latestRoundData();

        // Converts the price to a uint256 and adjusts the decimal places
        return uint256(answer)*10000000000;

    }

    // Function to get the conversion rate from ETH to USD
    function getConversionRate(uint256 ethAmount) public view returns(uint256){

        // Gets the current ETH price in USD
        uint256 ethPrice = getPrice();

        // Calculates the ETH amount in USD
        uint256 ethAmountinUSD = (ethPrice*ethAmount)/ 1000000000000000000;

        // Returns the ETH amount in USD
        return ethAmountinUSD;
        // 0.000001866140000000
    }

    // Modifier to restrict certain functions to only the contract owner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Function to withdraw the contract balance to the owner
    function withdraw() payable onlyOwner public {

        // Transfers the contract balance to the recipient
        payable(owner).transfer(address(this).balance);

        // Resets the amount funded by each funder to 0
        for (uint256 funderIndex=0; funderIndex<funders.length;funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // Clears the funders array
        delete funders;
    }

}

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