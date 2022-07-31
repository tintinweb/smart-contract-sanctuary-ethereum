// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// 780162 gas
// add constant : 760608 gas
// add constant and Immutable : 737682 gas

// -------------
// gas	848335 gas
// transaction cost	737682 gas
// execution cost	737682 gas

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders; // funders list

    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // set a minimum fund amount in USD
        // 1. how do we send ETH to this contract
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough !"
        );
        // msg.value = > stands for how much ethereum or how much native blockchain currency is sent
        // 1e18 == 1 *10 ** 18

        funders.push(msg.sender);
        //msg.sender
        // always avaliable global
        // = > the address of whoever calls the fund function

        addressToAmountFunded[msg.sender] = msg.value;

        // what is reverting?
        // undo any action before, and send remaining gas back
    }

    function withdraw() public {
        // goal : withdraw fund to do something , so need withdraw fund and delete msg.sender
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex = funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0; // addressToAmountFunded[msg.sender] = msg.value;
        }
        // reset the array
        funders = new address[](0);

        // actually withdraw the funds - send the funds back

        // 1.transfer
        // 2.send
        // 3.call

        // msg.sender = address
        // payable(msg.sender) = payable address = > 类似于一个容器
        // payable(msg.sender).transfer(address(this).balance);

        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "sender is not owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // if someone sends this contract ETH without calling the fund function

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

// all the functions insider of our library need to be internal
library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // 与项目外的合约交互需要两件事

        // 1.abi of the contract

        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000 eight decimal places associated

        return uint256(price * 1e10); // bez msg.value is uint 256
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // ethPrice : 1800_000000000000000000
        // 1ETH = 1_000000000000000000

        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // bez ethPrice * ethAmount have 36 decimals
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