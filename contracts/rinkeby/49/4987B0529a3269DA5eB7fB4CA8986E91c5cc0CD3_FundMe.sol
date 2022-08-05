// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

contract FundMe
{
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    AggregatorV3Interface public priceFeed;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable owner;

    constructor(address priceFeedAddress)
    {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable
    {
        // We want to be able to set a minimum fund amount in USD
        // how do we send ETH to this contract?
        // 1e18 is 1 * 10^18 wei
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner
    {

        for (uint funderIndex = 0; funderIndex < funders.length; ++funderIndex)
        {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the array
        funders = new address[](0);

        // withdraw the funds
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner
    {
        // require(msg.sender == owner, "Sender is not owner!");
        // more gas efficient
        if (msg.sender != owner)
        {
            revert NotOwner();
        }
        _;
    }

    receive() external payable
    {
        fund();
    }
    fallback() external payable
    {
        fund();
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter
{
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256)
    {
        (, int price, , , ) = priceFeed.latestRoundData();
        // 1700.00000000 (8 decimal places)
        // convert to 18 decimal places and to a uint256
        return uint256(price * 1e10); // 1 * 10^10
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        // Always multiply before you divide
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}