//SPDX SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract FundMe {
    //boolean, uint, int, address, bytes
    // struct, mapping

    //this get initialize to zero!
    uint256 favoriteNumber;
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        string name;
        uint256 favoriteNumber;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view, pure --> spend no gaz --> disallow modification of state (pure disallow reding from the blockchain)
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_name, _favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}