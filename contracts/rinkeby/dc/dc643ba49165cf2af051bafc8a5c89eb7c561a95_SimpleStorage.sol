/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract SimpleStorage {
    // bool, uint8-uint256, int8-int256, address, bytes1-bytes32
    bool hasFavoriteNumber = true;
    uint256 favoriteNumber;
    string favoriteNumberInText = "Five";
    int256 favoriteInt = -5;
    address myAddress = 0x2A3d10E144094a8b4a4085aBEaD12e357CEf109a;
    bytes32 favoriteBytes = "cat";
    mapping(string => uint256) public nameToFavoriteNumber;

    //defining struct
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // Declaring struct type array.
    // People public person = People({favoriteNumber: 2, name: 'Debangi'});
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber; //mapping
    }
}