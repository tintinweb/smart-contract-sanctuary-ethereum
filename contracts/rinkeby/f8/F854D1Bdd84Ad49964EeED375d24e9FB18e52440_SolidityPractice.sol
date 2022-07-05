/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

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

// File: contracts/SolidityPractice.sol

contract SolidityPractice {
    event Log(uint256 number1);

    uint256 num;

    function testAssignToStateVariable(uint256 _amount) external returns (uint256) {
        num = _amount;

        return num;
        // require(cToken.mint(_amount) == 0, "mint failed");
    }

    function testReturnParamater(uint256 _amount) external pure returns (uint256) {
        return _amount;
    }

    function testGetFromState() external view returns (uint256) {
        return num;
    }
}