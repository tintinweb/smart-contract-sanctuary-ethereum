/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract VentureFund {

    struct Anteilseigner {
        bool gewaehlt;
        uint anteil;
    }
    mapping(address => Anteilseigner) public anteilseigner; 

    struct Startup {
        address adresse;
        uint stimmen;
    }
    Startup[] public startups; 

    uint public mindestsumme;
    uint public fondvolumen;

    constructor(address[] memory startupAdressen, uint _mindestsumme) {
        mindestsumme = _mindestsumme;
        for (uint i = 0; i < startupAdressen.length; i++) {
            startups.push(Startup({
                stimmen: 0,
                adresse: startupAdressen[i]
            }));
        }
    }

    // Lösung: Diese Funktion ermöglicht es, zu investieren
    function investieren () public payable { 
        anteilseigner[msg.sender].anteil += msg.value;
        fondvolumen += msg.value;
    }

    function abstimmen(uint startupNummer) public {    
        Anteilseigner storage sender = anteilseigner[msg.sender]; 
        // Mögliche Lösung:
        require(sender.anteil != 0, "Sender hat kein Recht abzustimmen.");
        require(!sender.gewaehlt, "Sender hat bereits gewaehlt.");
        require(startupNummer < startups.length, "Startupnummer nicht vorhanden.");
        sender.gewaehlt = true;
        startups[startupNummer].stimmen += sender.anteil;
    }

    function auszaehlen() public view                   
            returns (uint gewinner)
    {
        // Mögliche Lösung:
        uint gewinnerstimmen = 0;
        for (uint s = 0; s < startups.length; s++) {
            if (startups[s].stimmen > gewinnerstimmen) {
                gewinnerstimmen = startups[s].stimmen;
                gewinner = s;
            }
        }
    }

    function auszahlen() public 
    {
        require(fondvolumen >= mindestsumme, "Noch nicht genug eingesammelt.");
        payable(startups[auszaehlen()].adresse).transfer(fondvolumen);
    }
}