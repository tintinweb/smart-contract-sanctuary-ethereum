/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

//SPDX-License-Identifier: MIT (regarder le lien dans GitHub)
pragma solidity 0.8.7; // ^ version supérieure acceptée

// >=0.8.7 <0.9 version depuis 0.8.7 jusqu'à 0.9 exclu

contract SimpleStorage {
  //----------------------------------------------------//

  uint256 favoriteNumber; // =0 (256 représente combien de bits à allouer, check solidity doc)

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  //view, pure sont 2 types de fonctions qui ne consomment pas de gas lors de l'exécution (sauf si executé a l'intérieur d'une autre fonction)
  //view empèche la modification de la blockchain
  //pure empèche la modification et la lecture de la blockchain (pas d'utilisation de data, etc)

  function retrieve() public view returns (uint256) {
    //returns permet de préciser le type de résultat de la fonction
    return favoriteNumber; //Cette fonction permet d'afficher myFavoriteNumber, même chose que mettre la variable en public
  }

  //----------------------------------------------------//
  //----------------------------------------------------//

  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }
  //People public person = People({favoriteNumber: 2, name: "Benjamin"});
  //Ci-dessus exemple pour définir une personne de la structure People (long et répétitif)

  People[] public people; //[] signifie "array" (=liste)

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    //1         People memory newPerson = People(_favoriteNumber, _name);
    //1         people.push(newPerson);

    //2         People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
    //2         people.push(newPerson);
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
  //----------------------------------------------------//
}