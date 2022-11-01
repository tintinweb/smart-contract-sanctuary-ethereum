// SPDX-License-Identifier: UNLICENSED
//pragma solidity ^0.8.9;

pragma solidity ^0.8.8;

contract BasicStorage {
    uint256 favoriteNumber;
    mapping(string => uint256) public nameToFavoriteNumber;

    People public person = People({favoriteNumber: 2, name: "Sajli"});

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public peopleList;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        retrieve();
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        peopleList.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }
}