// SPDX-License-Identifier: MIT

pragma solidity >0.6;

import "AggregatorV3Interface.sol";

contract FundMe {
    address owner;
    address[] fundAddressList;
    AggregatorV3Interface price_feed;

    constructor(address _priceFeed) {
        owner = msg.sender;
        price_feed = AggregatorV3Interface(_priceFeed);
    }

    mapping(address => uint256) public fundAddressToAmount;

    function getUSDValue() public view returns (uint256) {
        (, int256 answer, , , ) = price_feed.latestRoundData();
        return uint256(answer) * 10**18 - uint256(price_feed.decimals());
    }

    function fund() public payable {
        uint256 USDVal = getUSDValue();
        uint256 minUSD = 50 * 10**18;
        bool addAddress = true;
        uint256 receivedUSD = (msg.value * USDVal) / (10**18);

        require(receivedUSD >= minUSD, "Not enough ETH sent.");

        for (uint256 i = 0; i < fundAddressList.length; i++) {
            if (fundAddressList[i] == msg.sender) addAddress = false;
        }
        if (addAddress) fundAddressList.push(msg.sender);
        fundAddressToAmount[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        return price_feed.version();
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You don't have the permissions to execute this call."
        );
        _;
    }

    function totalFunds() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < fundAddressList.length; i++) {
            total += fundAddressToAmount[fundAddressList[i]];
        }
        return total;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i < fundAddressList.length; i++) {
            fundAddressToAmount[fundAddressList[i]] = 0;
        }
        fundAddressList = new address[](0);
    }
}

pragma solidity >=0.4.24;

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