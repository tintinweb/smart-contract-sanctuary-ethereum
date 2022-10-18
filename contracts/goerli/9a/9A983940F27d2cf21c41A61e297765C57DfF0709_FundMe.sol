//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PriceConverter.sol";

/* Get funds from users
   Withdraw Funds from contract
   Set a minimum funding value */

error NotOwner();

contract FundMe {
  using PriceConverter for uint256;

  uint256 public constant MINIMUM_USD = 5 * 1e18;
  address public immutable i_owner;
  address[] public funders;
  mapping(address => uint256) public addressToAmountFunded;
  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function fund() public payable {
    // Want to set a minimum fund amount in USD
    // How to send ETH to this contract?
    require(
      msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
      "Minimum transaction amount: $50."
    );
    funders.push(msg.sender);
    addressToAmountFunded[msg.sender] = msg.value;
  }

  function withdraw() public onlyOwner {
    //require(msg.sender == owner, "Sender does not own contract."); this is moved to onlyOwner modifier
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      addressToAmountFunded[funder] = 0;
    }
    funders = new address[](0);

    // call - current best practice for sending ETH or nataive blockchain tokens
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call failed.");

    /* 
        transfer
        msg.sender == address
        payable(msg.sender) == payable address
        payable(msg.sender).transfer(address(this).balance);
          
        send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed."); 
        */
  }

  modifier onlyOwner() {
    // require(msg.sender == i_owner, "Sender does not own contract.");
    if (msg.sender != i_owner) {
      revert NotOwner();
    } //more gas efficient
    _;
  }

  // what happens if someone sends this contract eth without using the fund function?
  // receive
  receive() external payable {
    fund();
  }

  // fallback
  fallback() external payable {
    fund();
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    // ABI application binaray interface
    (, int256 price, , , ) = priceFeed.latestRoundData(); // price of ETH in terms of USD
    return uint256(price * 1e10);
  }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
    return ethAmountInUSD;
  }

  function getVersion() internal view returns (uint256) {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(
      0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    );
    return priceFeed.version();
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