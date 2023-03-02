//SPDX-License-Identifier: MIT

pragma solidity 0.8.7; //Versioning

contract SimpleStorage {
    // boolean, uinit, int, address, bytes
    // This will initialised to zero by default
    uint256 favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }
    //uint256[] public favouriteNumberslist;
    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    //view, pure not gonna cost gas fee
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    //calldata, memory, storage
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}