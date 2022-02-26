// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public funders;
    address[] fundersArray;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        require(
            (msg.value * getEthPrice()) / 1000000000000000000 >= 50 * 10**18,
            "You need to spend more ETH"
        );
        funders[msg.sender] += msg.value;
        fundersArray.push(msg.sender);
    }

    function getEthPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10**10);
    }

    modifier ownerOnly() {
        require(owner == msg.sender);
        _;
    }

    function withdraw() public payable ownerOnly {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 index = 0; index < fundersArray.length; index++) {
            funders[fundersArray[index]] = 0;
        }
        fundersArray = new address[](0);
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