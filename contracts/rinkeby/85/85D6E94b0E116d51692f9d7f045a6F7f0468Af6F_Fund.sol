//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract Fund {
    address public owner;
    address[] public funders;
    mapping(address => uint256) public addressToValue;

    uint256 usdLim = 77;

    modifier adminOnly() {
        require(msg.sender == owner, "Only admin is allowed to withdraw money");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function putMoney() public payable {
        funders.push(msg.sender);
        addressToValue[msg.sender] += msg.value;
    }

    function minAmountGwei() public view returns (uint256) {
        return (usdLim * 10**9) / (getRate() / 10**8);
    }

    function putMoney77() public payable {
        require(
            convertEthToUsd(msg.value) >= usdLim * 10**9,
            "Not enough money!"
        );
        funders.push(msg.sender);
        addressToValue[msg.sender] += msg.value;
    }

    function getRate() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/
            ,
            ,

        ) = /*uint timeStamp*/
            /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
        return uint256(price); //303231702935
    }

    function convertEthToUsd(uint256 _EthValue) public view returns (uint256) {
        return (_EthValue * getRate()) / 10**17; //price in 10**8 + gwei = 10 ** 9
    }

    function sendMoneyToAdmin() public payable adminOnly {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 arrayIndex = 0;
            arrayIndex < funders.length;
            arrayIndex++
        ) {
            addressToValue[funders[arrayIndex]] = 0;
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