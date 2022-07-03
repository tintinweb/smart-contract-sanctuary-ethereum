// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public favouriteNumber;
    People[] public people;

    //dictionary
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    //view function is free because it reads from blockchain but doesnt spend any gas because it doesnt change anything on the blockchain
    // if a gas calling function calls a view then it costs money
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    //pure function is also free but it is not allowed to read or update any values from the blockchain
    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    //memory needed for strings/arrays to declare how to be stored. memeory is changable tmporary, calldata is immutable temporary
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        People memory newPerson = People({
            favouriteNumber: _favouriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}