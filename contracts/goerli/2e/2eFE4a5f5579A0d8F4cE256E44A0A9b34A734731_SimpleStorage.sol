// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint favoriteNumber;

    //    People public person = People({favoriteNumber:2,name:"Asad"});

    struct People {
        uint favoriteNumber;
        string name;
    }

    mapping(string => uint) public nametofavnumb;

    People[] public people;

    //uint[] public favoriteNumberlist;

    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function reterive() public view returns (uint) {
        return favoriteNumber;
        //  return People.name;
    }

    function addPeople(string memory _name, uint _favoriteNumber) public {
        //People memory newperson = People({favoriteNumber:_favoriteNumber,name:_name});
        //people.push(newperson);
        people.push(People(_favoriteNumber, _name));

        nametofavnumb[_name] = _favoriteNumber;
    }
}