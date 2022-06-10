/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7; // 0.8.12

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    /*
    bool hasFavoriteNumber = false;    
    string favoriteNumberInText = "asdfr";
    int256 favorite = -5;
    address myAddress = 0x6635F83421Bf059cd8111f180f0727128685BaE4;
    bytes32 favoriteBytes = 'cat';
    */

    uint256 favoriteNumber;
    mapping(string => uint256) public nameToFavoriteNumber;

    // People public person = People({favoriteNumber: 2, name: 'Derek'});

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        retrieve();
    }

    // view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People(_favoriteNumber, _name);
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}