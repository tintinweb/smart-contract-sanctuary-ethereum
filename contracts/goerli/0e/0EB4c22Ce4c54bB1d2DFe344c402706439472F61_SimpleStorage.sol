// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

contract SimpleStorage {
    struct Personne {
        string nom;
        string prenom;
        uint age;
        uint taille;
    }

    Personne[] public people;

    function ajoutPersonne(
        string memory _nom,
        string memory _prenom,
        uint _age,
        uint _taille
    ) public {
        people.push(Personne(_nom, _prenom, _age, _taille));
    }

    function voirNom(uint _nb) public view returns (string memory) {
        return people[_nb].nom;
    }
}

// pragma solidity 0.8.8;

// // pragma solidity ^0.8.0;
// // pragma solidity >=0.8.0 <0.9.0;

// contract SimpleStorage {
//     uint256 favoriteNumber;

//     struct People {
//         uint256 favoriteNumber;
//         string name;
//     }

//     // uint256[] public anArray;
//     People[] public people;

//     mapping(string => uint256) public nameToFavoriteNumber;

//     function store(uint256 _favoriteNumber) public {
//         favoriteNumber = _favoriteNumber;
//     }

//     function retrieve() public view returns (uint256) {
//         return favoriteNumber;
//     }

//     function addPerson(string memory _name, uint256 _favoriteNumber) public {
//         people.push(People(_favoriteNumber, _name));
//         nameToFavoriteNumber[_name] = _favoriteNumber;
//     }
// }