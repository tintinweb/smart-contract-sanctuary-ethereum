/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 lempiNumero;

    struct Ihmiset {
        uint256 lempiNumero;
        string nimi;
    }
    // Tehdään ihmiset-structista lista johon voi lisätä ihmisiä
    Ihmiset[] public ihmiset;

    mapping(string => uint256) public nimenKauttaLempiNumeroon;

    function tallenna(uint256 _lempiNumero) public {
        lempiNumero = _lempiNumero;
    }

    function nouda() public view returns (uint256) {
        return lempiNumero;
    }

    function lisaaIhminen(string memory _nimi, uint256 _lempiNumero) public {
        ihmiset.push(Ihmiset(_lempiNumero, _nimi));
        nimenKauttaLempiNumeroon[_nimi] = _lempiNumero;
    }
}