// SPDX-License-Identifier: MIT

pragma solidity 0.8.8; //0.8.12

// pragma solidity ^0.8.7; // any version that are above 0.8.7 will work.
// pragma solidity >=0.8.7 <0.9.0; // any version in between will work.

contract SimpleStorage {
    //boolean, uint, int, address, bytes
    //  bool hasFavroiteNumber = true;
    uint256 public favoriteNumber; // 8-256
    uint256 defaultNumber; // default value is 0.
    //  string favoriteNumberInText = "Five";
    //  int256 favoriteInt = -5;
    //  address myAddress = 0x7b19258d55b8E513d78Decc83582Bb379B6beab8;
    //  bytes32 favoritebytes = "cat";

    // mapping
    mapping(string => uint256) public nameToFavoriteNumber;

    // struct
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // People public person = People({favoriteNumber:2, name: "Mark"});

    // array
    People[] public people;

    // uint256[] public favoriteNumberList;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure functions dont cost gas.
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata,memory,storage
    // calldata is temperory that can't be modified
    // memory is temperory that can be modified
    //
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // people.push(People(_favoriteNumber, _name));

        // People memory newPeople = People({favoriteNumber: _favoriteNumber, name: _name});
        // People memory newPeople = People(_favoriteNumber,_name);
        // people.push(newPeople);

        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}