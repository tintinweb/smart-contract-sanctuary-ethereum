// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

contract FundMe {
    AggregatorV3Interface internal priceFeed;

    uint256 public minDepositValueinUSD;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        minDepositValueinUSD = 50 * 10**18;
        owner = msg.sender;
    }

    mapping(address => uint256) public addressToFunds;

    function fund() public payable {
        require(
            getUsdAmount(msg.value) >= minDepositValueinUSD,
            "50USD minimum"
        );
        addressToFunds[msg.sender] += msg.value;
    }

    function withdraw() public payable onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * 10**10;
    }

    function getUsdAmount(uint256 ethAmount) public view returns (uint256) {
        uint256 ethInUsd = getPrice(); // (eth/usd * 10^7) / 10^(7+18)
        return (ethAmount * ethInUsd) / 10**18; // eth = wei * 10^18
    }

    function getPFVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPFDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    function getPFDescription() public view returns (string memory) {
        return priceFeed.description();
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