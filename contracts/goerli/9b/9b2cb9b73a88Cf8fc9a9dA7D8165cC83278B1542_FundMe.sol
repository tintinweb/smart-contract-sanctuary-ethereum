// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;

    uint256 constant MIN_USD = 50;
    address [] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address immutable i_owner;
    address priceFeed;

    constructor (address feed) {
        priceFeed = feed;
        i_owner = msg.sender;
    }
    function fund() payable public {
        require(msg.value.getConversionRate(priceFeed) > MIN_USD, "Eth amount is less than $50");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }
    function withdraw() public onlyOwner {
        for(uint i=0; i<funders.length; i++) {
            addressToAmountFunded[funders[i]] = 0;
        }
        funders = new address [](1);
        bool sendSuccessful = payable(msg.sender).send(address(this).balance);
        require(sendSuccessful, "withdrawal unsuccessful");

    }

    modifier onlyOwner () {
        require(msg.sender == i_owner, "withdraw function is not called by the owner");
        _;
    }
    receive() payable external{
        fund();
    }
    fallback() payable external{
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getConversionRate(uint256 ethAmount, address feed) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feed);
        (, int price,,,) = priceFeed.latestRoundData();
        return (uint256 (price))*ethAmount/1e26;
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