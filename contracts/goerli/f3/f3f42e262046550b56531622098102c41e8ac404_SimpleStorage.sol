/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //^ means any version above which can compile the code

//EVM - Ehereum Virtual M/c - Avalanche, Fantom and Polygon

contract SimpleStorage {
    uint256 public favoriteNumber; //This initialise to default value of 0

    //hashtable mapping of key to value
    mapping(string => uint256) public nameToFavoriteNumber;

    //Structs are custom defined types that can group several variables
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //uint256[] public favoriteNumberList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        //retrieve();
    }

    //view, pure doesn't change the state of variables hence doesn't attract any gas charges
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //EVM can access and store data in six places: Stack, Memory, Storage, Calladata, code and Logs
    //calldata, memory and storage. storage is permanent and, memory and calldata are temporary
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        //people.push(newPerson);
        //Or
        //People memory newPerson = People( _favoriteNumber, _name);
        //people.push(newPerson);
        //Or
        people.push(People(_favoriteNumber, _name));

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
//0xd9145CCE52D386f254917e481eB44e9943F39138