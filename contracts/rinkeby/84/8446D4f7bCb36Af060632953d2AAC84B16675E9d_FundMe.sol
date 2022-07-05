// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

// Get funds from users
// withdraw funds
// Set a minimum funding value in USD
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    // smart contract addresses can hold funds just like wallets
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        // this is called immediately when ever this contract is deployed
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // set min amount to fund in USD
        //  msg.value is in terms of ETH and MINIMUM_USD in US dollar.
        //  How to convert and compare to validate ? this is where we use decentralized Oracles like ChainLink

        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Minimum value USD"
        ); // 1e18 = 1 * 10 ** 18 == 1000000000000000000 1ETH = 1e18
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        // starting index, ending index, step amount
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //  reset the array
        funders = new address[](0); // it resets the funders array
        //  actually withdraw the funds

        // "transfer", the max gas fee is 2300, so if transaction need more gas this will error and reverts the transaction
        // payable(msg.sender).transfer(address(this/*refers the current contract i.e; FundMe*/).balance /*FundMe contract balance*/);

        // "send", the max gas fee is 2300, so if transaction need more gas this will return bool false, or true if success, this wont revert
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // manual revert of transaction
        // require(sendSuccess, "Send failed");

        // "call", there is cap on gas fee, it calls some other function, it returns if call to function success and the data returned by the function
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        // manual revert of transaction
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _; // this is to represent to execute the rest of the code of function if above is passed.
    }

    // what happens if someone sends this contract ETH without calling the fund function
    // receive()

    receive() external payable {
        fund();
    }

    // fallback()
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI (ABI is like an interface of a contract it let us know what we can do with the contract )
        // address to get live price 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData(); // price of ETH in usd
        return uint256(price * 1e10);
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
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