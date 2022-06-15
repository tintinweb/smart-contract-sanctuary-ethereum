//SPDX-License-Identifier: MIT
pragma solidity 0.8.8; //latest version is 0.8.12

contract SimpleStorage {
    //basic data type are boolean,uint, int, address, bytes
    uint256 public favouriteNumber;
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public persons;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function addPerson(uint256 _favouriteNumber, string memory _name) public {
        persons.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}