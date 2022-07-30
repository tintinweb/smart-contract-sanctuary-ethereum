// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

contract Funds {
    struct Details {
        uint256 amount;
        string name;
        address sended;
    }

    Details[] public vork;
    mapping(address => uint256) public Jio;

    function hiro(string memory naming) public payable {
        vork.push(
            Details({amount: msg.value, name: naming, sended: msg.sender})
        );
        Jio[msg.sender] += msg.value;
    }

    function get_ver() public view returns (uint256) {
        AggregatorV3Interface yoos = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return yoos.version();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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