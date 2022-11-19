//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; // to speciify solidity version

contract SimpleStorage {
    //boolean, uint, int, address, bytes
    uint256 public favoriteNumber;
    People public person = People({favoriteNumber: 2, name: "Trunk"});
    //map
    mapping(string => uint256) public nameToFavoriteNumber;
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            name: _name,
            favoriteNumber: _favoriteNumber
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138