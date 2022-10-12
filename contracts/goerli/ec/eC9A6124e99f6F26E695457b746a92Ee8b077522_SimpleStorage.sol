// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    //bool, uint, int, address, bytes
    uint256 favoriteNumber; //unsigned integer, only positive
    address myAddress = 0xe8C10a7f86F59E9b0A4c1CB951103dB96C00C516;
    int256 favoriteInt = -1; //integer any number
    bytes32 favoriteByte = "es un hash";

    mapping(string => uint256) public nameToFavoriteNumber;

    //OOP Class
    struct People {
        string name;
        uint256 favoriteNumber;
    }
    //People public person = People({favoriteNumber:2, name:"alan"});

    //uint256[] public favoriteNumberList;

    //people is assigned to an array, and People[] is the class valuing as an array
    People[] public people;

    //virtual for being able to be overwriteable
    function storeFavoriteNumber(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        //only will cost gas if you put it inside a function which modifies the blockchain
        retrieve();
    }

    //view functions dont cost gas fees,
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //pure functions dont cost gas fee neither
    /* function add() public pure returns(uint256){
        return (1+1);
    } */

    //calldata, memory, storage are for arrays(strings), map
    //calldata are temporary variables that cant be modified
    //memory are temporary variables that can be modified
    //storage are permanent variables that can be modified
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People(_name,_favoriteNumber);
        //people.push(newPerson);
        people.push(People(_name, _favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
//0xd9145CCE52D386f254917e481eB44e9943F39138