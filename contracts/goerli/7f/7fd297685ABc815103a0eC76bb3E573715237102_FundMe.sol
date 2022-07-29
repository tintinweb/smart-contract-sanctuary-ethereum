// SPDX-License-Identifier: MIT

////////////////////////////////
/// Lesson 7: hardhat Fund Me //
////////////////////////////////

pragma solidity ^0.8.0;

import "./PriceConverter.sol";

    error NotOwner();
    error TransferFailed();
    error NotEnoughFund();

// DEPLOYMENT
// 853726 initially
// 834215 with constant
// 810624 with constant and immutable
// 731755 with constant, immutable and custom error
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable owner;

    AggregatorV3Interface priceFeed;

    constructor(AggregatorV3Interface _priceFeedAddress) {
        owner = msg.sender;
        priceFeed = _priceFeedAddress;
    }

    function fund() public payable {
        if (msg.value.getConversionRate(priceFeed) < MINIMUM_USD) {
            revert NotEnoughFund();
        }
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() external onlyOwner {
        for (uint256 index = 0; index < funders.length; index++) {
            addressToAmountFunded[funders[index]] = 0;
        }

        funders = new address[](0);

        // There are 3 ways to transfer eth: transfer/send/call

        // transfer: uses max 2300 gas, throws error on failure
        // payable(msg.sender).transfer(address(this).balance);

        // send: uses max 2300 gas, returns bool if succesful;
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call: forward all gas or set gas, returns bool and data. It's cheaper (2100 gas?) but doesn't protect against reentrancy attacks. It's recommended when transfering ether and should be avoided when calling other functions.
        // solhint-disable-next-line avoid-low-level-calls
        (bool callSuccess,) = payable(msg.sender).call{value : address(this).balance}("");
        if (!callSuccess) {
            revert TransferFailed();
        }
    }

    modifier onlyOwner {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

////////////////////////////////
/// Lesson 7: Hardhat Fund Me //
////////////////////////////////

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Address for Rinkeby
library PriceConverter {
    function getPrice(AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        (,int256 price,,,) = _priceFeed.latestRoundData();
        return uint256(price * 1e10);
        // ETH in terms of USD
    }

    // How much worth in USD is passed eth
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        return (ethPrice * ethAmount) / 1e18;
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