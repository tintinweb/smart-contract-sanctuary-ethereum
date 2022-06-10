// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    // Get funds from users
    // Withdraw funds
    // Set a minimum funding value in USD

    //constant and immutable variables save on gas, constant can't be reassigned and immutable can be reassigned once in the constructor
    uint256 public constant  MINIMUM_USD = 50 * 1e18;
    address public immutable  i_owner;
    AggregatorV3Interface public priceFeed;
    
    //address takes a priceFeedAddress as a parameter so we can choose which priceFeed to use depending on what chain we're on
    constructor(address priceFeedAddress ) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);

    }
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    function fund () public payable {
        // if value sent is not greater than 1 eth, revert and send revert message "Didn't send enough"
        // What is revert? Reverting undos any action before, and sends remaining gas back
        // So any action before revert, you spend that gas to do computation, but anything below revert will not get exected, and then remaning gas is returned
        require (msg.value.getConversationRate(priceFeed) >= MINIMUM_USD, "Didn't send enough"); //value is wei so we need to add zeros
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    

    function withdraw () public onlyOwner {
        //loop through funders array and set amount funded to 0
        for (uint256 i = 0 ; i < funders.length ; i++) {
            address funder =  funders[i];
            addressToAmountFunded[funder] = 0;
        }
        //set funders array to new empty array
        funders = new address[](0);

        //transfer (2300 gas limit, throws error)
        // msg.sender = address
        // payable(msg.sender) = payable address
        payable(msg.sender).transfer(address(this).balance);
        //send (2300 gas, returns bool)
        // send returns a bool value, won't actually revert on it's own. So if we use send we need to make sure to have a require so it can revert on failure
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");
        //call (forward all gas or set gas, returns bool) kind of the "reccommended way" as of now
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    //run this code before running the function this modifider is attached to, that way we don't have to copy paste requirements everywhere
    modifier onlyOwner {
        //do this first, then do _ (which means do the rest of the code)
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) { revert NotOwner();}
        _;
    }

    //what hapens if someone sends this ocntract ETH without calling the fund function?
    
    //receive and fallback are special functions in solidity that don't require the function keyword (constructor is one as well)
    //receive() if eth is sent to contract and msg.data is empty, receive is called
    //fallback() if eth is sent to contract and msg.data isn't empty, fallback is called
    // can have these in the contracts in case someone sends eth to contract without calling the specfic functions you wants
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice (AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // ABI
        // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //this address is the chainlink ethereum data feed for the rinkeby testnet for eth to usd
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        //price of ETH in terms of USD
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10); //add ten decimal places
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    //     return priceFeed.version();
    // }

    function getConversationRate (uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
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