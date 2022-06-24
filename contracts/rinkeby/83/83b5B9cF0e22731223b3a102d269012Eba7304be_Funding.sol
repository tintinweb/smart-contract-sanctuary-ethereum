// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./EthPrice.sol";

error NotOwner();

// funding campaign
contract Funding {
  // using a library on the uint256 type
  using EthPrice for uint256;

  address immutable public fundingOwner;

  // make the function payable
  uint256 constant public MIN_USD = 10 * 1e18;

  address[] public funders;
  mapping (address => uint256) public funderToAmount;
  mapping (address => bool) public funderToExists;

  // the pricefeed
  AggregatorV3Interface priceFeed;

  constructor(address feedAddress) {
    priceFeed = AggregatorV3Interface(feedAddress);
    fundingOwner = msg.sender;
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }

  function fund() public payable {
    uint256 usdAmount = msg.value.getEthInUsd(priceFeed);
    require(usdAmount >= MIN_USD, "Not enough funds sent. Send more than $50 you cheap bastard.");

    funderToAmount[msg.sender] += msg.value;
    if(!funderToExists[msg.sender]) {
      funders.push(msg.sender);
      funderToExists[msg.sender] = true;
    }
  }

  function withdraw() public ownerOnly {
    // for loop in solidity, kinda same as JS
    for(uint256 i = 0; i < funders.length; i++) {
        address funder = funders[i];
        funderToAmount[funder] = 0;
    }

    // reset the array
    funders = new address[](0);

    // actually withdraw the amount from this contract to the original caller.
    // payable address is address that we can send Eth to.
    bool withdrawalResp = payable(msg.sender).send(address(this).balance);
    require(withdrawalResp, "The withdrawal did not go through.");
  }

  modifier ownerOnly () {
    // require((fundingOwner == msg.sender), "You are not the owner.");
    if(fundingOwner != msg.sender) {
        revert NotOwner();
    }
    _;
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