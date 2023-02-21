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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import './PriceConverter.sol';

error FundMe__NotOwner();

/**
 * @title A contract for crowdfunding
 * @author jmrg90
 * @notice This contract is a demo sample
 * @dev This implements priceFeeds as our library
 */
contract FundMe {
  using PriceConverter for uint256;

  uint256 public constant MINIMUM_USD = 50 * 1e18;
  address[] private s_funders;
  mapping(address => uint256) private s_addressToAmountFunded;
  address private immutable i_owner;
  AggregatorV3Interface private s_priceFeed;

  modifier only_owner() {
    // The "if" block is more gas efficient than the "require" one.
    // require(msg.sender == i_owner, "Sender is not i_owner");
    if (msg.sender != i_owner) {
      revert FundMe__NotOwner();
    }
    _;
  }

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  /**
   * @notice This function funds this contract
   * @dev This implements price feeds as our library
   */
  function fund() public payable {
    require(
      msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
      "Didn't send enough"
    );
    s_funders.push(msg.sender);
    s_addressToAmountFunded[msg.sender] += msg.value;
  }

  function withdraw() public only_owner {
    for (uint256 i = 0; i < s_funders.length; i++) {
      address funder = s_funders[i];
      s_addressToAmountFunded[funder] = 0;
    }

    s_funders = new address[](0);

    // Transfer: limited to 2300 gas, automatically reverts if failed, throws an error.
    // payable(msg.sender).transfer(address(this).balance);
    // Send: also limited to 2300 gas, does nont revert if failed unless checked with "required", returns a bool
    // bool sendSuccess = payable(msg.sender).send(address(this).balance);
    // require(sendSuccess, "Send failed");
    // Call: doesn't limit gas, doesn't revert changes, returns a bool and transaction data in bytes. RECOMMENDED METHOD.
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }('');
    require(callSuccess, 'Call failed');
  }

  function cheaperWithdraw() public payable only_owner {
    // Reading from memory is way cheaper (in gas) than reading from storage
    address[] memory funders = s_funders;

    for (uint256 i = 0; i < funders.length; i++) {
      address funder = funders[i];
      s_addressToAmountFunded[funder] = 0;
    }

    s_funders = new address[](0);
    (bool success, ) = i_owner.call{value: address(this).balance}('');
    require(success);
  }

  function getOwner() public view returns (address) {
    return i_owner;
  }

  function getFunder(uint256 index) public view returns (address) {
    return s_funders[index];
  }

  function getAddressToAmountFunded(
    address funder
  ) public view returns (uint256) {
    return s_addressToAmountFunded[funder];
  }

  function getPriceFeed() public view returns (AggregatorV3Interface) {
    return s_priceFeed;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

library PriceConverter {
  function getPrice(
    AggregatorV3Interface priceFeed
  ) internal view returns (uint256) {
    (, int256 price, , , ) = priceFeed.latestRoundData();

    return uint256(price * 1e10); // Ether has 8 decimals and Gwei has 18, so we need to multiply the Ether price 1e10 to match Gwei.
  }

  function getVersion(
    AggregatorV3Interface priceFeed
  ) internal view returns (uint256) {
    return priceFeed.version();
  }

  function getConversionRate(
    uint256 ethAmount,
    AggregatorV3Interface priceFeed
  ) internal view returns (uint256) {
    uint256 ethPrice = getPrice(priceFeed);

    return (ethPrice * ethAmount) / 1e18;
  }
}