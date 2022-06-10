// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    // keyword virtual has to be added so as to mention that this function is overridable. Basically if any
    // children tries to use this function and implement it their way, this would be only possible if we have
    // permission to override it. This permission is given by virtual keyword.

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory p = People({
            name: _name,
            favoriteNumber: _favoriteNumber
        });
        // new keyword is only used to create instance of a contract. For any other class or struct we don't
        // need to use new keyword.
        people.push(p);
        //people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}