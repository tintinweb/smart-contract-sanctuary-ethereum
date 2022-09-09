// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 favoriteNumberooo;

    struct People {
        uint256 favoriteNumberooo;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumberooo;

    function store(uint256 _favoriteNumberooo) public {
        favoriteNumberooo = _favoriteNumberooo;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumberooo;
    }

    function addPerson(string memory _name, uint256 _favoriteNumberooo) public {
        people.push(People(_favoriteNumberooo, _name));
        nameToFavoriteNumberooo[_name] = _favoriteNumberooo;
    }
}