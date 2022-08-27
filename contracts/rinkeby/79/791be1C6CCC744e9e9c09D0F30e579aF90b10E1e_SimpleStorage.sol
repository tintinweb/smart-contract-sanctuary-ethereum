/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

/*pragma solidity ^0.8.8;
contract SimpleStorage{
    //state var
    uint public favoriteNumber;

    //mapping or dictionary
    mapping(string => uint ) public nameToFavNumber;
   // People public person = People({favoriteNumber:2, name: "Jason"});
   //struct
    struct People{
        uint favoriteNumber;
        string name;
        }
    //array or list
    People[] public people;

    //functions
    function store(uint _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        favoriteNumber = favoriteNumber + 8;
    }
    // pure var don't modify the blockchain state so they are free.
    function retrieve() public view returns(uint){
        return favoriteNumber;
    }

    //memory vars are function parameters, state var are storage
    function addPerson(string memory _name, uint _favoriteNumber) public{
     // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        people.push(People(_favoriteNumber, _name));
        nameToFavNumber[_name] = _favoriteNumber;
    }
} */