// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SharedStructs.sol";

contract SimpleStorage {
    uint256 private favoriteNumber;
    SharedStructs.Person[] private people;
    mapping(string => uint256) nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(SharedStructs.Person(_name, _favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function getPerson(uint256 index)
        public
        view
        returns (SharedStructs.Person memory)
    {
        return people[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SharedStructs {
    struct Person {
        string name;
        uint256 favoriteNumber;
    }
}