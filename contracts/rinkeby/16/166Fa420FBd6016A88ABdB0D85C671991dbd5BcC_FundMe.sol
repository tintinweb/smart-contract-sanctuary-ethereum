// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe {
    uint256 minimimUsd = 5;
    address payable public owner;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function fund() public payable {
        require(
            getValueInUsd(msg.value) >= minimimUsd * 10**18,
            "You need to send at least 5$."
        );

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            delete addressToAmountFunded[funders[i]];
        }
        funders = new address[](0);
    }

    // 18 decimals
    function getEthUsdPrice() public view returns (uint256) {
        // Kovan   0x9326BFA02ADD2366b30bacB125260Af641031331
        // Rinkeby 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10**10);
    }

    // 18 decimals
    function getValueInUsd(uint256 ethValue) public view returns (uint256) {
        return (ethValue * getEthUsdPrice()) / (10**18);
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