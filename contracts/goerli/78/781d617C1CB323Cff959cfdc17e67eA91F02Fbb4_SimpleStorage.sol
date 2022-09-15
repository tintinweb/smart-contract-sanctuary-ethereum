// SPDX-License-Identifier: MIT
// pragma solidity 0.8.8;
pragma solidity 0.8.8;

contract SimpleStorage {
    mapping(string => uint256) public nameToNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People public person = People({favouriteNumber: 5, name: "Steve"});
    People[] public people;
    People[3] public peopleFixed;

    uint256 favouriteNumber;

    function store(uint256 _favNum) public {
        favouriteNumber = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function add() public pure returns (uint256) {
        return (2 + 2);
    }

    function addPerson(string memory _name, uint256 _favoriteNum) public {
        people.push(People(_favoriteNum, _name));
        nameToNumber[_name] = _favoriteNum;
    }
}