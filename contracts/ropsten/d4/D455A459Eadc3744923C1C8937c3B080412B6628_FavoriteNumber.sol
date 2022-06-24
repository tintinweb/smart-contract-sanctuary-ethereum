//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


//Nom du Contrat
contract FavoriteNumber {

    //Lorsqu'on définis une variable en public Solidity créer automatiquement un Getter
    uint public favoriteNumber = 7;
    

    function getFavoriteNumber() external view returns(uint){
      return favoriteNumber;
    }


    //Création d'un Setter pour venir changer ce nombre
    function setFavoriteNumber (uint _favoriteNumber) external {
        favoriteNumber = _favoriteNumber;
    }
}