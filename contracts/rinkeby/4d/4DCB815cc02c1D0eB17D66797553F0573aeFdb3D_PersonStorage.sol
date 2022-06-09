// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract PersonStorage {
    // Struct for Person data
    struct Person {
        string name;
        uint8 age;
    }

    // Person array, and mapping of person's name to a number
    Person[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    // Storages a new Person in the array, and links the name
    // to a number in the mapping
    function addPerson(
        string memory _name,
        uint8 _age,
        uint256 _favoriteNumber
    ) public {
        people.push(Person(_name, _age));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // Returns a Person data from the array by index
    function getPerson(uint256 _index)
        public
        view
        returns (string memory, uint8)
    {
        return (people[_index].name, people[_index].age);
    }

    // Returns the favorite number of a Person by name
    function getFavoriteNumberByName(string memory _name)
        public
        view
        returns (uint256)
    {
        return nameToFavoriteNumber[_name];
    }
}