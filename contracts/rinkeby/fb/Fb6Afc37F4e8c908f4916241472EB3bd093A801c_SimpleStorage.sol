// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public persons;

    function store(uint256 _favoriteNumber) public virtual {
        // virtual for override
        favoriteNumber = _favoriteNumber;
    }

    // view and pure functions when called alone don't spend gas

    //view --> read (no modification)
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // pure --> can't read too (no modification)
    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    // string is a kind of array, so we need to specify 'memory' with it
    function addPeople(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        persons.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}