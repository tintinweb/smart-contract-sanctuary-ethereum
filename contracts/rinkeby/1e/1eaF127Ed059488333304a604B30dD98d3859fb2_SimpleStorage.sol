// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favourite_Number;
        string name;
    }

    // People public person=People({favourite_Number:3,name:'Sourav'});
    People[] public person;

    uint256 public favourite_Number;

    function store(uint256 _favourite_Number) public virtual {
        favourite_Number = _favourite_Number;
    }

    function retrieve() public view returns (uint256) {
        return favourite_Number;
    }

    function addPerson(uint256 _favourite_Number, string memory _name) public {
        person.push(People({favourite_Number: _favourite_Number, name: _name}));
        nameToFavouriteNumber[_name] = _favourite_Number;
    }
}