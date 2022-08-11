/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // 0.8.12 latest?  ^ means anything above  >= n.n.n < use version between

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    /*
    bool hasFavoriteNumber = true;
    string favoriteNumberInText = "Five";
    int256 favoriteInt = -5;
    address myAddress;
    bytes32 favoriteBytes = "cat";

    uint8 favoriteNumber1 = 123;
    */

    uint256 favoriteNumber;

    People public person = People({favoriteNumber: 2, name: "Simon"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    // calldata = only exists in call and cannot be modified ,
    // memory = exists in function but can be modified,
    // storage = exists after function returns
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //       People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure     // no gas as only retieving from blockchain but would cost gas if called from a function that costs gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138