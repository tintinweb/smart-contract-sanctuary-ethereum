//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;

    //Making Constant for Gas Optimizations
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address public immutable i_owner;

    error notOwner();

    AggregatorV3Interface priceFeed;

    //constructor
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //List of Funders with amount
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunders;

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        );
        funders.push(msg.sender);
        addressToAmountFunders[msg.sender] += msg.value;
    }

    function withdraw() public onlyi_owner {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunders[funder] = 0;
        }
        //reset the funders array
        funders = new address[](0);

        //Actual withdraw of funds
        // using call function

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyi_owner() {
        // require(i_owner ==  msg.sender, "You ain't the i_owner");
        if (i_owner != msg.sender) revert notOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        
        (, int256 price, , , ) = priceFeed.latestRoundData(); //returns eth in usd
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 _ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 convertedPrice = (_ethAmount * ethPrice) / 1e18;
        return convertedPrice;
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