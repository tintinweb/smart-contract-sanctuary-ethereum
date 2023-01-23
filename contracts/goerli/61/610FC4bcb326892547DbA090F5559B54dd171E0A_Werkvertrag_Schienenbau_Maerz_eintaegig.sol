// SPDX-License-Identifier: MIT

/*

Guten Tag,
wir benoetigen fÃ¼r unsere Baustelle noch drei Hilfsarbeiter zum Schotter ausschuetten.
Arbeitszeit: 1 Werktag; Arbeitsbeginn um 8.00 Uhr am 06.03.2023.
Es handelt sich um einen Werkvertrag, die Arbeit ist zu Ende wenn der vorgesehene Schotter ausgeschuettet wurde.
Der Lohn betrÃ¤gt 1/3 vom Gesamtkontostand dieses Vertrages.
Dieser Vertrag bleibt so lange offen bis 3 Arbeiter gefunden wurden.
Wurden bis 27.02.2023 nicht genÃ¼gend Leute gefunden, betrachten Sie diesen Vertrag als gegenstandslos.

Die Funktion Counter, gibt Auskunft Ã¼ber die aktuelle Anzahl an Bewerbern.
Durch klick auf "Bewerben" koennen Sie sich mit ihrem public key fÃ¼r den Job bewerben.
Durch klick auf "Abmelden" koennen Sie sich wieder vom Vertrag abmelden.
Durch klick auf "Lohn" koennen Sie sich ihren Lohn fÃ¼r diese Taetigkeit in EUR anzeigen lassen.
Bei unzufriedenstellender Arbeit oder Nichterscheinen, werden Sie von diesem Vertrag ausgeschlossen und kÃ¶nnen sich kuenftig nicht mehr bewerben.

*/
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract Werkvertrag_Schienenbau_Maerz_eintaegig {
    AggregatorV3Interface internal priceFeed;

    address public owner;
    address payable[] private KontenArbeiter;
    mapping(address => uint256) private keysArbeiter;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
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
            "Es braucht mindestens 3 Leute fuer diese Arbeit"
        );
        //zahle jedem Arbeiter ein Drittel von der Gesamtsumme
        uint256 Lohn = address(this).balance / KontenArbeiter.length;

        for (uint256 i = 0; i < KontenArbeiter.length; i++) {
            KontenArbeiter[i].transfer(Lohn);
        }
    }

    function AnzahlBewerber() public view returns (uint256) {
        uint256 Anz = KontenArbeiter.length;
        return Anz;
    }

    function exist(address key) private view returns (bool) {
        for (uint256 i = 0; i < KontenArbeiter.length; i++) {
            if (KontenArbeiter[i] == key) {
                return true;
            }
        }
        return false;
    }

    function Bewerben() public {
        require(
            KontenArbeiter.length < 3,
            "Wir haben schon genug Leute fuer diese Arbeit"
        );
        require(exist(msg.sender) == false, "Jede Person nur einmal");
        require(
            address(this).balance > 0,
            "Vertrag ist nicht aktiv, schauen Sie ein anderes Mal vorbei"
        );
        KontenArbeiter.push(payable(msg.sender));
        if (KontenArbeiter.length == 3) {
            Auszahlen();
            delete KontenArbeiter;
        }
    }

    //schiebe die gesuchte adresse an die letzte Stelle des Arrays und lÃ¶sche diese indem der Array um 1 verkÃ¼rzt wird
    function loeschen(uint256 index) private {
        require(index < KontenArbeiter.length);
        KontenArbeiter[index] = KontenArbeiter[KontenArbeiter.length - 1];
        KontenArbeiter.pop();
    }

    function Abmelden() public {
        require(exist(msg.sender) == true, "Sie sind keiner unserer Bewerber");
        for (uint256 i = 0; i < KontenArbeiter.length; i++) {
            if (KontenArbeiter[i] == msg.sender) {
                loeschen(i);
            }
        }
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
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