// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Get funds form users
// Withdrawal funds
// Set a minimum funding value in USD

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
  using PriceConverter for uint256;

  uint256 public constant MINIMUM_USD = 50 * 1e18;

  address[] public funders;
  mapping(address => uint256) public addressToAmountFunded;

  address public immutable i_owner;

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    // gets called at the moment that the contract is created
    i_owner = msg.sender; // owner = whoever deploys the contract
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function fund() public payable {
    /*
        // Want to be able to to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract?
        // require(msg.value >= 1e18, "Didn't send enough ETH"); // 1e18 = 1 * 10 ** 18 = 1000000000000000000
        
        // Now we want to use the minimumUSD threshold instead of the ETH threshold.
        // We ned to convert the ETH to USD -> we need the price feed ETH/USD -> Oracle (Chainlink)
        require(getConversionRate(msg.value) >= minimumUSD, "Didn't send enough ETH");
        // What is reverting? -> Undo any action before, and sendremaining gas back
        */

    // Library version:
    require(
      msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
      "Didn't send enough ETH"
    );

    // Add address to funders list
    funders.push(msg.sender);
    addressToAmountFunded[msg.sender] = msg.value;
  }

  function withdraw() public onlyOwner {
    // We need to reset the array and mapping
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      // code
      address funder = funders[funderIndex];
      addressToAmountFunded[funder] = 0;
    }
    // reset the array
    funders = new address[](0);

    // actually withdraw the funds - transfer, send, call
    // en teoria call es la millor que podem utilitzar, pero les diferencies son petites
    // caldria mirar en detall per a cada cas quina es la millor.

    // transfer
    // msg.sender = address
    // payable(msg.sender) = payable address
    // payable(msg.sender).transfer(address(this).balance);

    // send
    // bool sendSuccess = payable(msg.sender).send(address(this).balance);
    // require(sendSuccess, "Send failed")

    // call
    //(bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call failed");
  }

  modifier onlyOwner() {
    //require(msg.sender == i_owner, "Sender is not the owner");
    if (msg.sender != i_owner) {
      revert NotOwner();
    } // manera alternativa de fer el mateix pero amb menos gas
    _;
  }

  // What happens if someone sends this contract ETH without calling the fund() function? -> recaive and fallback

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
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    // We need the ABI and the address

    // ABI -> Interfaces

    // Address: easy -> contrract adress section data feeds chanilink (https://docs.chain.link/docs/ethereum-addresses/)
    // address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

    // creem un contracte amb l'adressa del price feed de ETH/USD per Rinkeby
    (, int256 price, , , ) = priceFeed.latestRoundData(); // ETH in terms of USD
    return uint256(price * 1e10); // per retoirnar amb els mateixos decimals uqe tindra el msg.value
  }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
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