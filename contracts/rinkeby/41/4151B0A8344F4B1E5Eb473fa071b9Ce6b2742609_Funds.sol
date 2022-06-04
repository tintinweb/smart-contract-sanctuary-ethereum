// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract Funds {
    //When mapping is initialised all the keys are initialised.
    mapping(address => uint256) public fundsArray;
    address[] public funders;
    address public owner;

    constructor() public {
        //This msg.sender is no one but the address from which the contract was deployed/called first.
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minValueUsd = 1 * 10**18;
        require(
            convertToUsd(msg.value) >= minValueUsd,
            "Veer g paise ghat je!"
        );
        fundsArray[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface Aggregator = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return Aggregator.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface Aggregator = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = Aggregator.latestRoundData();
        return uint256(answer * 10000000000); // for getting answer in 18 decimals.
    }

    function convertToUsd(uint256 ethAmount) public view returns (uint256) {
        uint256 currentPrice = getPrice();
        uint256 finalValue = (currentPrice * ethAmount) / (10**18);
        return finalValue;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Chor kahin ka");
        _;
    }

    function withdraw() public payable onlyOwner {
        // So that only the ower could withdraw the ammount
        //require(msg.sender == owner, "Chor kahin ke");  but we have an another way of doing it too
        // i.e. by modifiers.
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint80 funderIndex = 0;
            funderIndex > funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            fundsArray[funder] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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