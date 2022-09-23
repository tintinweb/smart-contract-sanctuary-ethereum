// working:
// Get funds from donors
// withdraw funds - only for owner
// set mimiumum value for funds to be sent. - in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    // list of functions to be implemented
    // fund()

    // const: doesn't take up space, so good on gas
    // naming convention: all caps
    uint256 public constant MIN_USD = 5 * 1e18;
    mapping(address => uint256) public addressToamountFunded;
    address[] public funders;

    // naming convention for immutable append i_ at the beginning
    address public immutable i_owner;
    AggregatorV3Interface priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Minimum donation amount - 0.001 ETH"
        );
        funders.push(msg.sender);
        addressToamountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // reset the mapping of funders
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToamountFunded[funder] = 0;
        }
        // reset the funders array
        funders = new address[](0);
        // withdraw
        /*{
        Three diff. ways:
        1. transfer
        2. send 
        3.call}
        */

        // transfer
        // msg.sender : address
        // so type cast into payable address
        // payable(msg.sender).transfer(address(this).balance);

        // //send
        // bool sendSuccess=payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "send failed");

        // call
        // low-level
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, NotOwner());
        if (msg.sender != i_owner) {
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

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ineracting with external contract, so we need,
        // 1. ABI of the contract, and
        // 2. The adress of the contract. 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 amountInEth,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 amountInUsd = (ethPrice * amountInEth) / 1e18;
        return amountInUsd;
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