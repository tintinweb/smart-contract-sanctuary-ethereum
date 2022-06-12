// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    struct People {
        string name;
        uint256 favoriteNumber;
    }

    People public person = People({favoriteNumber: 2, name: 'Shumas'});

    People public person2 = People('Musab', 14);

    People[] public persons;

    mapping(string => string) public roll_no;

    mapping(string => People) public peopleMapping;

    function store(uint256 newVal) public virtual {
        favoriteNumber = newVal;

        retreive();
    }

    function retreive() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        persons.push(People({favoriteNumber: _favoriteNumber, name: _name}));
    }

    function setRollNumber(string calldata key, string calldata _roll_num)
        public
    {
        roll_no[key] = _roll_num;
    }

    function setPeopleMapping(string calldata key, uint256 _favoriteNumber)
        public
    {
        peopleMapping[key] = People(key, _favoriteNumber);
    }
}