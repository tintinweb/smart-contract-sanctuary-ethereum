/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

contract DataStorage {
    string vorname;
    string nachname;
    string wantDonate;
    string dontwantDonate;
    // Ist string wirklich bester Datentyp für birthdate?
    // Eingabe soll wie folgt aussehen: 01.01.1990
    string birthdate;
    bool donateYesOrNo;

    function store(
        string memory _vorname,
        string memory _nachname,
        string memory _wantDonate,
        string memory _dontwantDonate,
        string memory _birthdate,
        bool _donateYesOrNo // ist Public hier wirklich korrekt?
    ) public {
        vorname = _vorname;
        nachname = _nachname;
        wantDonate = _wantDonate;
        dontwantDonate = _dontwantDonate;
        birthdate = _birthdate;
        donateYesOrNo = _donateYesOrNo;
        // Alterüberprüfung bei Smart Contract zu spät
        // Diese muss früher passieren, schon auf Webseite

        //if (donateYesOrNo = true) {
        //wantDonate = "-";
        //dontwantDonate = "-";
        //} else wantDonate = _wantDonate;
        //dontwantDonate = _dontwantDonate;
    }

    function read()
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            bool
        )
    {
        // Ausgabe-Funktion verschlüsseln
        return (
            vorname,
            nachname,
            wantDonate,
            dontwantDonate,
            birthdate,
            donateYesOrNo
        );
    }

    // function delete for changing opinio or whatever
    // https://stackoverflow.com/questions/71330577/solidity-correct-way-to-insert-read-and-delete-data-into-smart-contract
    // https://medium.com/asecuritysite-when-bob-met-alice/deleting-data-from-a-smart-contract-182b0e9e09fe
}