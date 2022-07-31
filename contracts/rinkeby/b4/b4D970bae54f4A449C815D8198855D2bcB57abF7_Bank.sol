//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PriceConverter.sol";

contract Bank {
  using PriceConverter for uint256;

  uint256 public constant MINIMUMUSD = 7 * 1e18;

  address[] public accounts;

  mapping(address => uint256) private balances;

  event depositInfo(address, uint256);
  event depositBalances(uint256, uint256);
  event withdrawInfo(address, uint256);
  event withdrawBalances(uint256, uint256);

  AggregatorV3Interface public priceFeed;

  constructor(address priceFeedAddress) {
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  receive() external payable {
    deposit();
  }

  function deposit() public payable {
    uint256 oldBal = balances[msg.sender];
    require(
      msg.value.getConversionRate(priceFeed) > MINIMUMUSD,
      "No Value Sent!"
    );
    balances[msg.sender] += msg.value;

    // Checking to see if account exists before adding to accounts array.
    if (exists(msg.sender) == false) {
      accounts.push(msg.sender);
    }
    emit depositInfo(msg.sender, msg.value);
    emit depositBalances(oldBal, balances[msg.sender]);
  }

  function withdraw(uint256 _amount) public {
    uint256 oldBal = balances[msg.sender];
    require(balances[msg.sender] >= _amount, "Insufficent Funds!");
    balances[msg.sender] -= _amount;
    (bool sent, ) = payable(msg.sender).call{value: _amount}("");
    require(sent, "Withdrawal Failed!");
    emit withdrawInfo(msg.sender, _amount);
    emit withdrawBalances(oldBal, balances[msg.sender]);
  }

  function getBalanceInETH() public view returns (uint256) {
    return (balances[msg.sender]);
  }

  function getBalanceInUSD() public view returns (uint256) {
    uint256 balanceInUSD = (balances[msg.sender].getConversionRate(priceFeed));
    return (balanceInUSD);
  }

  function exists(address _account) public view returns (bool) {
    for (uint256 i = 0; i < accounts.length; i++) {
      if (accounts[i] == _account) {
        return true;
      }
    }
    return false;
  }
}

// 980,683 Original gas cost
// 960,941 After making MINIMUMUSD a constant variable

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  // No state variables inside of libraries
  // All functions must be internal

  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256 _price)
  {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price * 1e10);
  }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 price = getPrice(priceFeed);
    uint256 ethAmountInUsd = (price * ethAmount) / 1e18;
    return (ethAmountInUsd);
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