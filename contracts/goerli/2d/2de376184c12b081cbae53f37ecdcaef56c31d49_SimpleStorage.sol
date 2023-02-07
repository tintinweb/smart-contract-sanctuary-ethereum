/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT
contract SimpleStorage
{
        uint256 FavN = 5;
        // sledeci broj se automatsji initilizuje na 0 sto je NULL vrednost za unitove
        uint256 public uninitialized;
        bool FavB = true;
        string FavS = "adfsafas";
        int256 FavMS = -20;
        address favA = 0x01061Df5cEb35374314871475e8814e6342E0EF5;
        bytes32 favB = "cat";
        mapping (string => uint256) public MapMap;
        struct Ljudi
        {
                string ime;
                uint256 broj;
        }
        Ljudi public Mare = Ljudi({ime: "Marko", broj: 16});
        Ljudi[] public listaLjudi;
        function sacuva(uint256 _omiljeniBroj) public 
        {
                uninitialized = _omiljeniBroj;
        }
        // view i pure ne menjaju stanje masine, svaka public variabla ima automatski view; pure radi matu i ispise rezultat ali niti cita niti pise datoteke
        function vrati() public view returns(uint256)
        {
                return uninitialized;
        }
        function mlatipraznuslamu() public pure returns(uint256)
        {
                uint256 petica = 5;
                return petica*petica + petica;
        }
        function dodajOsobu(string memory _ime, uint256 _omiljeniBroj) public
        // moze i bez ovog ime: i broj:, ali bolje je mozda specifirati kada ima puno promenljivih istog data tipa.
        // podatci mogu da se cuvaju ili u memory ili u storage. Ako ih cuvamo u memory oni su tu samo tokom egzekjusna; Storage persists posle exe
        // string u solidity nisu jedan od osnovnih tipova (uint,char,address), oni su zamaskirani array charova. String je object i kao takaqv mora biti u memory ili storage
        {
                listaLjudi.push(Ljudi({ime: _ime, broj: _omiljeniBroj}));
                MapMap [_ime] = _omiljeniBroj*3;
        }
}