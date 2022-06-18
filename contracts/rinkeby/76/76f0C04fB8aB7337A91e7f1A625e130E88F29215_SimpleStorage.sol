/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // 0.8.12 -> today's newest version

contract SimpleStorage {
    // gets initialized to zero!
    uint256 favoriteNumber;
    // like dict
    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata if name won't be modified inside function
    // structs, mappings and arrays need to be given memory/storage etc. when added as function parameters
    // function parameters cannot be storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}