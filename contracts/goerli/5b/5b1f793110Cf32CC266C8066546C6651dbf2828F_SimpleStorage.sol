/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //Definir a versão do solidity. ^0.8.7 - Qualquer versão acima; >=0.8.7 <0.9.0 - Entre versões;

//boolean, uint, int, address, bytes
//    bool hasFavoriteNumber = true;
//    uint256 FavoriteNumber = 5; // uint256 ou uint8. Por default é 256. 8,16,32.... VALOR DEFAULT é 0
//    string favoriteNumberInText = "Five";
//    int256 favoriteInt = -5;
//    address myAddress = 0x43acF39616881D5E5D6DE9D9B0E642F275a4291F;
//    bytes32 favoriteBytes = "cat";

//****MEMORY****
//Stack, memory - apenas na transação, storage - existe até fora da função ou transação, calldata - variavel temporaria que não pode ser alterada, code, logs

contract SimpleStorage {
    uint256 public favoriteNumber; //se não for colocado o public, o default é internal e é so visivel para o contract/função.

    mapping(string => uint256) public nameToFavoriteNumber;

    //uint256 public favoriteNumbersList;

    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}