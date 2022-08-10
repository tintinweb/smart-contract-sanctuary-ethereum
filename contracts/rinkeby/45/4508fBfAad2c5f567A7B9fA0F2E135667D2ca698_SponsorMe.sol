// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SponsorMe {
    using PriceConverter for uint;
    uint public constant MIN_USD = 0 * 1e18; // 1 ETH == 1e18 Wei == 1000000000000000000 Wei.
    mapping(address => uint) public funds;
    address[] public funders;
    address public immutable owner;
    AggregatorV3Interface private chainLinkDataPriceFeed;

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not Owner !");
        _;
    }

    // Executes when Contract is deployed.
    constructor(address dataPriceFeedAddress) {
        chainLinkDataPriceFeed = AggregatorV3Interface(dataPriceFeedAddress);
        owner = msg.sender;
    }

    function sponsor() public payable {
        require(msg.value.usdPrice(chainLinkDataPriceFeed) > MIN_USD, "Didn't send enough ETH !!!");
        funders.push(msg.sender);
        funds[msg.sender] += msg.value;
    } 

    function withdraw() public payable onlyOwner {
        address[] memory fundersList = funders;

        for (uint i = 0; i < fundersList.length; i++) {
            funds[funders[i]] = 0;
        }
        
        funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "failed");
    }

    receive() external payable {
        sponsor();
    }

    fallback() external payable {
        sponsor();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // Chainlink Datafeed Contract Address - 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e.
    function ethMarketPrice(AggregatorV3Interface chainLinkDataPriceFeed) internal view returns (uint) {
        (, int price, , , ) = chainLinkDataPriceFeed.latestRoundData(); // ETH market val in USD without decimals.
        return uint(price * 1e10); // To Match length of 1e18 Wei.
    }

    function usdPrice(uint ethAmount, AggregatorV3Interface chainLinkDataPriceFeed) internal view returns (uint) {
        uint ethPrice = ethMarketPrice(chainLinkDataPriceFeed);
        return (ethPrice * ethAmount) / 1e18; // To Remove addition 18 decimals
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