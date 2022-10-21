/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

contract annuaire {
    struct Personne {
        string nom;
        string prenom;
        uint age;
        uint hauteur;
    }

    Personne[] public people;

    function ajoutPersonne(
        string memory _nom,
        string memory _prenom,
        uint _age,
        uint _hauteur
    ) public {
        people.push(Personne(_nom, _prenom, _age, _hauteur));
    }

    function voirNom(uint _nb) public view returns (string memory) {
        return people[_nb].nom;
    }
}