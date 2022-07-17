// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // ^ indicates 0.8.7 or higher < >= operators also work

contract SimpleStorage {
    // Default scope is internal
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // callback - temporary variables that cannot be modified
    // memory   - temporary variables that CAN be modified
    // storage  - permanent variables that CAN be modified

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}