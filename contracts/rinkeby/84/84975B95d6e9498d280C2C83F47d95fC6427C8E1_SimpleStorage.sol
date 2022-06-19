/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //version ok pour ce contrat 0.8.7 ou au dessus

//EVM, Etherium Virtual Machine => peut recevoir un code solidity
//ex: Avalanche, Fantom, Polygon

contract SimpleStorage {
    uint256 public favNum; //initialisé à 0
    People[] public person; // liste de personnes

    mapping(string => uint256) public nameToFavouriteNum;

    struct People {
        //création de structure (nouveau type)
        uint256 favNum;
        string name;
    }

    function store(uint256 _favNum) public virtual {
        //virtual -> peut être réécrite dans
        //           ses sous contrats (override)
        favNum = _favNum;
    }

    //view, pure -> pas de gas dépensés car pas de puissance de calcul
    //                  => sauf si éxécuté dans une fonction qui demande du gas

    //view ne peut pas modifier le statut de la blockchain ( ne peut pas modifier
    //une variable)

    //pure pareil que view mais en plus tu ne peut pas lire de la blockchain( ne peut pas
    //lire une variable)

    function retrieve() public view returns (uint256) {
        //view : juste lit de la blockchain
        return favNum;
    }

    //calldata, memory, storage

    //memory : temporaire, la mémoire est effecée une fois la fonction terminée,
    //         qui peut être modifiée
    //calldata : même chose que memory mais ne peut pas modifier la valeur de la variable une
    //           fois celle ci déclarée
    //storage : existe en dehors de la fonction (ex. par défaut une variable
    //          est définie en storage, variable permannente

    //il faut définir le type de storage quand c'est une liste, comme string c'est une liste de
    //de bits ils faut écrire memory

    function addPerson(string memory _name, uint256 _favNum) public {
        People memory new_person = People(_favNum, _name);
        person.push(new_person);
        nameToFavouriteNum[_name] = _favNum;
    }
}