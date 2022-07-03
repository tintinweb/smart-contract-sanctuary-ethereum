// SPDX-License-Identifier: MIT

// run yarn solhint contracts/*.sol to find and fix problems in code
// goals: get funds from users, withdraw funds, set a minimum funding value in usd

pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    // by adding the keyword "using" we could give any uint256 within the FundMe contract the libraries functions
    // and pass the uint256 as the first parameter of that function.

    // constant and immutable are good gas savers if youre only setting your variables once
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier isOwner() {
        // require(msg.sender == i_owner, "Only owner can withdraw.");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    function fund() public payable {
        // require(getConversionRate(msg.value) >= minimumUsd, "Didn't send enough!");
        // msg.value fills the first param slot for getConversionRate(). if the function took two params, then you would
        // have to put something in the brackets.
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public isOwner {
        //funderIndex = funderIndex + 1 === funderIndex++
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        // type casting msg.sender
        // msg.sender = address
        // payable(msg.sender) = payable address
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Call failed");
    }

    // what happens if someone sends ETH without using fund()? (so we cant keep track of their address)
    // -> recieve() and fallback()

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
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // interacting with an external contract, so need abi and address of that contract
        // address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        (, int256 price, , , ) = priceFeed.latestRoundData(); // eth in terms of usd
        // 1,216.67000000
        // need to convert int256 into uint256 (not all types are convertable)
        return uint256(price * 1e10); // 1*10 == 10000000000 (to get the same amount of decimal places)
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    // function getVersion() internal view returns(uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    //     return priceFeed.version();
    // }
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