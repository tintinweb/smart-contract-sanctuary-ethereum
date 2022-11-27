// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract SimpleStorage {
    // gets initialized to zero

    struct People {
        string name;
        uint8 age;
    }

    uint256 public favouriteNumber;

    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // mapping will assign a key to a value
    mapping(string => uint8) public nameToAge;

    function createPerson(string memory _name, uint8 _age) public {
        People memory newPerson = People(_name, _age);
        people.push(newPerson);
        nameToAge[_name] = _age;
    }

    function compareTwoStrings(
        string memory s1,
        string memory s2
    ) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    // view functions can only read state, does not cost gas and cannot mutate state;

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function docsViewFunction() public view returns (uint256) {
        return favouriteNumber;
    }

    // pure functions can only call other pure functions and cannot read or mutate state;

    function docsPureFunction(
        string memory name
    ) public pure returns (string memory) {
        return pureFunction(name);
    }

    function pureFunction(
        string memory name
    ) private pure returns (string memory) {
        return string.concat("Hello ", name);
    }
}