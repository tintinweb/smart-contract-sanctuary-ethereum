//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";

//https://ethereum.stackexchange.com/questions/99677/how-can-msg-sender-addressthis
//https://medium.com/swlh/getting-deep-into-evm-how-ethereum-works-backstage-ab6ad9c0d0bf
//https://betterprogramming.pub/learn-solidity-functions-ddd8ea24c00d

contract Fundme {
    uint256 public don;
    address public owner;

    constructor() {
        owner = address(this);
    }

    function fund() public payable {
        uint256 donate = (msg.value * price()) / (10**8);
        don = donate;
    }

    function getversion() public view returns (uint256) {
        AggregatorV3Interface newprice = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return newprice.version();
    }

    function price() public view returns (uint256) {
        AggregatorV3Interface newprice = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        (, int256 ans, , , ) = newprice.latestRoundData();
        return uint256(ans);
    }

    function withdraw() public payable {
        payable(msg.sender).transfer(address(this).balance);
    }

    function checkbalance() public view returns (uint256) {
        return address(this).balance;
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