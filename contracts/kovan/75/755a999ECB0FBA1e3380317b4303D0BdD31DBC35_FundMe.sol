// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// 1. only send & transfer need payable, balance doesn't need.
//  payable(msg.sender).transfer(address(this).balance);
// 2. payable need convert.
//  address payable b; address a; b = payable(a); a = b;
// 3. functions must have payable, if transfer money.

contract FundMe {
    address payable public owner;
    AggregatorV3Interface priceFeed;
    mapping(address => uint256) funderMoneys;
    address[] funders;

    modifier money(uint256 dollarNum) {
        require(
            msg.value * getETHPrice() > (dollarNum * 10**26),
            "You need more money to fund!"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are Not owner, cannot take all money.");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
    }

    function fund() public payable money(10) {
        funderMoneys[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public payable {
        require(funderMoneys[msg.sender] >= 0, "no money to withdraw.");
        payable(msg.sender).transfer(funderMoneys[msg.sender]);
        funderMoneys[msg.sender] = 0;
    }

    function balance() public view returns (uint256) {
        return funderMoneys[msg.sender];
    }

    function takeAll() public payable onlyOwner {
        owner.transfer(address(this).balance);
        for (uint256 fIdx = 0; fIdx < funders.length; fIdx += 1) {
            funderMoneys[funders[fIdx]] = 0;
        }
        funders = new address[](0);
    }

    function getETHPrice() public view returns (uint256) {
        // (
        //     uint80 roundId,
        //     int256 answer,
        //     uint256 startedAt,
        //     uint256 updatedAt,
        //     uint80 answeredInRound
        // ) = priceFeed.latestRoundData();

        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer);
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