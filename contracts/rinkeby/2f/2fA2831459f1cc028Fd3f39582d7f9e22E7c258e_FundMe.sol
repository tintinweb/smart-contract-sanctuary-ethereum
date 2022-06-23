// Send funds to contract
// Withdraw funds from contract
// Fix minimum value of fund to send to contract

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

// 822,736
// 800,890
error NotOwner();

contract FundMe {
    uint256 public constant MINIMUM_FUND = 5 * 1e18;
    using PriceConverter for uint256;

    AggregatorV3Interface public priceFeed;

    address public immutable i_Owner;

    constructor(address priceFeedAddress) {
        i_Owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    function fund() public payable {
        // require(convertToDollars(msg.value) > MINIMUM_FUND, "Didn't send enough funds.");
        require(
            msg.value.convertToDollars(priceFeed) > MINIMUM_FUND,
            "Not enough funds"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function Withdraw() public admin {
        // reset funders mapping
        for (
            uint256 funderIndex = 0;
            funderIndex > funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset funders array
        funders = new address[](0);
        // send funds to another address
        // funds can only be sent to payable address types
        // Three means of sending funds:
        // // > transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // > send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // > call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier admin() {
        // require(msg.sender == i_Owner, "Administrator only");
        if (msg.sender != i_Owner) {
            revert NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getEthInDollars(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // interact with the ORACLE to get latest market eth value in dollars
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 ethValueInDollars, , , ) = priceFeed.latestRoundData();

        return uint256(ethValueInDollars * 1e10);
    }

    function convertToDollars(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethInDol = getEthInDollars(priceFeed);
        return (ethAmount * ethInDol) / 1e18;
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