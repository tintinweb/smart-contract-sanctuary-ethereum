// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favioriteNumber;
    //People public person = People({favioriteNumber:2,name:"mukund"});
    mapping(string => uint256) public nameToFavoriteNumber;
    // mapping(uint256 => string) public FavioriteNumbertoname;

    struct People {
        uint256 favioriteNumber;
        string name;
    }
    People[] public people;

    function store(uint256 _favioriteNumber) public virtual {
        favioriteNumber = _favioriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favioriteNumber;
    }

    function addPerson(string memory _name, uint256 _favioriteNumber) public {
        people.push(People(_favioriteNumber, _name));
        nameToFavoriteNumber[_name] = _favioriteNumber;
        // FavioriteNumbertoname[_favioriteNumber] = _name;
    }
}