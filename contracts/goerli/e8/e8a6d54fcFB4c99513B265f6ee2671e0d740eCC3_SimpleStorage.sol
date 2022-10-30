// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    struct People {
        uint favoriteNumber;
        string name;
    }

    uint public favoriteNumber;
    // uint[] public favoriteNumberList;

    // People public person = People({
    //     favoriteNumber: favoriteNumber,
    //     name: "quanlb"
    // });

    People[] public pepple;

    mapping(string => uint) public nameToFavouriteNumber;

    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        // retrieve();
    }

    function retrieve() public view returns (uint) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        pepple.push(newPerson);
        nameToFavouriteNumber[_name] = _favoriteNumber;
    }
}