// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// meisten kommentare gelöscht und nur im remix

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    // wird hier als global var deklariert, und im constructor initialisiert
    AggregatorV3Interface public priceFeed; // hier findet das refactoring fürs mocking statt

    constructor(address priceFeedAddress) {
        // jetzt ist die pricefeedAddress änderbar, je nachdem auf welche chain wir uns gerade befinden
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress); // initialisiert
    }

    function fund() public payable {
        //übergibt den pricefeed der getconversionRate function
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough!"); //msg.value als erster Parameter in Methode von Library Function
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // erwartet als arg einen price feed und ist nicht mehr hardcoded
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // das wurde jetzt durch pricefeed var variable gemacht anstatt hardcoded
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (, int256 price, , , ) = priceFeed.latestRoundData(); // hier wird vom im constructor eingetragenen pricefeed finnally der preis aufgerufen
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed); // übergibt pricefeed der getPrice Function
        uint256 ethAmountinUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountinUsd;
    }
}