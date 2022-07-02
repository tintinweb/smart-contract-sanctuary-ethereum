// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./PriceConverter.sol";

contract FundMe {
    error NotOwner();

    using PriceConverter for uint;

    address[] public funders;

    mapping(address => uint) public amountFunded;

    uint public constant MINIMUM_USD = 50 * 10**18;

    address public immutable ContractOwner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        ContractOwner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function Fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Unsuficient Amount"
        );
        funders.push(msg.sender);
        amountFunded[msg.sender] = msg.value;
    }

    // function Fund() payable public {
    //     require(msg.value >= 50, "Unsuficient Amount");
    //     funders.push(msg.sender);
    //     amountFunded[msg.sender] = msg.value;
    // }

    function Balance() public view returns (uint) {
        return address(this).balance;
    }

    function Withdraw() public contractOwnerOnly {
        for (uint i; i < funders.length; i++) {
            address funder = funders[i];
            amountFunded[funder] = 0;
        }
        funders = new address[](0);

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transaction Failed");
    }

    modifier contractOwnerOnly() {
        // require(msg.sender == ContractOwner, "Chor! Chor! Chor!");
        if (msg.sender != ContractOwner) {
            revert NotOwner();
        }
        _;
    }

    receive() external payable {
        Fund();
    }

    fallback() external payable {
        Fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint)
    {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint(price * 1e10);
        //ETH in USD
    }

    function getConversionRate(uint ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint)
    {
        uint ethPrice = getPrice(priceFeed);
        uint ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
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