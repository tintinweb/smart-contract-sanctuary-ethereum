// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    /*bool hasFavoriteNumber = false;
    string favoriteNumberInText = "Five";
    int256 favoriteInt = -5;
    address myAddress = 0xAC23220E2d380589D5Faf84f4eBa129043E620Eb
    bytes32 favoriteBytes = "cat";*/

    uint256 favoriteNumber; // Initialized to 0
    People public person = People({favoriteNumber: 2, name: 'Patrick'});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        retrieve();
    }

    // view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return 1 + 1;
    }

    // calldata, memory, storage
    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}