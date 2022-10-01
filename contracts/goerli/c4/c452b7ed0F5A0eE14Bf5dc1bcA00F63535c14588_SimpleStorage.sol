// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    // Value Type = boolean, unint , int, address , bytes
    //  bool hasFavotiteBumber = true;
    //  uint256 favoriteNumber = 5;
    //  string favotiteNumberInText = "Five";
    //  int256 favoriteInt = -5;
    //  address myAddress = 0xa6E67d0fa33fbcBC370b79f2E96b05dc20a5f895;
    //  bytes32 favotiteBytes = "cat";

    uint256 public favoriteNumber; // <- This gets initialized to zero!
    // People public person = People({favoriteNumber : 2, name: "Rommel"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view, pure = disallow modification of state
    // pure = disallow reading of the state
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        // or  People memory newPerson = People({favoriteNumber : _favoriteNumber, name: _name});
        // people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}