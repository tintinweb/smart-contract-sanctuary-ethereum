// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract Arbeitsvertrag {
    AggregatorV3Interface internal priceFeed;

    address public owner;
    address payable[] public KontenArbeiter;

    //mapping (address => uint256) public keysArbeiter;

    constructor() {
        owner = msg.sender;
    }

    function einzahlen() public payable {
        require(msg.value > 0);
        require(msg.sender == owner);
    }

    function Auszahlen() public payable {
        require(
            address(this).balance > 0,
            "Der aktuelle Kontostand ist 0. Bitte den Ersteller des Vertrages kontaktieren"
        );
        require(
            KontenArbeiter.length == 3,
            "Es braucht min. 3 Leute fuer diese Arbeit"
        );
        //zahle jedem Arbeiter ein Drittel von der Gesamtsumme
        uint256 Lohn = address(this).balance / KontenArbeiter.length;
        for (uint256 i = 0; i < KontenArbeiter.length; i++) {
            KontenArbeiter[i].transfer(Lohn);
        }
    }

    function exist(address key) private view returns (bool) {
        for (uint256 i = 0; i < KontenArbeiter.length; i++) {
            if (KontenArbeiter[i] == key) {
                return true;
            }
        }
        return false;
    }

    function Bewerber(address payable key) public {
        require(
            KontenArbeiter.length < 3,
            "Wir haben schon genug Leute fuer diese Arbeit"
        );
        require(exist(key) == false, "Jede Person nur einmal");
        KontenArbeiter.push(key);
        if (KontenArbeiter.length == 3) {
            Auszahlen();
            delete KontenArbeiter;
        }
    }

    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331)
                .latestRoundData();
        return price;
    }
} //Ende Smart Contract Arbeitsvertrag

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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