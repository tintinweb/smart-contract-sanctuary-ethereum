//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();
error LessThanMinUSD();
error WithdrawFailed();

contract FundMe {
  using PriceConverter for uint256;

  uint256 public constant MIN_USD = 50 * 1e18;
  address[] public funders;
  mapping(address => uint256) public addressToAmountFunded;
  address public immutable i_owner;

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    i_owner = msg.sender; // This is so the deployer of the contract is the owner.
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  function fund() public payable {
    // require(msg.value.getConversionRate() > MIN_USD, "The minimum funding is 50 USD.");
    if (msg.value.getConversionRate(priceFeed) < MIN_USD) {
      revert LessThanMinUSD();
    }
    funders.push(msg.sender);
    addressToAmountFunded[msg.sender] = msg.value;
  }

  modifier onlyOwner() {
    //require (msg.sender == i_owner, "Only the owner can withdraw.");
    if (msg.sender != i_owner) {
      revert NotOwner();
    }
    _; // The rest of the code. Ex: the Send function.
  }

  function withdraw() public onlyOwner {
    for (uint256 i = 0; i < funders.length; i++) {
      addressToAmountFunded[funders[i]] = 0;
    }
    // This resets the array by declaring it anew with no objects (0).
    funders = new address[](0);

    // Then send this contract's native ETH balance to the sender.
    // Since msg.sender is of type message, it needs to be cast as a payable
    // before ETH can be sent.
    // transfer would revert is the transfer failed.
    // payable(msg.sender).transfer(address(this).balance);

    // Using send. Send would only respond with a boolean, so we need to
    // catch any error and revert the transaction.
    // bool sendSuccess = payable(msg.sender).send(address(this).balance);
    // require(sendSuccess, "Send failed.");

    // Using call which as of Dec-2019 is the preferred method.
    (
      bool callSuccess, /*bytes memory dataReturned*/

    ) = payable(msg.sender).call{value: address(this).balance}("");
    //require(callSuccess, "Call failed.");
    if (!callSuccess) {
      revert WithdrawFailed();
    }
  }

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

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
  // We could make this public, but then we'd have to deploy it
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    // Rinkeby ETH / USD Address
    // https://docs.chain.link/docs/ethereum-addresses/
    /*AggregatorV3Interface priceFeed = AggregatorV3Interface(
      0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    );*/
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    // ETH/USD rate in 18 digit
    return uint256(answer * 10000000000);
  }

  // 1000000000
  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    // the actual ETH/USD conversation rate, after adjusting the extra 0s.
    return ethAmountInUsd;
  }
}