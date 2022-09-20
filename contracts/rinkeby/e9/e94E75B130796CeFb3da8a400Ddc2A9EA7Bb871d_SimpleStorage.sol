//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// ^ 0.8.12 // carret means if we have version above 0.8.12 then its ok but atleast use 0.8.12
// >= 0.8.7 < 0.9.0 // means use version between 0.8.7 and 0.9.0, above 0.9.0 will not work

contract SimpleStorage {
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint favoriteNumber;
        string name;
    }
    uint256 favoriteNumber;
    People public person = People({favoriteNumber: 621, name: "Shakil Khan"});
    People[] public persons;

    function addUser(string calldata _name, uint _favoriteNumber) public {
        persons.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}