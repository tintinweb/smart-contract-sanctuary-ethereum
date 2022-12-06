// Get funds from users
// Withdraw funds as owner of contract
// Set the minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// my pricing libary
import "./PriceConverter.sol";

// const, immutable - if you have a value outside of a function once and never changes, const much cheaper to use

// cost: 809,984
// cost: 790,394

error NotOwner();

contract FundMe {
    // attach my pricing library to the type
    using PriceConverter for uint256;

    // layer 2 source for pricing
    // const (21,415 gas) * 13000000000 = 278395000000000 =     0.000278395 eth = .33 USD
    // non-const (23,515 gas) * 13000000000 = 305695000000000 = 0.000305695000000000 =
    // call = 21,415 * 13000000000 = 278395000000000 = 0.000278395 eth = .33 USD
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public immutable owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18; // Gwei

    AggregatorV3Interface public priceFeed;

    // gets called in the same tx as contract creation
    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // payable turns the function red, this contract can receive wei from sender to store in its wallet
    function fund() public payable {
        // set the minimum fund amount to 1 ETH (1 * 10 ** 18) gwei, revert will rollback and send remaining gas back to sender
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Mininum value is not met.."
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // orange button b/c not payable
        // reset our funders totals
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array with zero elements
        funders = new address[](0);

        // There are 3 ways to send ETH / native tokens (we need to cast the senders addreess to payable address type)
        // see https://solidity-by-example.org/sending-ether/
        // 1. transfer will revert on fail, 2300 gas cap
        //payable(msg.sender).transfer(address(this).balance);

        // 2. send will return bool on fail, so we need to add a require to revert on fail, 2300 gas cap
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send failed");

        // 3. Recommended - call (a lower level command, can call any function in ethereum without ABI) returns 2 vars, no gas capp
        // since bytes objects are arrays dataReturned needs to be in memory - but we dont need it so leave empty
        // (bool callSuccess, bytes memory dataReturned) = ..
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not the owner");
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _; // now execute the rest of the code
    }

    // if msg.data is empty call this
    receive() external payable {
        fund();
    }

    // if msg.data is empty and no recieve() / function missing call this
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// cannot have any state and cannot send ether, and all functions are internal
library PriceConverter {
    // convert ETH to USD on testnet using a chainlink oracle source
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ABI and Address of data source contract: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        (, int256 price, , , ) = priceFeed.latestRoundData(); // price has 8 decimal places
        return uint256(price * 1e10); // 1 ** 10 = 10000000000
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    // both price and amount are have 18 decimal places, 1st parameter is the object called (msg.value)
    function getConversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // eg. 3000_000000000000000000
        // 1_00000000000000000
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