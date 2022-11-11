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

// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe{
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // USD

    address[] public funders;
    mapping (address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we sent ETH to this contract?
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough!"); // 1e18 == 1 * 10 ** 18
        // 18 decimals

        // What is reverting?
        // undo any action before, and send remainning gas back

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function Withdraw() public onlyOwner {
        // for(starting index, ending index, step amount)
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0); // (i) means there are i objects in this array

        // actually withdraw the funds
        // there are three ways
        // 1. transfer
         // msg.sender == address
         // payable(address) == payable address
        // payable(msg.sender).transfer(address(this).balance);
        // 2. send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance); // if failed, it will not revert transaction
        // require(sendSuccess, "Send failed");
        // 3. call recommended
        (bool callSuccess, /* bytes memory dataReturned */) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if(msg.sender != i_owner) { revert NotOwner(); }
        _; // reset of codes
    }

    // What happens if someone send this contract ETH without calling the fund function
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// install by "yarn add --dev @chainlink/contracts"
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// library cannot have any state variables and cannot send ETH
library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // ABI
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e); // not need this, because we received it
        (, int256 price,,,) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // ethPrice * ethAmount だけだと32decimalになる
        return ethAmountInUsd;
    }
}