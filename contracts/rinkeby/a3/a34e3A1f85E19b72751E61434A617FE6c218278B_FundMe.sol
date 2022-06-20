// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    address public owner;
    address[] public funders;

    constructor() public {
        owner = msg.sender;
    }

    // address public currSender = msg.sender;

    mapping(address => uint256) public addressToAmount;

    function fund() public payable {
        // $1
        uint256 minUSD = 1 * 10**18;
        require(convertEthUsd(msg.value) >= minUSD, "SPEND AT LEAST $1");

        addressToAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // function getVersion() public view returns(uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    //     return priceFeed.version();
    // }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        // (
        //     uint80 roundId,
        //     int256 answer,
        //     uint256 startedAt,
        //     uint256 updatedAt,
        //     uint80 answeredInRound
        // ) = priceFeed.latestRoundData();
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(10**10 * answer);
        // multiply by 10^10 for some reason instead of 10^9
    }

    // 1 eth = 10^18 wei
    // 1 eth = 10^9 gwei

    //amountPayed in Gwei
    function convertEthUsd(uint256 amountPayed) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (amountPayed * ethPrice) / 10**18;
        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        // require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            addressToAmount[funders[funderIndex]] = 0;
        }
        funders = new address[](0);
    }

    // function getSender() public view returns(address) {
    //     return msg.sender;
    // }

    // function assertOwnerSender() public view returns(bool) {
    //     return owner == getSender();
    // }

    // function getContractBalance() public onlyOwner view returns(uint256) {
    //     return address(this).balance;
    // }
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