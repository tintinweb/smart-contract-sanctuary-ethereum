// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import"./PriceConverter.sol";

// tricks to bring down the gas; constant, immutable

error NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
   
    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract?
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough"); // 1e18 = 1 * 10^18
        //msg.value has 18 decimal places
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }
    
    function withdraw() public onlyOwner {
        for(uint256 i = 0; i < funders.length; i++) {
            addressToAmountFunded[funders[i]] = 0;
        }

        // reset the array
        funders = new address[](0);

        // actually withdraw the funds

        // This is the recommended way *for the most part* to send and recieve eth or your blockchain token
        // call method:
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");

    
        // transfer method:
      //  payable(msg.sender).transfer(address(this).balance); // msg.sender = address, payable(msg.sender) = payable address
    
        // send method:
      //  bool sendSuccess = payable(msg.sender).send(address(this).balance);
      //  require(sendSuccess, "Send failed");

    }

    modifier onlyOwner {
        // using require is pretty gas costly -> require(msg.sender == i_owner, "Sender is not owner!");

        if(msg.sender != i_owner) { // this saves gas since we don't have to store an array string anywhere
            revert NotOwner();
        }
        _;
    }

    // What happens if someone sends this contract ETH without calling the fund() function?

        // recieve()
        // fallback()

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface _priceFeed) internal view returns (uint256){
        // We will use another contract, so we need the:
        // ABI: we can import the contract (see top of code)
        // Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e (this is the Rinkeby testnet address for ETH to USD)
        
        (,int256 price,,,) = _priceFeed.latestRoundData();
        // ETH in terms of USD, USD has 8 decimal places, ETH has 18
        return uint256(price * 1e10); // 1^10, do this so eth and usd has same amout of decimal places
    }

    function getConversionRate(uint256 _ethAmount, AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18;
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