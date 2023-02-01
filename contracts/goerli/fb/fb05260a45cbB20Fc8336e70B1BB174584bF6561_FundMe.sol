// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe {
    address public owner;
    mapping(address => uint256) public addressToAmount;
    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        require (
            getConversationalRate(msg.value) >= 50,
            "You need to spend more ETH!"
        );
        addressToAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner () {
        require (owner == msg.sender, "You need to be contract owner");
        _;
    }

    function withdraw() public onlyOwner payable {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 funderIndex=0;funderIndex<funders.length;funderIndex++)
            addressToAmount[funders[funderIndex]] = 0;
        funders = new address[](0);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface price = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (, int256 answer,,,) = price.latestRoundData();
        return uint256(answer / int256(10 ** price.decimals()));
    }

    function getConversationalRate(uint256 amount) public view returns (uint256) {
        uint256 price = getPrice();
        return price * amount / 10**18;
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