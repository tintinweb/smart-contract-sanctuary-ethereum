// SPDX-License-Identifier: MIT
// Get funds from users
// Withdraw funds
// SEt a minimum funding value in USD
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18

    address[] public funders;
    mapping(address => uint256 ) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // Waant to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract ?
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "You need to spend more ETH!"); // 1Eth == 1e18 == 1 * 10 ** 18
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    

    function withdraw() public onlyOwner {
        /* startIndex; endIndex; steps*/
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset Array
        funders = new address[](0);
        // 3 ways to Withdraw funds
        // 1. transfer
            // msg.sender is of type uint256
            // payable is of type payable
        /*
        payable( msg.sender ).transfer(address(this).balance);
        */

        // 2. send : will return a boolean for the transaction which has to be handled with the key word require
        /* 
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed !!");
        */

        //  3. call
        (bool sendSuccess,/* bytes memory dataReturned */) = payable(msg.sender).call{value: address(this).balance}("");
        require(sendSuccess, "Call failed !!");
    }
    // modifier's are like guards that are ran before a function or variable it's modifying is evaluated
    modifier onlyOwner() {
        // require(i_owner == msg.sender, "Sender not owner");
        if(i_owner != msg.sender) {revert NotOwner();}
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        // ABI 
        // Address  0x8A753747A1Fa494EC906cE90E9f37563A8AF630e 
        // the adddress for eth/usd on Rinket
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256 (price * 1e10);
    }

    function getVersion() internal view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
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