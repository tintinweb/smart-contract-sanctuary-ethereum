// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        retrieve();
    }

    // Aquesta funció fa exactament el mateix que la getter que retorna favoriteNumber
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function add() public pure returns(uint256) {
        return (1 + 1);
    }

    function addPeople(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}