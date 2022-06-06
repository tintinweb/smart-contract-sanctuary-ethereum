//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 favouriteNumber;
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        string name;
        uint256 favouriteNumber;
    }

    People[] public people;

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    //utilizamos memory en el caso de que el parametro _name pueda cambiar, en caso de que no, usamos calldata
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_name, _favouriteNumber));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}