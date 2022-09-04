// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; // That means compiler supports 0.8.7 and above versions like 0.8.8, 0.8.9 etc.

contract SimpleStorage {
    // uint256 default value is 0(zero)
    uint256 public favoriteNumber; // That is also means -> uint256 favouriteNumber = 0 ;
    //public above means, "create me a function that show me the favorite number(after deploy).

    mapping(string => uint256) public nameToFavoriteNumber; //mapping is like dictionary)
    //        key  => value => this string(key) represent a uint256(a value)

    struct People {
        string name;
        uint256 favoriteNumber;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_name, _favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}