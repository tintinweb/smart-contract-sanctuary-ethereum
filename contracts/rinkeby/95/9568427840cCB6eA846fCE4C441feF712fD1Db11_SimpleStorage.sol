// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// or you can write ^0.8.8 which tells it can use and above
// or we can use >=0.8.8<0.9.0

contract SimpleStorage {
    // bool hasFavoriteNumber = true;
    // string FavouriteNumberInText = "five";
    // int8 FavoriteInt = -5;
    // address myAddress = 0x9aFc97444C8D0BBBe0697b7698fD072A0b8006D4;
    // bytes32 FavBytes = "cat";

    uint256 FavoriteNumber;
    // if we dont initialize here it will be initialized to null value (0)

    struct People {
        uint256 FavoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavnum;

    function store(uint _FavoriteNumber) public virtual {
        FavoriteNumber = _FavoriteNumber;
    }

    // contract address = 0xd9145CCE52D386f254917e481eB44e9943F39138

    function retrive() public view returns (uint256) {
        return FavoriteNumber;
    }

    function addPerson(uint256 _FavoriteNumber, string memory _name) public {
        // People memory newPeople = People({FavoriteNumber: _FavoriteNumber,name: _name});
        // people.push(newPeople);

        // People memory newPeople = People( _FavoriteNumber,_name);
        // people.push(newPeople);

        people.push(People(_FavoriteNumber, _name));
        nameToFavnum[_name] = _FavoriteNumber;
    }
}