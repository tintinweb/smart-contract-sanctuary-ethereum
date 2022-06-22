// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint favouriteNo;

    struct People {
        uint favouriteNo;
        string name;
    }
    People[] public people;

    mapping(string => uint) public nameToFavouriteNo;

    function store(uint _fNo) public {
        favouriteNo = _fNo;
    }

    function retrieve() public view returns (uint) {
        return favouriteNo;
    }

    function addPerson(string memory _name, uint _fNo) public {
        people.push(People(_fNo, _name));
        nameToFavouriteNo[_name] = _fNo;
    }

    function getFavNoOfPerson(string memory _name) public view returns (uint) {
        return nameToFavouriteNo[_name];
    }
}