// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./EthPrice.sol";

error Funding__NotOwner();

/// @title A contract to allow users to fund it
/// @author Anas Latique
/// @notice You can use this contract to collect funds from users and withdraw those funds.
/// @dev This contract uses Price Feeds from the Chainlink Oracle to calculate the price of ETH to determine the limit.
contract Funding {
  // using a library on the uint256 type
  using EthPrice for uint256;

  address immutable public fundingOwner;

  uint256 constant public MIN_USD = 10 * 1e18;

  address[] public funders;
  mapping (address => uint256) public funderToAmount;
  mapping (address => bool) public funderToExists;

  // the pricefeed
  AggregatorV3Interface public priceFeed;

  modifier ownerOnly () {
    if(fundingOwner != msg.sender) {
        revert Funding__NotOwner();
    }
    _;
  }

  constructor(address feedAddress) {
    priceFeed = AggregatorV3Interface(feedAddress);
    fundingOwner = msg.sender;
  }

  /// @notice Payable function and it's used to fund the contract.
  /// @dev Gets the current price of ETH in USD from a Chainlink Oracle and compares it with the limit.
  function fund() public payable {
    uint256 usdAmount = msg.value.getEthInUsd(priceFeed);
    require(usdAmount >= MIN_USD, "Not enough funds sent. Send more than $50 you cheap bastard.");

    funderToAmount[msg.sender] += msg.value;
    if(!funderToExists[msg.sender]) {
      funders.push(msg.sender);
      funderToExists[msg.sender] = true;
    }
  }

  /// @notice Withdraws the funds from the contract to the transaction (current function caller) sender.
  /// @dev Checks if the contract owner, is the transaction sender using a function modifier.
  function withdraw() public ownerOnly {
    // for loop in solidity, kinda same as JS
    address funder;
    address[] memory fundersCopy = funders;

    for(uint256 i = 0; i < fundersCopy.length; i++) {
        funder = fundersCopy[i];
        funderToAmount[funder] = 0;
    }

    // reset the array
    funders = new address[](0);

    // actually withdraw the amount from this contract to the original caller.
    // payable address is address that we can send Eth to.
    bool withdrawalResp = payable(msg.sender).send(address(this).balance);
    require(withdrawalResp, "The withdrawal did not go through.");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library EthPrice {
  function getPrice(AggregatorV3Interface priceFeed) view internal returns (uint256) {
    (
      /*uint80 roundID*/,
      int price,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = priceFeed.latestRoundData();
    return uint256(price * 1e10);
  }

  function getEthInUsd (uint256 ethValue, AggregatorV3Interface priceFeed) internal view returns (uint256) {
    uint256 ethPrice = getPrice(priceFeed);
    return (ethPrice * ethValue) / 1e18;
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