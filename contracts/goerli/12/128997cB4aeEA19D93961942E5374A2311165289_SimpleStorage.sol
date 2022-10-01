// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 lempiNumero;
    string lempiVari;

    struct Ihmiset {
        uint256 lempiNumero;
        string lempiVari;
        string nimi;
    }
    // Tehdään ihmiset-structista lista johon voi lisätä ihmisiä
    Ihmiset[] public ihmiset;

    mapping(string => uint256) public nimenKauttaLempiNumeroon;
    mapping(string => string) public nimenKauttaLempiVariin;


    function tallenna(uint256 _lempiNumero) public {
        lempiNumero = _lempiNumero;
    }
    function tallennaVari(string memory _lempiVari) public {
        lempiVari = _lempiVari;
    }

    function nouda() public view returns (uint256) {
        return lempiNumero;
    }
    function noudaVari() public view returns (string memory) {
        return lempiVari;
    }

    function lisaaIhminen(string memory _nimi, uint256 _lempiNumero, string memory _lempiVari) public {
        ihmiset.push(Ihmiset(_lempiNumero, _lempiVari, _nimi));
        nimenKauttaLempiNumeroon[_nimi] = _lempiNumero;
        nimenKauttaLempiVariin[_nimi] = _lempiVari;
    }
//    function lisaaIhminenJaVari(string memory _nimi, string memory _lempiVari) public {
//        ihmiset.push(Ihmiset(_lempiVari, _nimi));
//        nimenKauttaLempiVariin[_nimi] = _lempiVari;
//    }
}