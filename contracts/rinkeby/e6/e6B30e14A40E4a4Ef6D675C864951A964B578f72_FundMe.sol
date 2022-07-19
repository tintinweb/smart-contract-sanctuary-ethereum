// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

// gas : 1015043
error notOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    // called after the contract is deployed in the blockchain
    // msg.sender inside the constructor is whoever deployed the contract

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
        // msg.value has 18 decimal, value is in Wei
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the funders
        funders = new address[](0);

        // withdraw the funds

        // msg.sender = address
        // payable(msg.sender) = payable address

        // method 1: using transfer  (autmatically will revert if the transaction fails - e.g. gas limit reached)
        // payable(msg.sender).transfer(address(this).balance);

        // method 2: using send ( returns a boolean of result, we need to use 'require' to revert the transaction)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // method 3: call ( low level and very powerfull)
        // empty "" means we are not calling any funtion, but inside the {} we are passing the value
        // originally returns (bool callSuccess, bytes memory dataReturned), but we only need the first.
        // no capped gas
        // Currently, this is the recommended method
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    //  _; means doing the rest of the code
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not the owner of this contract");
        if (msg.sender != i_owner) {
            revert notOwner();
        }
        _;
    }

    function test() public view returns (uint256) {
        return PriceConverter.getPrice(priceFeed);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// Get funds from users
// withdraw funds
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // price has 8 decimals, we need to convert this to 18 decimals to match Wei decimals
        return uint256(price * 1e10); // 1e10 means 1**10 = 10000000000
    }

    function getVersion(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Explanation:
        // ETH price/USD = 3000_000000000000000000    <= $3,000 with 18 decimals
        // if ethAmount = 1_000000000000000000  <= 1 ETH in wei
        // then coversion rate would b 3k USD

        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
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