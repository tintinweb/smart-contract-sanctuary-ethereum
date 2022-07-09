// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public PaytoAddress;
    address[] public funders;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    function payto() public payable {
        // mininum amount required; is 0.05 USD;
        uint256 mininumUSD = 5 * 10**16; //18-2 =16
        require(
            getConversionRate(msg.value) >= mininumUSD,
            "You need to send more Eth!!!"
        );
        PaytoAddress[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getversion() public view returns (uint256) {
        AggregatorV3Interface ethToUSDInterface = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return ethToUSDInterface.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface price_feed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = price_feed.latestRoundData();
        return uint256(answer);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = (getPrice() * ethAmount) / 10**18;
        return ethPrice;
    }

    modifier onlyOwnerFunct() {
        require(msg.sender == owner);
        _;
    }

    function withdrawl() public onlyOwnerFunct {
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 fundersindex = 0;
            fundersindex < funders.length;
            fundersindex++
        ) {
            address funder = funders[fundersindex];
            PaytoAddress[funder] = 0;
        }

        funders = new address[](0);
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