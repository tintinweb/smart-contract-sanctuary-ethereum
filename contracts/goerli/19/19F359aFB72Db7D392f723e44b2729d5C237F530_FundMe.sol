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
import "./PriceConverter.sol";
error NotOwner();

contract FundMe {
    using PriceConverter for uint256;


    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public /* immutable */ i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    AggregatorV3Interface public PriceFeed;

    constructor(address PriceFeedAdress) {
        i_owner = msg.sender;
        PriceFeed = AggregatorV3Interface(PriceFeedAdress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(PriceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    modifier onlyOwner {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }
    
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface PriceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = PriceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface PriceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(PriceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }
}