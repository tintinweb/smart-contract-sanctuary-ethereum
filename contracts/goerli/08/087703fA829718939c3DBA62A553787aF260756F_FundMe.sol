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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// Sending ETH Through a function & reverts
// - get funds from users
// - withdraw funds
// - set a minimum funding value in USD

// chainlink - is a technology for getting external data and doing external computation in a decentralized context for our smart contracts.

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    // we set those variable one time - we can make it more gas efficient by keywords: constant and immutable.
    // give constant if variable is set ones at compile time
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    // if variable is set one time but outside the line they declated - give immutable
    address public immutable i_owner;

    // the reason why constant and immutable save gas, because it is not store in storage but directly in the bytecode in the contract.

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // want to be able to set a minimum fund amount
        // 1. How do we send ETH to this contract?
        // give function payable keyword
        // $ smart contracts can hold funds just like how wallets can $

        // at list one ether is require
        // require(msg.value >= 1 ether, "Didn't send enough!");

        // how to do it like msg.value is grater or equal than $50?
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );

        // above function if condition is not meet, it revert with error.
        // what is reverting?
        // undo any action before, and send remaining gas back
        // e.g if we put : number = 5, above require() and if require revert transaction, then
        // number will be still 0.

        // we would like to keep tract which address send us money
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset array
        funders = new address[](0);
        // actually withdraw the funds - sending eth from contract

        // 3 ways to send Ether to other contract:

        // 1. transfer (2300 gas, throws error)
        // msg.sender = address
        // payable(msg.sender) = payable address where we send eth in from this contract address
        // payable(msg.sender).transfer(address(this).balance);

        // 2. send (2300 gas, return bool)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed"); // transfer automatically revert transaction, in this case we need to do it manually

        // 3. call - low level command (forward all gas or set gas, returns bool) - so call doesn't have capped gas like functions above
        // Recommended
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        // much more gas efficinet is to create custom error instead of require with string message, it does the same thing like require
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // What happens if someone sends this contract ETH without calling the fund function?
    // we have two special functions in solidity:
    // - receive()
    // - fallback()
    // see FallbackExample contract
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// Transactions fields:
// - nounce: tx count for the account
// - gas price: price per unit of gas (in wei)
// - gas limit: max gas that this tx can use (in case only value, 21000)
// - to: address that the tx is sent to
// - value: amount of wei to send
// - data: what to send to the To address
// - v, r, s: components of tx signature

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// chainlink & oracles
// - chainlink data feeds - gets data from diffrent exchanges and brings that data through the network
// of decentraland chainlink nodes (Data providers -> chainlink nodes).
// then deliver it to single transaction called reference contracts on chain that other contracts can use.

// import interface directly from npm package,
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// library which will be attach to uint256
library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // address:
        // 1. go to docs.chain.link/docs/ethereum-addresses/
        // 2. ethereum data feeds
        // 3. find ETH/USD contract address for appropriate network
        // 4. copy
        // for goreli ETH / USD : 	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e it is address of AggregatorV3Interface

        // ABI - we achive it by interface.
        // after importing AggregatorV3Interface and passing address to it, we can call whathever function from that contract, to interact with it.
        // now we create AggregatorV3Interface instance inside FundMe contract
        (, int price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // solidity doesn't work with decimals, but we already know that there are 8 decimal places.
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // let's assume that 1 ETH is cost $3000 -> 3000_000000000000000000
        // 1ETH -> 1_000000000000000000 ETH
        // (3000_000000000000000000 * 1_000000000000000000) / 1000000000000000000
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}