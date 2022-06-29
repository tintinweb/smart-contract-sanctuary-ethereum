//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleStorage {
    struct People {
        string name;
        uint256 patrimony;
    }

    uint256 patrimony;
    People public person =
        People({name: "Gianfilippo", patrimony: 12000000000000});

    People[] public peopleList;
    mapping(string => uint256) public peopleMap;

    function store(uint256 value) public virtual {
        //si usa virtual per rendere la funzione sovrascrivibile, ovvero per poter essere modificata in altri contratti
        patrimony = value;
    }

    function retrieve() public view returns (uint256) {
        return patrimony;
    }

    //siccome string è un tipo speciale c'è bisogno di definire dov'è presente in memoria
    function addPerson(string memory _name, uint256 _patrimony) public {
        peopleList.push(People(_name, _patrimony));
        peopleMap[_name] = _patrimony;
    }
}