//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    uint8 favoriteNumber;

    people[] public persons;
    mapping(string => uint8) public nameToNumber;

    function addNumber(uint8 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint8) {
        return favoriteNumber;
    }

    struct people {
        uint8 favoriteNumber;
        string name;
    }

    function addPeople(uint8 _favoriteNumber, string memory _name) public {
        nameToNumber[_name] = _favoriteNumber;
        persons.push(people(_favoriteNumber, _name));
    }
}
// memory exists during function execution
//calldata same as memory but cant be modified function mein
//storage(exists even outside the function execution) by default